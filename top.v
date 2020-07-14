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
    
    output wire pin_fpga_int,
    
    inout wire  pin_miso,
    inout wire  pin_mosi,
    output wire pin_cs,
    output wire pin_sck
  );

  wire [15:0]   debug;
    
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



  wire mem_busy;
  wire dfu_busy;
  wire dfu_usb_to_flash;
  wire dfu_flash_to_usb;
  reg usb_reset;

  wire flash_busy;
  assign flash_busy = mem_busy | dfu_busy;
  
  localparam DFU_STATE_appIDLE                = 'h00;
  localparam DFU_STATE_appDETACH              = 'h01;
  localparam DFU_STATE_dfuIDLE                = 'h02;
  localparam DFU_STATE_dfuDNLOAD_SYNC         = 'h03;
  localparam DFU_STATE_dfuDNBUSY              = 'h04;
  localparam DFU_STATE_dfuDNLOAD_IDLE         = 'h05;
  localparam DFU_STATE_dfuMANIFEST_SYNC       = 'h06;
  localparam DFU_STATE_dfuMANIFEST            = 'h07;
  localparam DFU_STATE_dfuMANIFEST_WAIT_RESET = 'h08;
  localparam DFU_STATE_dfuUPLOAD_IDLE         = 'h09;
  localparam DFU_STATE_dfuERROR               = 'h0a;

  wire [7:0] dfu_state;
  assign dfu_busy = (dfu_state == DFU_STATE_appIDLE |
                     dfu_state == DFU_STATE_appDETACH |
                     dfu_state == DFU_STATE_dfuIDLE);

  assign dfu_usb_to_flash = (dfu_state == DFU_STATE_dfuDNLOAD_SYNC |
                             dfu_state == DFU_STATE_dfuDNBUSY |
                             dfu_state == DFU_STATE_dfuDNLOAD_IDLE);

  assign dfu_flash_to_usb = (dfu_state == DFU_STATE_dfuUPLOAD_IDLE);
  

  wire       frame_complete;
    
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// generate 48 mhz clock
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  wire clk_48mhz;
  wire clk_locked;
  SB_PLL40_CORE #(
      .DIVR(4'd0),
      .DIVF(7'd31), // was 47 - 7'b0101111 = 0x2F
      .DIVQ(3'd4),
      .FILTER_RANGE(3'd1),
      .FEEDBACK_PATH("SIMPLE"),
      .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
      .FDA_FEEDBACK(4'd0),
      .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
      .FDA_RELATIVE(4'd0),
      .SHIFTREG_DIV_MODE(2'd0),
      .PLLOUT_SELECT("GENCLK"),
      .ENABLE_ICEGATE(1'b0)
  ) usb_pll_inst (
      .REFERENCECLK(pin_clk),
      .PLLOUTCORE(clk_48mhz),
      .PLLOUTGLOBAL(),
      .EXTFEEDBACK(),
      .RESETB(1'b1),
      .BYPASS(1'b0),
      .LATCHINPUTVALUE(),
      .LOCK(clk_locked),
      .SDI(),
      .SDO(),
      .SCLK()
  );
  wire          lf_clk;
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
  
  //wire hf_clk;
  //SB_HFOSC OSCInst0 (
  //  .CLKHFEN(1),
  //  .CLKHFPU(~reset),
  //  .CLKHF(hf_clk)
  //);

  //reg  clk_48mhz;
  //always @(posedge hf_clk) clk_48mhz <= ~clk_48mhz;
  
  localparam TEXT_LEN = 13;
  
  

  reg  clk_24mhz = 0;
  always @(posedge clk_48mhz) clk_24mhz <= ~clk_24mhz;
  
  reg  clk_12mhz = 0;
  always @(posedge clk_24mhz) clk_12mhz <= ~clk_12mhz;

  reg  clk_6mhz = 0;
  always @(posedge clk_12mhz) clk_6mhz <= ~clk_6mhz;
  
  wire clk;
  wire rst;
  assign clk = clk_12mhz;
  assign rst = reset;
  
  //assign pin_fpga_int     = clk_48mhz;
  //assign pin_fpga_int = clk_12mhz;
  
  //---------------------------------------------------------------
  // Wishbone arbitration connections
  reg [7:0] data_in;
  wire      ack;
  
  reg [7:0] led_data;
  reg       led_ack;
  
  wire [7:0] mem_data;
  wire       mem_ack;

  wire [7:0] mem2_data;
  wire       mem2_ack;

  assign ack = |{led_ack, mem_ack};
  
  always @(*) begin
    if      (led_ack)    begin  data_in = led_data;    end
    else if (mem_ack)    begin  data_in = mem_data;    end
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
    
  //wire        rs232_cycle;
  //wire        rs232_cycle_in;
  //wire [15:0] rs232_adr;
  //wire [7:0]  rs232_data;
  //wire        rs232_we;
  //wire        rs232_sel;
  //wire        rs232_stb;
  //wire [2:0]  rs232_cti;
    
  wire        led_drv_cycle;
  wire        led_drv_cycle_in;
  wire [15:0] led_drv_adr;
  wire [7:0]  led_drv_data;
  wire        led_drv_we;
  wire        led_drv_sel;
  wire        led_drv_stb;
  wire [2:0]  led_drv_cti;

  wire        tpat_cycle;
  wire        tpat_cycle_in;
  wire [15:0] tpat_adr;
  wire [7:0]  tpat_data;
  wire        tpat_we;
  wire        tpat_sel;
  wire        tpat_stb;
  wire [2:0]  tpat_cti;
  
  //assign rs232_cycle_in   = led_drv_cycle | tpat_cycle;
  assign led_drv_cycle_in = tpat_cycle; // rs232_cycle | 
  assign tpat_cycle_in    = led_drv_cycle; // rs232_cycle | 

  assign cycle = led_drv_cycle | tpat_cycle; // rs232_cycle | 
    
  always @(*) begin
    //if      (rs232_cycle)    begin  adr = rs232_adr;     data = rs232_data;     we = rs232_we;     sel = rs232_sel;     stb = rs232_stb;     cti = rs232_cti;    end
    if      (led_drv_cycle)  begin  adr = led_drv_adr;   data = led_drv_data;   we = led_drv_we;   sel = led_drv_sel;   stb = led_drv_stb;   cti = led_drv_cti;  end
    else if (tpat_cycle)     begin  adr = tpat_adr;      data = tpat_data;      we = tpat_we;      sel = tpat_sel;      stb = tpat_stb;      cti = tpat_cti;     end
    else                     begin  adr =     16'd0;     data =       8'd0;     we =        0;     sel =         0;     stb =         0;     cti =      3'd0;    end
  end

  
  
  //---------------------------------------------------------------
  assign mem2_data = 0;
  assign mem2_ack = 0;

  wire       mem_spi_sck;
  wire       mem_spi_cs;
  wire [3:0] mem_spi_d_out;
  reg [3:0]  mem_spi_d_in;
  wire [3:0] mem_spi_d_dir;

  reg  dfu_miso;
  wire dfu_cs;
  wire dfu_mosi;
  wire dfu_sck;

  wire [3:0] spi_d_in;
  reg [3:0]  spi_d_out;
  reg [3:0]  spi_d_dir;
  reg        spi_sck;
  reg        spi_cs;

  always @(*) begin
    if (!dfu_busy) begin
      spi_sck      = mem_spi_sck;
      spi_cs       = mem_spi_cs;
      spi_d_out    = mem_spi_d_out;
      spi_d_dir    = mem_spi_d_dir;
      mem_spi_d_in = spi_d_in;

      dfu_miso     = 0;
    end
    else begin
      spi_sck      = dfu_sck;
      spi_cs       = dfu_cs;
      spi_d_out    = {3'd0, dfu_mosi};
      spi_d_dir    = { 4'b0001 };
      dfu_miso     = spi_d_in[1];

      mem_spi_d_in = 4'd0;
    end
  end

  assign pin_cs  = spi_cs;
  assign pin_sck = spi_sck;
  SB_IO #(
    .PIN_TYPE( 6'b1010_01 ), // PIN_OUTPUT_TRISTATE - PIN_INPUT
    .PULLUP  ( 1'b1       )
  ) iobuf_d0 (
    .PACKAGE_PIN   ( pin_mosi     ),
    .OUTPUT_ENABLE ( spi_d_dir[0] ),
    .D_OUT_0       ( spi_d_out[0] ),
    .D_IN_0        ( spi_d_in[0]  )
  );
  SB_IO #(
    .PIN_TYPE( 6'b1010_01 ), // PIN_OUTPUT_TRISTATE - PIN_INPUT
    .PULLUP  ( 1'b1       )
  ) iobuf_d1 (
    .PACKAGE_PIN   ( pin_miso     ),
    .OUTPUT_ENABLE ( spi_d_dir[1] ),
    .D_OUT_0       ( spi_d_out[1] ),
    .D_IN_0        ( spi_d_in[1]  )
  );
  assign spi_d_in[2] = 0;
  assign spi_d_in[3] = 0;
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
  
  video_memory #(
    .ADDRESS_WIDTH   (16),
    .DATA_WIDTH      (8),
    .DATA_BYTES      (1),
    .BASE_ADDRESS    (`FRAME_MEMORY_START),
    .BASE_FRAME_ADDR (`FRAME_MEMORY_START + 1024)
  ) vido_memory_inst (
    .rst_i ( rst      ),
    .clk_i ( clk      ),
    .adr_i ( adr      ),
    .dat_i ( data     ),
    .dat_o ( mem_data ),
    .we_i  ( we       ),
    .sel_i ( sel      ),
    .stb_i ( stb      ),
    .cyc_i ( cycle    ),
    .ack_o ( mem_ack  ),
    .cti_i ( cti      ),

    .dfu_busy  ( dfu_busy ),
    .mem_busy  ( mem_busy ),
    
    .spi_clk   ( mem_spi_sck   ),
    .spi_sel   ( mem_spi_cs    ),
    .spi_d_out ( mem_spi_d_out ),
    .spi_d_in  ( mem_spi_d_in  ),
    .spi_d_dir ( mem_spi_d_dir )
  );

  
  //wishbone_spram #(
  //  .ADDRESS_WIDTH (16),
  //  .DATA_WIDTH    (8),
  //  .DATA_BYTES    (1),
  //  .BASE_ADDRESS  (`FRAME_MEMORY_START)
  //) memory_inst (
  //  .rst_i ( rst ),
  //  .clk_i ( clk ),
  //  .adr_i ( adr ),
  //  .dat_i ( data ),
  //  .dat_o ( mem_data ),
  //  .we_i  ( we ),
  //  .sel_i ( sel ),
  //  .stb_i ( stb ),
  //  .cyc_i ( cycle ),
  //  .ack_o ( mem_ack ),
  //  .cti_i ( cti )
  //);


  
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
    .col_rclk       ( col_rclk ),

    .frame_complete ( frame_complete ),
                   
    .debug          ( debug )
  );

  
  //---------------------------------------------------------------
  // uart and protocol
  
  wire usb_p_tx;
  wire usb_n_tx;
  wire usb_p_rx;
  wire usb_n_rx;
  wire usb_tx_en;
  
  // usb DFU - this instanciates the entire USB device.
  usb_dfu_core dfu (
    .clk_48mhz (clk_48mhz),
    .clk       (clk),
    .reset     (reset),

    // pins - these must be connected properly to the outside world.  See below.
    .usb_p_tx  (usb_p_tx),
    .usb_n_tx  (usb_n_tx),
    .usb_p_rx  (usb_p_rx),
    .usb_n_rx  (usb_n_rx),
    .usb_tx_en (usb_tx_en),

    // SPI pins
    .spi_csel  (dfu_cs),
    .spi_clk   (dfu_sck),
    .spi_miso  (dfu_miso),
    .spi_mosi  (dfu_mosi),

     // DFU state and debug
    .dfu_state (dfu_state),
    .debug     ()
  );




  //assign tpat_cycle = 0;
  //assign tpat_adr   = 0;
  //assign tpat_data  = 0;
  //assign tpat_we    = 0;
  //assign tpat_sel   = 0;
  //assign tpat_stb   = 0;
  //assign tpat_cti   = 0;

  reg [3:0] audio_volume;
  reg [3:0] audio_peak;

  video_machine #(
    .ADDRESS_WIDTH       ( 16 ),
    .DATA_WIDTH          ( 8 ),
    .DATA_BYTES          ( 1 ),
    .LED_MATRIX_ADDR     ( `MATRIX_START ),
    .LED_MATRIX_REG_ADDR ( `MATRIX_ADDR_L ),
    .BASE_FRAME_ADDR     ( `FRAME_MEMORY_START + 1024 ),
    .FRAME_SIZE          ( 1024 ), // including header
    .HEADER_SIZE         ( 128 ),
    .CLOCK_MHZ           ( 12 )
  ) video_machine_inst (// Wishbone master
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

    .frame_complete ( frame_complete ),
    .mem_busy       ( mem_busy ),
    .volume_in      ( audio_volume )
  );

  
  //generate
  //  if (0) begin // flag to switch between the LED test pattern (0) and VU meter (1)
  //    test_intensity #(
  //      .FRAME_ADDRESS ( `FRAME_MEMORY_START + 16'h0400)
  //    )test_pattern_inst (
  //      .rst_i ( rst ),
  //      .clk_i ( clk ),
  //      .adr_o ( tpat_adr ),
  //      .dat_i ( data_in ),
  //      .dat_o ( tpat_data ),
  //      .we_o  ( tpat_we ),
  //      .sel_o ( tpat_sel ),
  //      .stb_o ( tpat_stb ),
  //      .cyc_i ( tpat_cycle_in ),
  //      .cyc_o ( tpat_cycle ),
  //      .ack_i ( ack ),
  //      .cti_o ( tpat_cti ),
  //    
  //      .volume_in ( audio_volume ),
  //      .peak_in   ( audio_peak )
  //    );
  //  end
  //  else begin
  //    test_pattern #(
  //      .FRAME_ADDRESS ( `FRAME_MEMORY_START + 16'h0400 )//`FRAME_MEMORY_START )
  //    )test_pattern_inst (
  //      .rst_i ( rst ),
  //      .clk_i ( clk ),
  //      .adr_o ( tpat_adr ),
  //      .dat_i ( data_in ),
  //      .dat_o ( tpat_data ),
  //      .we_o  ( tpat_we ),
  //      .sel_o ( tpat_sel ),
  //      .stb_o ( tpat_stb ),
  //      .cyc_i ( tpat_cycle_in ),
  //      .cyc_o ( tpat_cycle ),
  //      .ack_i ( ack ),
  //      .cti_o ( tpat_cti )
  //    );
  //  end
  //endgenerate

  wire signed [11:0] audio1;
  wire signed [11:0] audio2;
  wire               audio_valid;
  pdm_mic #(
    .SAMPLE_DEPTH      ( 12 ),
    .FIR_SAMPLE_LENGTH ( 8192 ),
    .INPUT_FREQUENCY   ( 12000000 ),
    .FREQUENCY         (  2000000 ),
    .SAMPLE_FREQUENCY  ( 8000 )
  ) mic_inst (
    .clk ( clk ),
    .rst ( rst ),

    .mic_clk  ( pin_mic_clk ),
    .mic_data ( pin_mic_data ),

    .audio1 ( audio1 ),
    .audio2 ( audio2 ),
    .audio_valid ( audio_valid )
  );

  localparam N_BUCKETS = 16;
  reg [11:0]        audio_sample [0:N_BUCKETS-1];
  integer            shift_i;
  always @(posedge clk) begin
    if (audio_valid) begin
      for (shift_i = 1; shift_i < 16; shift_i = shift_i + 1) begin
        audio_sample[shift_i] <= audio_sample[shift_i-1];
      end
      audio_sample[0] <= audio1;
    end
  end
  
  reg [16:0] accum_1 = 0;
  reg [16:0] accum_2 = 0;
  reg [16:0] accum_3 = 0;
  reg [16:0] accum_4 = 0;

  reg [16:0] next_accum_1;
  reg [16:0] next_accum_2;
  reg [16:0] next_accum_3;
  reg [16:0] next_accum_4;

  reg signed [16:0]  add1_in1;
  reg signed [11:0]  add1_in2;
  reg signed [11:0]  add1_in3;
  wire signed [15:0] add1_result;

  assign add1_result = add1_in1 + add1_in2 - add1_in3;

  localparam FILT_STATE_1       = 0;
  localparam FILT_STATE_2       = 1;
  localparam FILT_STATE_3       = 2;
  localparam FILT_STATE_4       = 3;
  localparam FILT_STATE_END     = 4;
  reg [2:0]         filter_state;
  
  always @(*) begin
    next_accum_1 = accum_1;
    next_accum_2 = accum_2;
    next_accum_3 = accum_3;
    next_accum_4 = accum_4;

    add1_in1 = 0;
    add1_in2 = 0;
    add1_in3 = 0;

    case (filter_state)
    FILT_STATE_1: begin
      add1_in1     = accum_1;
      add1_in2     = audio1;
      add1_in3     = audio_sample[1];
      next_accum_1 = add1_result;
    end

    FILT_STATE_2: begin
      add1_in1     = accum_2;
      add1_in2     = audio1;
      add1_in3     = audio_sample[3];
      next_accum_2 = add1_result;
    end

    FILT_STATE_3: begin
      add1_in1     = accum_3;
      add1_in2     = audio1;
      add1_in3     = audio_sample[7];
      next_accum_3 = add1_result;
    end

    FILT_STATE_4: begin
      add1_in1     = accum_4;
      add1_in2     = audio1;
      add1_in3     = audio_sample[15];
      next_accum_4 = add1_result;
    end
    endcase
  end

  
  always @(posedge clk) begin
    if (filter_state > 3) begin
      if (audio_valid) filter_state  = 0;
    end
    else begin
      filter_state <= filter_state + 1;
    end
    accum_1 <= next_accum_1;
    accum_2 <= next_accum_2;
    accum_3 <= next_accum_3;
    accum_4 <= next_accum_4;
  end
  
  wire signed [11:0] filt_4    = accum_4[16:5];
  wire signed [11:0] filt_3    = accum_3[15:4];
  wire signed [11:0] filt_2    = accum_2[14:3];
  wire signed [11:0] filt_1    = accum_1[13:2];
  
  wire [11:0]        abs_audio  = ( filt_4 >= 0 ? filt_4 : -filt_4 );
  wire [11:0]        abs_audio2 = ( filt_1 >= 0 ? filt_1 : -filt_1 );

  reg [11:0]         peak_value;
  reg [11:0]         volume_value;
  
  localparam UPDATE_COUNT = (12000000 / 1000);
  localparam UPDATE_COUNT_WIDTH = $clog2(UPDATE_COUNT);
  reg [UPDATE_COUNT_WIDTH-1:0] update_counter;
  always @(posedge clk) begin
    if (abs_audio > peak_value) peak_value <= abs_audio;
    if (abs_audio > volume_value) volume_value <= abs_audio;

    if (update_counter) update_counter <= update_counter - 1;
    else begin
      update_counter <= UPDATE_COUNT;

      if (peak_value > 0) peak_value <= peak_value - 1;
      else                  peak_value <= 0;

      audio_volume <= ( abs_audio[15] ? 10 :
                        abs_audio[14] ? 10 :
                        abs_audio[13] ? 10 :
                        abs_audio[12] ? 10 :
                        abs_audio[11] ?  9 :
                        abs_audio[10] ?  8 :
                        abs_audio[ 9] ?  7 :
                        abs_audio[ 8] ?  6 :
                        abs_audio[ 7] ?  5 :
                        abs_audio[ 6] ?  4 :
                        abs_audio[ 5] ?  3 :
                        abs_audio[ 4] ?  2 :
                        abs_audio[ 3] ?  1 :
                        abs_audio[ 2] ?  0 :
                        abs_audio[ 1] ?  0 : 0);
      
      audio_peak <= ( peak_value[15] ? 10 :
                      peak_value[14] ? 10 :
                      peak_value[13] ? 10 :
                      peak_value[12] ? 10 :
                      peak_value[11] ?  9 :
                      peak_value[10] ?  8 :
                      peak_value[ 9] ?  7 :
                      peak_value[ 8] ?  6 :
                      peak_value[ 7] ?  5 :
                      peak_value[ 6] ?  4 :
                      peak_value[ 5] ?  3 :
                      peak_value[ 4] ?  2 :
                      peak_value[ 3] ?  1 :
                      peak_value[ 2] ?  0 :
                      peak_value[ 1] ?  0 : 0);
      
      volume_value <= 0;
    end
  end

  
  
  assign debug = {audio_volume, abs_audio[7:0]};
                   
  

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
  
  //reg  reset_armed = 0;
  //always @(clk) begin
  //  if (!(dfu_state == DFU_STATE_appIDLE || dfu_state == DFU_STATE_dfuIDLE)) reset_armed = 1;
  //end

  wire usb_reset_unreg;
  usb_reset_det rst_detector(
    .clk(clk_12mhz),
    .reset(usb_reset_unreg),
    .usb_p_rx(usb_p_in),
    .usb_n_rx(usb_n_in),
  );
  always @(posedge clk) usb_reset <= usb_reset_unreg;
  

  SB_WARMBOOT warmboot_inst (
    .S1(1'b0),
    .S0(1'b0), // was 1
    .BOOT(usb_reset && dfu_state == DFU_STATE_appDETACH)
  );

endmodule
