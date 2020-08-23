`include "globals.vh"

module top (
    input wire  pin_clk,

    inout wire  pin_usbp,
    inout wire  pin_usbn,
    output wire pin_pu,
    
    output wire pin_col_first,
    output wire pin_col_advance,
    output wire pin_row_oe_n,
    output wire pin_row_bank0,
    output wire pin_row_bank1,
    output wire pin_row_bank2,
    output wire pin_row_bank3,
    output wire pin_rclk,
    output wire pin_r0a,
    output wire pin_r0b,
    output wire pin_r1a,
    output wire pin_r1b,
    output wire pin_r2a,
    output wire pin_r2b,
    output wire pin_r3a,
    output wire pin_r3b,
    
    input wire  pin_mic_data,
    output wire pin_mic_clk,
    
    inout wire  pin_miso,
    inout wire  pin_mosi,
    inout wire  pin_wp,
    inout wire  pin_hold,
    output wire pin_cs,
    output wire pin_sck,

    input wire  pin_button_up,
    input wire  pin_button_down,

    output wire pin_stat_r,
    output wire pin_stat_g,
    output wire pin_stat_b,
            
    // addon header
    //                            GND
    output wire  pin_iob_9b, //  pin 3
    output wire  pin_iob_8a, //  pin 4
    output wire  pin_iob_13b, // pin 6
    //                           +3.3V

    input wire  pin_iot_38b, // pin 27
    input wire  pin_iob_29b, // pin 19
    input wire  pin_iob_23b  // pin 21
  );

  wire          stat_r;
  wire          stat_g;
  wire          stat_b;
  wire          stat_en;

  SB_RGBA_DRV #(
    .CURRENT_MODE ( "0b1"        ), // half current mode
    .RGB0_CURRENT ( "0b00000000" ), // 4mA
    .RGB1_CURRENT ( "0b00000000" ),
    .RGB2_CURRENT ( "0b00000000" )
  ) rgb_drv_inst (
    .RGBLEDEN ( stat_en    ),
    .CURREN   ( stat_en    ),
    .RGB0PWM  ( stat_r     ),
    .RGB1PWM  ( stat_g     ),
    .RGB2PWM  ( stat_b     ),
    .RGB0     ( pin_stat_r ),
    .RGB1     ( pin_stat_g ),
    .RGB2     ( pin_stat_b )
  );

  assign stat_r = 0;
  assign stat_g = 1;
  assign stat_b = 0;
  assign stat_en = 1;

  wire [15:0]   debug;
    
  wire [3:0]    latch_row_bank;
  wire [7:0]    row_data;
  wire          row_oe;
  wire          col_first;
  wire          col_advance;
  wire          col_rclk;
    
  assign pin_col_first   = col_first;
  assign pin_col_advance = col_advance;
  assign pin_row_oe_n    = row_oe;
  assign pin_row_bank0   = latch_row_bank[0];
  assign pin_row_bank1   = latch_row_bank[1];
  assign pin_row_bank2   = latch_row_bank[2];
  assign pin_row_bank3   = latch_row_bank[3];
  assign pin_rclk        = col_rclk;
  assign pin_r0a         = row_data[0];
  assign pin_r0b         = row_data[1];
  assign pin_r1a         = row_data[2];
  assign pin_r1b         = row_data[3];
  assign pin_r2a         = row_data[4];
  assign pin_r2b         = row_data[5];

  assign pin_r3a         = row_data[6];
  assign pin_r3b         = row_data[7];


  wire flash_busy;
  assign flash_busy = 0;
  
  wire       frame_complete;
    
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// Generate Clocks
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  wire clk_48mhz;
  wire clk_locked;
  pll48mhz pll(
    .refclk(pin_clk),
    .clk_48mhz(clk_48mhz),
    .clk_locked(clk_locked)
  );

  wire lf_clk;
  SB_LFOSC LF_OscInst (
    .CLKLFPU (1),
    .CLKLFEN (1),
    .CLKLF   (lf_clk)
  );

  // Generate reset signal
  reg [3:0]     reset_cnt = 7;
  reg           reset;
  
  always @(posedge lf_clk) begin
    if (reset_cnt) begin
      reset     <= 1;
      reset_cnt <= reset_cnt - 1;
    end
    else begin
      reset     <= 0;
      reset_cnt <= 0;
    end
  end
  
  reg  clk_24mhz = 0;
  always @(posedge clk_48mhz) clk_24mhz <= ~clk_24mhz;
  
  reg  clk_12mhz = 0;
  always @(posedge clk_24mhz) clk_12mhz <= ~clk_12mhz;

  reg  clk_6mhz = 0;
  always @(posedge clk_12mhz) clk_6mhz <= ~clk_6mhz;
  
  wire clk;
  wire rst;
  localparam CLK_FREQ = 24000000;
  assign clk = clk_24mhz;
  assign rst = reset;

  assign pin_iob_9b = clk_48mhz;
  assign pin_iob_8a = clk;
  assign pin_iob_13b = rst;
  
  //---------------------------------------------------------------
  // Wishbone arbitration connections
  reg [7:0] data_in;
  wire      ack;
  
  reg [7:0] led_data;
  reg       led_ack;
  
  wire [7:0] mem2_data;
  wire       mem2_ack;

  assign ack = |{led_ack};
  
  always @(*) begin
    if      (led_ack)    begin  data_in = led_data;    end
    else if (mem2_ack)   begin  data_in = mem2_data;   end
    else                 begin  data_in = 8'd0;        end
  end

    
  // the blocking mechanism is pretty simple. If any device is
  // currently using the bus, block everything else
  wire        cycle;
  reg [15:0]  adr;
  reg [7:0]   data;
  reg         we;
  reg [0:0]   sel;
  reg         stb;
  reg [2:0]   cti;
    
  wire        tpat_cycle;
  wire        tpat_cycle_in;
  wire [15:0] tpat_adr;
  wire [7:0]  tpat_data;
  wire        tpat_we;
  wire        tpat_sel;
  wire        tpat_stb;
  wire [2:0]  tpat_cti;
  
  //assign rs232_cycle_in   = tpat_cycle;
  assign tpat_cycle_in    = 0;

  assign cycle = tpat_cycle;
    
  always @(*) begin
    //if      (rs232_cycle)    begin  adr = rs232_adr;     data = rs232_data;     we = rs232_we;     sel = rs232_sel;     stb = rs232_stb;     cti = rs232_cti;    end
    if (tpat_cycle)     begin  adr =    tpat_adr;   data =    tpat_data;   we =    tpat_we;   sel =    tpat_sel;   stb =    tpat_stb;   cti =    tpat_cti;  end
    else                begin  adr =       16'd0;   data =         8'd0;   we =          0;   sel =           0;   stb =           0;   cti =        3'd0;  end
  end

  
  //---------------------------------------------------------------
  assign mem2_data = 0;
  assign mem2_ack = 0;

  
  led_matrix #(
    .ADDRESS_WIDTH   ( 16 ),
    .DATA_WIDTH      ( 8 ),
    .DATA_BYTES      ( 1 ),
    .BASE_ADDRESS    ( `MATRIX_START ),
    .BASE_MEM_ADDRESS( `FRAME_MEMORY_START )
  ) led_matrix_inst (
    // Wishbone interface
    .rst_i ( rst ),
    .clk_i ( clk ),
  
    .adr_i ( adr ),
    .dat_i ( data ),
    .dat_o ( led_data ),
    .we_i  ( we ),
    .sel_i ( sel ),
    .stb_i ( stb ),
    .cyc_i ( cycle ),
    .ack_o ( led_ack ),
    .cti_i ( cti ),
  
    // LED Drive Out
    .latch_row_bank ( latch_row_bank ),
    .row_data       ( row_data ),
    .row_oe         ( row_oe ),
    .col_first      ( col_first ),
    .col_advance    ( col_advance ),
    .col_rclk       ( col_rclk ),

    .frame_complete ( frame_complete ),
                   
    .debug          ( debug )
  );

  assign debug = { led_ack, cycle, led_data[7:0] };

  
  //---------------------------------------------------------------
  // uart and protocol
  
  wire usb_p_tx;
  wire usb_n_tx;
  wire usb_p_rx;
  wire usb_n_rx;
  wire usb_tx_en;
  
  wire dfu_detach;

  // usb DFU - this instanciates the entire USB device.
  usb_dfu_stub dfu (
    .clk_48mhz (clk_48mhz),
    .clk       (clk),
    .reset     (reset),

    // pins - these must be connected properly to the outside world.  See below.
    .usb_p_tx  (usb_p_tx),
    .usb_n_tx  (usb_n_tx),
    .usb_p_rx  (usb_p_rx),
    .usb_n_rx  (usb_n_rx),
    .usb_tx_en (usb_tx_en),

     // DFU state and debug
    .dfu_detach(dfu_detach),
    .debug     ()
  );





  reg [3:0] audio_volume;
  reg [3:0] audio_peak;
  assign audio_peak = 0;

  generate
    if (0) begin
      assign tpat_cycle = 0;
      assign tpat_adr   = 0;
      assign tpat_data  = 0;
      assign tpat_we    = 0;
      assign tpat_sel   = 0;
      assign tpat_stb   = 0;
      assign tpat_cti   = 0;
    end
    else begin
      if (0) begin // flag to switch between the LED test pattern (0) and VU meter (1)
        test_intensity #(
          .FRAME_ADDRESS ( `FRAME_MEMORY_START + 1024)
        )test_pattern_inst (
          .rst_i ( rst ),
          .clk_i ( clk ),
          .adr_o ( tpat_adr ),
          .dat_i ( data_in ),
          .dat_o ( tpat_data ),
          .we_o  ( tpat_we ),
          .sel_o ( tpat_sel ),
          .stb_o ( tpat_stb ),
          .cyc_i ( tpat_cycle_in ),
          .cyc_o ( tpat_cycle ),
          .ack_i ( ack ),
          .cti_o ( tpat_cti ),
        
          .volume_in ( audio_volume ),
          .peak_in   ( audio_peak )
        );
      end
      else begin
        test_pattern #(
          .FRAME_ADDRESS ( `FRAME_MEMORY_START + 1024 )//`FRAME_MEMORY_START )
        )test_pattern_inst (
          .rst_i ( rst ),
          .clk_i ( clk ),
          .adr_o ( tpat_adr ),
          .dat_i ( data_in ),
          .dat_o ( tpat_data ),
          .we_o  ( tpat_we ),
          .sel_o ( tpat_sel ),
          .stb_o ( tpat_stb ),
          .cyc_i ( tpat_cycle_in ),
          .cyc_o ( tpat_cycle ),
          .ack_i ( ack ),
          .cti_o ( tpat_cti )
        );
      end
    end
  endgenerate

  wire signed [11:0] audio1;
  wire               audio_valid;
  pdm_mic #(
    .SAMPLE_DEPTH      ( 12 ),
    .FIR_SAMPLE_LENGTH ( 8192 ),
    .INPUT_FREQUENCY   ( CLK_FREQ ),
    .FREQUENCY         (  2000000 ),
    .SAMPLE_FREQUENCY  ( 8000 )
  ) mic_inst (
    .clk ( clk ),
    .rst ( rst ),

    .mic_clk  ( pin_mic_clk ),
    .mic_data ( pin_mic_data ),

    .audio1 ( audio1 ),
    .audio_valid ( audio_valid )
  );


   
  wire [11:0]        abs_audio  = ( audio1 >= 0 ? audio1 : -audio1 );

  reg [11:0]         volume_value = 0;
  
  localparam UPDATE_COUNT = (12000000 / 200);
  localparam UPDATE_COUNT_WIDTH = $clog2(UPDATE_COUNT);
  reg [UPDATE_COUNT_WIDTH-1:0] update_counter;
  always @(posedge clk) begin
    if (abs_audio > volume_value) volume_value <= abs_audio;
  
    if (update_counter) update_counter <= update_counter - 1;
    else begin
      update_counter <= UPDATE_COUNT;
  
      audio_volume <= ( abs_audio[11] ? 10 :
                        abs_audio[10] ? 10 :
                        abs_audio[ 9] ?  8 :
                        abs_audio[ 8] ?  6 :
                        abs_audio[ 7] ?  4 :
                        abs_audio[ 6] ?  3 :
                        abs_audio[ 5] ?  2 :
                        abs_audio[ 4] ?  1 :
                        abs_audio[ 3] ?  0 :
                        abs_audio[ 2] ?  0 :
                        abs_audio[ 1] ?  0 : 0);
      
      volume_value <= 0;
    end
  end

                   
  

  assign pin_pu = 1'b1;

  wire usb_p_in;
  wire usb_n_in;
  assign usb_p_rx = usb_tx_en ? 1'b1 : usb_p_in;
  assign usb_n_rx = usb_tx_en ? 1'b0 : usb_n_in;
    
  SB_IO #(
    .PIN_TYPE(6'b 1010_01), // PIN_OUTPUT_TRISTATE - PIN_INPUT
    .PULLUP(1'b 0)
  ) iobuf_usbp (
    .PACKAGE_PIN(pin_usbp),
    .OUTPUT_ENABLE(usb_tx_en),
    .D_OUT_0(usb_p_tx),
    .D_IN_0(usb_p_in)
  );
    
  SB_IO #(
    .PIN_TYPE(6'b 1010_01), // PIN_OUTPUT_TRISTATE - PIN_INPUT
    .PULLUP(1'b 0)
  ) iobuf_usbn (
    .PACKAGE_PIN(pin_usbn),
    .OUTPUT_ENABLE(usb_tx_en),
    .D_OUT_0(usb_n_tx),
    .D_IN_0(usb_n_in)
  );
  

  // Image Slot 0: Multiboot header and POR springboard.
  // Image Slot 1: DFU Bootloader
  // Image Slot 2: This Image (User Application).
  SB_WARMBOOT warmboot_inst (
    .S1(1'b0),
    .S0(1'b1),
    .BOOT(dfu_detach)
  );


  //assign pin_sck = spi_sck;
  //SB_IO #(
  //  .PIN_TYPE( 6'b1010_01 ), // PIN_OUTPUT_TRISTATE - PIN_INPUT
  //  .PULLUP  ( 1'b0       )
  //) iobuf_d0 (
  //  .PACKAGE_PIN   ( pin_mosi     ),
  //  .OUTPUT_ENABLE ( spi_d_dir[0] ),
  //  .D_OUT_0       ( spi_d_out[0] ),
  //  .D_IN_0        ( spi_d_in[0]  )
  //);
  //SB_IO #(
  //  .PIN_TYPE( 6'b1010_01 ), // PIN_OUTPUT_TRISTATE - PIN_INPUT
  //  .PULLUP  ( 1'b0       )
  //) iobuf_d1 (
  //  .PACKAGE_PIN   ( pin_miso     ),
  //  .OUTPUT_ENABLE ( spi_d_dir[1] ),
  //  .D_OUT_0       ( spi_d_out[1] ),
  //  .D_IN_0        ( spi_d_in[1]  )
  //);
  //assign spi_d_in[2] = 0;
  //assign spi_d_in[3] = 0;
  //SB_IO #(
  //  .PIN_TYPE( 6'b1010_01 ), // PIN_OUTPUT_TRISTATE - PIN_INPUT
  //  .PULLUP  ( 1'b1       )
  //) iobuf_d2 (
  //  .PACKAGE_PIN   ( pin_wp       ),
  //  .OUTPUT_ENABLE ( spi_d_dir[2] ),
  //  .D_OUT_0       ( spi_d_out[2] ),
  //  .D_IN_0        ( spi_d_in[2]  )
  //);
  //SB_IO #(
  //  .PIN_TYPE( 6'b1010_01 ), // PIN_OUTPUT_TRISTATE - PIN_INPUT
  //  .PULLUP  ( 1'b1       )
  //) iobuf_d3 (
  //  .PACKAGE_PIN   ( pin_hold     ),
  //  .OUTPUT_ENABLE ( spi_d_dir[3] ),
  //  .D_OUT_0       ( spi_d_out[3] ),
  //  .D_IN_0        ( spi_d_in[3]  )
  //);

  
endmodule
