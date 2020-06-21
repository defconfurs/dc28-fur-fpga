`include "globals.v"

module top (
    input wire  pin_clk,

    //inout wire  pin_usbp,
    //inout wire  pin_usbn,
    //output wire pin_pu,
    
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
    
    output wire pin_fpga_int,
    
    output wire pin_miso,
    input wire  pin_cs,
    input wire  pin_mosi,
    input wire  pin_sck
    
    //input wire  pin_miso,
    //output wire pin_cs,
    //output wire pin_mosi,
    //output wire pin_sck
  );

  localparam N_COLS = 32;
  localparam N_ROWS = 7;

  wire [11:0]   debug;
    
  wire [3:0]    latch_row_bank;
  wire [7:0]    row_data;
  wire          row_oe;
  wire          col_first;
  wire          col_advance;
  wire          col_rclk;
    
  //reg [7:0]         test_counter;
  //always @(posedge pin_clk) begin
  //    test_counter <= test_counter + 1;
  //end

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


    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    ////////
    //////// generate 48 mhz clock
    ////////
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    //wire clk_48mhz;
    //wire clk_locked;
    //SB_PLL40_CORE #(
    //    .DIVR(4'b0000),
    //    .DIVF(7'b0101111),
    //    .DIVQ(3'b100),
    //    .FILTER_RANGE(3'b001),
    //    .FEEDBACK_PATH("SIMPLE"),
    //    .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
    //    .FDA_FEEDBACK(4'b0000),
    //    .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
    //    .FDA_RELATIVE(4'b0000),
    //    .SHIFTREG_DIV_MODE(2'b00),
    //    .PLLOUT_SELECT("GENCLK"),
    //    .ENABLE_ICEGATE(1'b0)
    //) usb_pll_inst (
    //    .REFERENCECLK(pin_clk),
    //    .PLLOUTCORE(clk_48mhz),
    //    .PLLOUTGLOBAL(),
    //    .EXTFEEDBACK(),
    //    .RESETB(1'b1),
    //    .BYPASS(1'b0),
    //    .LATCHINPUTVALUE(),
    //    .LOCK(clk_locked),
    //    .SDI(),
    //    .SDO(),
    //    .SCLK()
    //);
    wire lf_clk;
    SB_LFOSC LF_OscInst (
        .CLKLFPU (1),
        .CLKLFEN (1),
        .CLKLF   (lf_clk)
    );
    
    // Generate reset signal
    // Generate reset signal
    reg [3:0] reset_cnt         = 7;
    reg       reset;

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

    wire hf_clk;
    SB_HFOSC OSCInst0 (
        .CLKHFEN(1),
        .CLKHFPU(~reset),
        .CLKHF(hf_clk)
    );

    reg clk_48mhz;
    always @(posedge hf_clk) clk_48mhz <= ~clk_48mhz;
    
    localparam TEXT_LEN = 13;

    

    reg        clk_24mhz = 0;
    always @(posedge clk_48mhz) clk_24mhz <= ~clk_24mhz;

    reg        clk_12mhz = 0;
    always @(posedge clk_24mhz) clk_12mhz <= ~clk_12mhz;
    
    wire clk;
    wire rst;
    assign clk = clk_12mhz;
    assign rst = reset;

    assign pin_fpga_int = clk_12mhz;

    reg [4:0] mic_clk_div = 0;
    always @(posedge clk_12mhz) mic_clk_div <= mic_clk_div - 1;
    assign pin_mic_clk = mic_clk_div[4];
    
    //---------------------------------------------------------------
    // Wishbone arbitration connections
    reg [7:0] data_in;
    wire      ack;
    
    reg [7:0] led_data;
    reg       led_ack;
    
    wire [7:0] mem_data;
    wire       mem_ack;
    

    assign ack = |{led_ack, mem_ack};
    
    always @(*) begin
        if      (led_ack)  begin  data_in = led_data;  end
        else if (mem_ack)  begin  data_in = mem_data;  end
        else               begin  data_in = 8'd0;      end
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
    
    wire        rs232_cycle;
    wire        rs232_cycle_in;
    wire [15:0] rs232_adr;
    wire [7:0]  rs232_data;
    wire        rs232_we;
    wire        rs232_sel;
    wire        rs232_stb;
    wire [2:0]  rs232_cti;
    
    wire        led_drv_cycle;
    wire        led_drv_cycle_in;
    wire [15:0] led_drv_adr;
    wire [7:0]  led_drv_data;
    wire        led_drv_we;
    wire        led_drv_sel;
    wire        led_drv_stb;
    wire [2:0]  led_drv_cti;

  wire          tpat_cycle;
  wire          tpat_cycle_in;
  wire [15:0]   tpat_adr;
  wire [7:0]    tpat_data;
  wire          tpat_we;
  wire          tpat_sel;
  wire          tpat_stb;
  wire [2:0]    tpat_cti;
  
  assign rs232_cycle_in   = led_drv_cycle | tpat_cycle;
  assign led_drv_cycle_in = rs232_cycle | tpat_cycle;
  assign tpat_cycle_in    = rs232_cycle | led_drv_cycle;

  assign cycle = rs232_cycle | led_drv_cycle | tpat_cycle;
    
  always @(*) begin
    if      (rs232_cycle)    begin  adr = rs232_adr;     data = rs232_data;     we = rs232_we;     sel = rs232_sel;     stb = rs232_stb;     cti = rs232_cti;    end
    else if (led_drv_cycle)  begin  adr = led_drv_adr;   data = led_drv_data;   we = led_drv_we;   sel = led_drv_sel;   stb = led_drv_stb;   cti = led_drv_cti;  end
    else if (tpat_cycle)     begin  adr = tpat_adr;      data = tpat_data;      we = tpat_we;      sel = tpat_sel;      stb = tpat_stb;      cti = tpat_cti;     end
    else                     begin  adr =     16'd0;     data =       8'd0;     we =        0;     sel =         0;     stb =         0;     cti =      3'd0;    end
  end

    
    //---------------------------------------------------------------
    //assign test_cycle = 0;
    //assign test_adr   = 0;
    //assign test_data  = 0;
    //assign test_we    = 0;
    //assign test_sel   = 0;
    //assign test_stb   = 0;
    //assign test_cti   = 0;
    
    wishbone_memory #(
        .ADDRESS_WIDTH (16),
        .DATA_WIDTH    (8),
        .DATA_BYTES    (1),
        .BASE_ADDRESS  (`FRAME_MEMORY_START),
        .MEMORY_SIZE   (32768)
    ) memory_inst (
        .rst_i ( rst ),
        .clk_i ( clk ),
        .adr_i ( adr ),
        .dat_i ( data ),
        .dat_o ( mem_data ),
        .we_i  ( we ),
        .sel_i ( sel ),
        .stb_i ( stb ),
        .cyc_i ( cycle ),
        .ack_o ( mem_ack ),
        .cti_i ( cti )
    );
    

    //assign led_drv_adr = 0;
    //assign led_drv_data = 0;
    //assign led_drv_we = 0;
    //assign led_drv_sel = 0;
    //assign led_drv_stb = 0;
    //assign led_drv_cycle = 0;
    //assign led_drv_cti = 0;
    led_matrix #(
        .ADDRESS_WIDTH   ( 16 ),
        .DATA_WIDTH      ( 8 ),
        .DATA_BYTES      ( 1 ),
        .BASE_ADDRESS    ( `MATRIX_START ),
        .MAX_WAIT        ( 8 )
    ) led_matrix_inst (
        // Wishbone interface
        .rst_i ( rst ),
        .clk_i ( clk_24mhz ),
    
        .adr_i ( adr ),
        .dat_i ( data ),
        .dat_o ( led_data ),
        .we_i  ( we ),
        .sel_i ( sel ),
        .stb_i ( stb ),
        .cyc_i ( cycle ),
        .ack_o ( led_ack ),
        .cti_i ( cti ),
    
        // Wishbone master
        .frame_adr_o ( led_drv_adr ),
        .frame_dat_i ( data_in ),
        .frame_dat_o ( led_drv_data ),
        .frame_we_o  ( led_drv_we ),
        .frame_sel_o ( led_drv_sel ),
        .frame_stb_o ( led_drv_stb ),
        .frame_cyc_i ( led_drv_cycle_in ),
        .frame_cyc_o ( led_drv_cycle ),
        .frame_ack_i ( ack ),
        .frame_cti_o ( led_drv_cti ),
    
        // LED Drive Out
        .latch_row_bank ( latch_row_bank ),
        .row_data       ( row_data ),
        .row_oe         ( row_oe ),
        .col_first      ( col_first ),
        .col_advance    ( col_advance ),
        .col_rclk       ( col_rclk )
    );

    
    //---------------------------------------------------------------
    // uart and protocol
    
    

    wire [7:0]  uart_in_data;
    wire       uart_in_valid;
    wire       uart_in_ready;
    wire [7:0] uart_out_data;
    wire       uart_out_valid;
    wire       uart_out_ready;


    protocol #(
        .ADDRESS_WIDTH (16),
        .DATA_WIDTH    (8 ),
        .DATA_BYTES    (1 ),
        .MAX_WAIT      (8 ),
        .MAX_PAYLOAD   (4 )
    ) protocol_inst (
        // Wishbone interface
        .rst_i     ( rst ),
        .clk_i     ( clk ),
        .clk_48mhz ( clk_48mhz ),

        .adr_o ( rs232_adr      ),
        .dat_i ( data_in        ),
        .dat_o ( rs232_data     ),
        .we_o  ( rs232_we       ),
        .sel_o ( rs232_sel      ),
        .stb_o ( rs232_stb      ),
        .cyc_i ( rs232_cycle_in ),
        .cyc_o ( rs232_cycle    ),
        .ack_i ( ack            ),
        .cti_o ( rs232_cti      ),
        
        // Uart interfaces
        .rx_byte       ( uart_out_data ),
        .rx_byte_valid ( uart_out_valid ),
        .rx_ready      ( uart_out_ready ),

        .tx_byte       ( uart_in_data ),
        .tx_byte_valid ( uart_in_valid ),
        .tx_ready      ( uart_in_ready ), 
    );

    
    // usb uart
    usb_uart_core uart (
        .clk_48mhz     ( clk_48mhz      ),
        .reset         ( reset          ),
     
        .usb_p_tx      ( usb_p_tx       ),
        .usb_n_tx      ( usb_n_tx       ),
        .usb_p_rx      ( usb_p_rx       ),
        .usb_n_rx      ( usb_n_rx       ),
        .usb_tx_en     ( usb_tx_en      ),
     
        // uart pipeline in (out of the device, into the host)
        .uart_in_data  ( uart_in_data   ),
        .uart_in_valid ( uart_in_valid  ),
        .uart_in_ready ( uart_in_ready  ),
     
        // uart pipeline out (into the device, out of the host)
        .uart_out_data ( uart_out_data  ),
        .uart_out_valid( uart_out_valid ),
        .uart_out_ready( uart_out_ready ),
     
        .debug(  )
    );
    
    wire usb_p_tx;
    wire usb_n_tx;
    wire usb_p_rx;
    wire usb_n_rx;
    wire usb_tx_en;
    wire usb_p_in;
    wire usb_n_in;


  
  test_pattern #(
    .FRAME_ADDRESS ( `FRAME_MEMORY_START )
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

    //assign pin_pu = 1'b1;
    //
    //assign usb_p_rx = usb_tx_en ? 1'b1 : usb_p_in;
    //assign usb_n_rx = usb_tx_en ? 1'b0 : usb_n_in;
    //
    //SB_IO #(
    //    .PIN_TYPE(6'b 1010_01), // PIN_OUTPUT_TRISTATE - PIN_INPUT
    //    .PULLUP(1'b 0)
    //) 
    //iobuf_usbp 
    //(
    //    .PACKAGE_PIN(pin_usbp),
    //    .OUTPUT_ENABLE(usb_tx_en),
    //    .D_OUT_0(usb_p_tx),
    //    .D_IN_0(usb_p_in)
    //);
    //
    //SB_IO #(
    //    .PIN_TYPE(6'b 1010_01), // PIN_OUTPUT_TRISTATE - PIN_INPUT
    //    .PULLUP(1'b 0)
    //) 
    //iobuf_usbn 
    //(
    //    .PACKAGE_PIN(pin_usbn),
    //    .OUTPUT_ENABLE(usb_tx_en),
    //    .D_OUT_0(usb_n_tx),
    //    .D_IN_0(usb_n_in)
    //);

endmodule
