module usb_dfu_app_ep #(
  parameter MAX_IN_PACKET_SIZE = 32,
  parameter MAX_OUT_PACKET_SIZE = 32,
) (
  input clk,
  input clk_48mhz,
  input reset,
  output [6:0] dev_addr,

  ////////////////////
  // out endpoint interface
  ////////////////////
  output out_ep_req,
  input out_ep_grant,
  input out_ep_data_avail,
  input out_ep_setup,
  output out_ep_data_get,
  input [7:0] out_ep_data,
  output out_ep_stall,
  input out_ep_acked,

  ////////////////////
  // in endpoint interface
  ////////////////////
  output in_ep_req,
  input in_ep_grant,
  input in_ep_data_free,
  output in_ep_data_put,
  output reg [7:0] in_ep_data = 0,
  output in_ep_data_done,
  output reg in_ep_stall,
  input in_ep_acked,

  ////////////////////
  // DFU State and debug
  ////////////////////
  output       dfu_detach,
  output [7:0] dfu_state,
  output [7:0] debug,
);

  // Get flash partition information
  `include "boardinfo.vh"

  localparam IDLE = 0;
  localparam SETUP_IN = 1;
  localparam SETUP_DONE = 2;
  localparam DATA_IN = 3;
  localparam DATA_OUT = 4;
  localparam STATUS_IN = 5;
  localparam STATUS_OUT = 6;

  // DFU constants and states.
  localparam DFU_STATUS_OK = 'h00;
  localparam DFU_STATUS_ERR_TARGET = 'h01;
  localparam DFU_STATUS_ERR_FILE = 'h02;
  localparam DFU_STATUS_ERR_WRITE = 'h03;
  localparam DFU_STATUS_ERR_ERASE = 'h04;
  localparam DFU_STATUS_ERR_CHECK_ERASED = 'h05;
  localparam DFU_STATUS_ERR_PROG = 'h06;
  localparam DFU_STATUS_ERR_VERIFY = 'h07;
  localparam DFU_STATUS_ERR_ADDRESS = 'h08;
  localparam DFU_STATUS_ERR_NOTDONE = 'h09;
  localparam DFU_STATUS_ERR_FIRMWARE = 'h0a;
  localparam DFU_STATUS_ERR_VENDOR = 'h0b;
  localparam DFU_STATUS_ERR_USBR = 'h0c;
  localparam DFU_STATUS_ERR_POR = 'h0d;
  localparam DFU_STATUS_ERR_UNKNOWN = 'h0e;
  localparam DFU_STATUS_ERR_STALLEDPKT = 'h0f;

  localparam DFU_STATE_appIDLE = 'h00;
  localparam DFU_STATE_appDETACH = 'h01;

  localparam STR_INDEX_MANUFACTURER = 1;
  localparam STR_INDEX_PRODUCT = 2;
  localparam STR_INDEX_SERIAL = 3;
  localparam STR_INDEX_PARTITIONS = 4;

  localparam TEST_SERIAL = "123456";
  localparam DFU_DETACH_TIMEOUT = 1000;

  function [8:0] str_addr;
    input [7:0] index;
    str_addr = (index - 1) * 9'h020;
  endfunction

  reg [5:0] ctrl_xfr_state = IDLE;
  reg [5:0] ctrl_xfr_state_next;

  reg setup_stage_end = 0;
  reg data_stage_end = 0;
  reg status_stage_end = 0;
  reg send_zero_length_data_pkt = 0;

  // the default control endpoint gets assigned the device address
  reg [6:0] dev_addr_i = 0;
  assign dev_addr = dev_addr_i;

  assign out_ep_req = out_ep_data_avail;
  assign out_ep_data_get = out_ep_data_avail;
  reg out_ep_data_valid = 0;
  always @(posedge clk) out_ep_data_valid <= out_ep_data_avail && out_ep_grant;

  // need to record the setup data
  reg [3:0] setup_data_addr = 0;
  reg [9:0] raw_setup_data [7:0];

  wire [7:0] bmRequestType = raw_setup_data[0];
  wire [7:0] bRequest = raw_setup_data[1];
  wire [15:0] wValue = {raw_setup_data[3][7:0], raw_setup_data[2][7:0]};
  wire [15:0] wIndex = {raw_setup_data[5][7:0], raw_setup_data[4][7:0]};
  wire [15:0] wLength = {raw_setup_data[7][7:0], raw_setup_data[6][7:0]};

  // keep track of new out data start and end
  wire pkt_start;
  wire pkt_end;

  rising_edge_detector detect_pkt_start (
    .clk(clk),
    .in(out_ep_data_avail),
    .out(pkt_start)
  );

  falling_edge_detector detect_pkt_end (
    .clk(clk),
    .in(out_ep_data_avail),
    .out(pkt_end)
  );

  assign out_ep_stall = 1'b0;

  wire setup_pkt_start = pkt_start && out_ep_setup;

  wire has_data_stage = wLength != 16'b0000000000000000; // this version for some reason causes a 16b carry which is slow
  //wire has_data_stage = |wLength;

  wire out_data_stage;
  assign out_data_stage = has_data_stage && !bmRequestType[7];

  wire in_data_stage;
  assign in_data_stage = has_data_stage && bmRequestType[7];

  reg [15:0] rom_length = 0;
  reg [15:0] data_length = 0;

  wire all_data_sent = (ctrl_xfr_state == DATA_IN) && ((rom_length == 16'b0) || (data_length == 16'b0));
  wire more_data_to_send = !all_data_sent;

  wire in_data_transfer_done;
  rising_edge_detector detect_in_data_transfer_done (
    .clk(clk),
    .in(all_data_sent),
    .out(in_data_transfer_done)
  );

  assign in_ep_data_done = (in_data_transfer_done && ctrl_xfr_state == DATA_IN) || send_zero_length_data_pkt;

  assign in_ep_req = ctrl_xfr_state == DATA_IN && more_data_to_send;
  assign in_ep_data_put = rom_data_put;

  localparam ROM_ENDPOINT = 0;
  localparam ROM_STRING = 1;
  localparam ROM_DFUSTATE = 2;

  reg [8:0] rom_addr = 0;
  reg [3:0] rom_mux = ROM_ENDPOINT;
  wire rom_data_put;
  assign rom_data_put = (ctrl_xfr_state == DATA_IN && more_data_to_send) && in_ep_data_free;
  assign dfu_state = dfu_mem['h004];

  reg save_dev_addr = 0;
  reg [6:0] new_dev_addr = 0;

  // DFU Detach/Reboot Timer.
  reg [15:0] dfu_msec_prescaler = 0;
  reg dfu_msec_clk = 0;
  always @(posedge clk_48mhz) begin
      if (dfu_msec_prescaler) dfu_msec_prescaler <= dfu_msec_prescaler - 1;
      else begin
          dfu_msec_clk <= ~dfu_msec_clk;
          dfu_msec_prescaler <= 23999; /* 0.5ms in 48MHz clocks */
      end
  end
  
  reg [15:0] dfu_detach_timer = DFU_DETACH_TIMEOUT;
  always @(posedge dfu_msec_clk) begin
      if ((dfu_mem['h004] == DFU_STATE_appDETACH) && (dfu_detach_timer)) dfu_detach_timer <= dfu_detach_timer - 1;
  end
  assign dfu_detach = (dfu_mem['h004] == DFU_STATE_appDETACH) && (dfu_detach_timer == 0);

  ////////////////////////////////////////////////////////////////////////////////
  // control transfer state machine
  ////////////////////////////////////////////////////////////////////////////////

  always @* begin
    setup_stage_end <= 0;
    data_stage_end <= 0;
    status_stage_end <= 0;
    send_zero_length_data_pkt <= 0;

    case (ctrl_xfr_state)
      IDLE : begin
        if (setup_pkt_start) begin
          ctrl_xfr_state_next <= SETUP_IN;
        end else begin
          ctrl_xfr_state_next <= IDLE;
        end
      end

      SETUP_IN : begin
        if (pkt_end) begin
          ctrl_xfr_state_next <= SETUP_DONE;
        end else begin
          ctrl_xfr_state_next <= SETUP_IN;
        end
      end

      SETUP_DONE : begin
        setup_stage_end <= 1;
        if (in_data_stage) begin
          ctrl_xfr_state_next <= DATA_IN;

        end else if (out_data_stage) begin
          ctrl_xfr_state_next <= DATA_OUT;

        end else begin
          ctrl_xfr_state_next <= STATUS_IN;
          send_zero_length_data_pkt <= 1;
        end
      end

      DATA_IN : begin
        if (in_ep_stall) begin
          ctrl_xfr_state_next <= IDLE;
          data_stage_end <= 1;
          status_stage_end <= 1;

        end else if (in_ep_acked && all_data_sent) begin
          ctrl_xfr_state_next <= STATUS_OUT;
          data_stage_end <= 1;

        end else begin
          ctrl_xfr_state_next <= DATA_IN;
        end
      end

      DATA_OUT : begin
        if (!data_length) begin
          ctrl_xfr_state_next <= STATUS_IN;
          send_zero_length_data_pkt <= 1;
          data_stage_end <= 1;

        end else begin
          ctrl_xfr_state_next <= DATA_OUT;
        end
      end

      STATUS_IN : begin
        if (in_ep_acked) begin
          ctrl_xfr_state_next <= IDLE;
          status_stage_end <= 1;

        end else begin
          ctrl_xfr_state_next <= STATUS_IN;
        end
      end

      STATUS_OUT: begin
        if (out_ep_acked) begin
          ctrl_xfr_state_next <= IDLE;
          status_stage_end <= 1;

        end else begin
          ctrl_xfr_state_next <= STATUS_OUT;
        end
      end

      default begin
        ctrl_xfr_state_next <= IDLE;
      end
    endcase
  end

  always @(posedge clk) begin
    if (reset) begin
      ctrl_xfr_state <= IDLE;
    end else begin
      ctrl_xfr_state <= ctrl_xfr_state_next;
    end
  end

  always @(posedge clk) begin
    in_ep_stall <= 0;

    if (out_ep_setup && out_ep_data_valid) begin
      raw_setup_data[setup_data_addr] <= out_ep_data;
      setup_data_addr <= setup_data_addr + 1;
    end

    if (setup_stage_end) begin
      data_length <= wLength;
      
      // Standard Requests
      case ({bmRequestType[6:5], bRequest})
        'h006 : begin
          // GET_DESCRIPTOR
          case (wValue[15:8])
            1 : begin
              // DEVICE
              rom_mux     <= ROM_ENDPOINT;
              rom_addr    <= 'h00;
              rom_length  <= ep_rom['h00]; // bLength
            end

            2 : begin
              // CONFIGURATION
              rom_mux     <= ROM_ENDPOINT;
              rom_addr    <= 'h16;
              rom_length  <= ep_rom['h16 + 2]; // wTotalLength
            end

            3 : begin
              // STRING
              if (wValue[7:0] == 0) begin
                // Language descriptors
                rom_mux     <= ROM_ENDPOINT;
                rom_addr    <= 'h12;
                rom_length  <= ep_rom['h12]; // bLength
              end else begin
                rom_mux     <= ROM_STRING;
                rom_addr    <= str_addr(wValue[7:0]);
                rom_length  <= str_rom[str_addr(wValue[7:0])];
              end
            end

            6 : begin
              // DEVICE_QUALIFIER
              in_ep_stall <= 1;
              rom_mux    <= ROM_ENDPOINT;
              rom_addr   <= 'h00;
              rom_length <= 'h00;
            end

          endcase
        end

        'h005 : begin
          // SET_ADDRESS
          rom_mux    <= ROM_ENDPOINT;
          rom_addr   <= 'h00;
          rom_length <= 'h00;

          // we need to save the address after the status stage ends
          // this is because the status stage token will still be using
          // the old device address
          save_dev_addr <= 1;
          new_dev_addr <= wValue[6:0];
        end

        'h009 : begin
          // SET_CONFIGURATION
          rom_mux    <= ROM_ENDPOINT;
          rom_addr   <= 'h00;
          rom_length <= 'h00;
        end

        'h0b : begin
          // SET_INTERFACE
          rom_mux    <= ROM_ENDPOINT;
          rom_addr   <= 'h00;
          rom_length <= 'h00;
        end

        'h100 : begin
          // DFU_DETACH
          rom_mux    <= ROM_ENDPOINT;
          rom_addr   <= 0;
          rom_length <= 'h00;
          
          dfu_mem['h004] <= DFU_STATE_appDETACH;
        end

        'h103 : begin
          // DFU_GETSTATUS
          rom_mux    <= ROM_DFUSTATE;
          rom_addr   <= 'h00;
          rom_length <= 6;
        end

        'h104 : begin
          // DFU_CLRSTATUS
          rom_mux    <= ROM_ENDPOINT;
          rom_addr   <= 'h00;
          rom_length <= 0;
          dfu_mem['h000] <= DFU_STATUS_OK;
          dfu_mem['h004] <= DFU_STATE_appIDLE;
        end

        'h105 : begin
          // DFU_GETSTATE
          rom_mux    <= ROM_DFUSTATE;
          rom_addr   <= 'h04;
          rom_length <= 1;
        end

        'h106 : begin
          // DFU_ABORT
          rom_mux    <= ROM_DFUSTATE;
          rom_addr   <= 'h00;
          rom_length <= 0;

          // Return to the dfuIDLE state.
          dfu_mem['h004] <= DFU_STATE_appIDLE;
        end 

        default begin
          rom_mux    <= ROM_ENDPOINT;
          rom_addr   <= 'h00;
          rom_length <= 'h00;
        end
      endcase
    end

    if (in_ep_grant && in_ep_data_put) begin
      rom_addr <= rom_addr + 1;
      rom_length <= rom_length - 1;
      data_length <= data_length - 1;
    end
    if (!out_ep_setup && out_ep_grant && out_ep_data_get) begin
      data_length <= data_length - 1;
    end

    if (status_stage_end) begin
      setup_data_addr <= 0;
      rom_addr <= 0;
      rom_length <= 0;

      if (save_dev_addr) begin
        save_dev_addr <= 0;
        dev_addr_i <= new_dev_addr;
      end
    end

    if (reset) begin
      dev_addr_i <= 0;
      setup_data_addr <= 0;
      save_dev_addr <= 0;
    end
  end

  reg [7:0] ep_rom[255:0];
  reg [7:0] str_rom[511:0];
  reg [7:0] dfu_mem[5:0];

  // Mux the data being read
  always @* begin
    case (rom_mux)
      ROM_ENDPOINT : in_ep_data <= ep_rom[rom_addr];
      ROM_STRING   : in_ep_data <= str_rom[rom_addr];
      ROM_DFUSTATE : in_ep_data <= dfu_mem[rom_addr];
      default      : in_ep_data <= 8'b0;
    endcase
  end

  initial begin
      // device descriptor
      ep_rom['h000] <= 18; // bLength
      ep_rom['h001] <= 1; // bDescriptorType
      ep_rom['h002] <= 'h00; // bcdUSB[0]
      ep_rom['h003] <= 'h01; // bcdUSB[1]
      ep_rom['h004] <= 'h00; // bDeviceClass
      ep_rom['h005] <= 'h00; // bDeviceSubClass
      ep_rom['h006] <= 'h00; // bDeviceProtocol
      ep_rom['h007] <= MAX_OUT_PACKET_SIZE; // bMaxPacketSize0

      ep_rom['h008] <= BOARD_VID >> 0; // idVendor[0]
      ep_rom['h009] <= BOARD_VID >> 8; // idVendor[1]
      ep_rom['h00A] <= BOARD_PID >> 0; // idProduct[0]
      ep_rom['h00B] <= BOARD_PID >> 8; // idProduct[1]

      ep_rom['h00C] <= 0; // bcdDevice[0]
      ep_rom['h00D] <= 0; // bcdDevice[1]
      ep_rom['h00E] <= STR_INDEX_MANUFACTURER;  // iManufacturer
      ep_rom['h00F] <= STR_INDEX_PRODUCT;       // iProduct
      ep_rom['h010] <= STR_INDEX_SERIAL;        // iSerialNumber
      ep_rom['h011] <= 1; // bNumConfigurations

      // Language string descriptor is at string index zero.
      ep_rom['h012] <= 4;     // bLength
      ep_rom['h013] <= 3;     // bDescriptorType == STRING
      ep_rom['h014] <= 'h09;  // wLANGID[0] == US English
      ep_rom['h015] <= 'h04;  // wLANGID[1]

      // configuration descriptor
      ep_rom['h016] <= 9; // bLength
      ep_rom['h017] <= 2; // bDescriptorType
      ep_rom['h018] <= (9+9+9); // wTotalLength[0]
      ep_rom['h019] <= 0; // wTotalLength[1]
      ep_rom['h01A] <= 1; // bNumInterfaces
      ep_rom['h01B] <= 1; // bConfigurationValue
      ep_rom['h01C] <= 0; // iConfiguration
      ep_rom['h01D] <= 'hC0; // bmAttributes
      ep_rom['h01E] <= 50; // bMaxPower

      ep_rom['h01F] <= 9;     // bLength
      ep_rom['h020] <= 4;     // bDescriptorType
      ep_rom['h021] <= 0;     // bInterfaceNumber
      ep_rom['h022] <= 0;     // bAlternateSetting
      ep_rom['h023] <= 0;     // bNumEndpoints
      ep_rom['h024] <= 'hFE;  // bInterfaceClass (Application Specific Class Code)
      ep_rom['h025] <= 1;     // bInterfaceSubClass (Device Firmware Upgrade Code)
      ep_rom['h026] <= 1;     // bInterfaceProtocol (Runtime protocol)
      ep_rom['h027] <= 0;     // iInterface
      
      // DFU Header Functional Descriptor, DFU Spec 4.1.3, Table 4.2
      ep_rom['h028] <= 9;           // bFunctionLength
      ep_rom['h029] <= 'h21;        // bDescriptorType
      ep_rom['h02A] <= 'h0F;        // bmAttributes
      ep_rom['h02B] <= DFU_DETACH_TIMEOUT >> 0; // wDetachTimeout[0]
      ep_rom['h02C] <= DFU_DETACH_TIMEOUT >> 8; // wDetachTimeout[1]
      ep_rom['h02D] <= SPI_PAGE_SIZE >> 0; // wTransferSize[0]
      ep_rom['h02E] <= SPI_PAGE_SIZE >> 8; // wTransferSize[1]
      ep_rom['h02F] <= 'h10;        // bcdDFUVersion[0]
      ep_rom['h030] <= 'h01;        // bcdDFUVersion[1]

      // DFU State data
      dfu_mem['h000] <= DFU_STATUS_OK;      // bStatus
      dfu_mem['h001] <= 1;                  // bwPollTimeout[0]
      dfu_mem['h002] <= 0;                  // bwPollTimeout[1]
      dfu_mem['h003] <= 0;                  // bwPollTimeout[2]
      dfu_mem['h004] <= DFU_STATE_appIDLE;  // bState
      dfu_mem['h005] <= 0;                  // iString
  end

///////////////////////////////////////////////////////////
// Generate String ROMS for Board Description
///////////////////////////////////////////////////////////

`define INIT_STRING_ROM(_idx_, _str_) \
  genvar i;                                                 \
  generate                                                  \
    initial begin                                           \
      str_rom[str_addr(_idx_) + 0] <= 2 + $size(_str_) / 4; \
      str_rom[str_addr(_idx_) + 1] <= 3;                    \
    end                                                     \
    for (i = 0; i < $size(_str_); i = i + 8) begin          \
      initial str_rom[str_addr(_idx_) + 2 + i/4] <=         \
          _str_[$size(_str_)-i-1 : $size(_str_)-i-8];       \
      initial str_rom[str_addr(_idx_) + 3 + i/4] <= 8'h00;  \
    end                                                     \
  endgenerate

`INIT_STRING_ROM(STR_INDEX_MANUFACTURER, BOARD_MFR_NAME)
`INIT_STRING_ROM(STR_INDEX_PRODUCT, BOARD_PRODUCT_NAME)
`INIT_STRING_ROM(STR_INDEX_SERIAL, BOARD_SERIAL)

endmodule
