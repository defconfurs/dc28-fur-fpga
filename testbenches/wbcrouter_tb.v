`timescale 1ns/100ps

module wbcrouter_testbench #() ();
  reg rst_i;
  reg clk_i;
  localparam  CLOCK_PERIOD            = 100; // Clock period in ps
  localparam  INITIAL_RESET_CYCLES    = 10;  // Number of cycles to reset when simulation starts
  // Clock signal generator
  initial clk_i = 1'b1;
  always begin
      #(CLOCK_PERIOD / 2);
      clk_i = ~clk_i;
  end
  
  // Initial reset
  initial begin
      rst_i = 1'b1;
      repeat(INITIAL_RESET_CYCLES) @(posedge clk_i);
      rst_i = 1'b0;
  end

  wire clk;
  wire rst;
  
  assign clk = clk_i;
  assign rst = rst_i;


  localparam ADDRESS_WIDTH = 16;
  localparam DATA_WIDTH    = 16;
  localparam DATA_BYTES    = 2;
  localparam MAX_WAIT      = 8;
  localparam MAX_PAYLOAD   = 2;
    
  localparam INTERFACE_WIDTH = (MAX_PAYLOAD * DATA_WIDTH);
  localparam INTERFACE_LENGTH_N = $clog2(MAX_PAYLOAD+1);



  reg [ADDRESS_WIDTH-1:0]      transfer_address;
  reg [INTERFACE_WIDTH-1:0]    payload_in;
  wire [INTERFACE_WIDTH-1:0]   payload_out;
  reg [INTERFACE_LENGTH_N-1:0] payload_length;
  reg                          start_read;
  wire                         read_busy;
  reg                          start_write;
  wire                         write_busy;
  wire                         completed;
  wire                         timeout;
  
  // Peripherals to simplify the mux component
  wire [ADDRESS_WIDTH-1:0] wb_peripherals_addr;
  wire [DATA_WIDTH-1:0]    wb_peripherals_rdata;
  wire [DATA_WIDTH-1:0]    wb_peripherals_wdata;
  wire                     wb_peripherals_we;
  wire [DATA_BYTES-1:0]    wb_peripherals_sel;
  wire                     wb_peripherals_ack;
  wire                     wb_peripherals_cyc;
  wire                     wb_peripherals_stb;
  wire                     wb_peripherals_err;

  wishbone_master #(
    .ADDRESS_WIDTH (ADDRESS_WIDTH),
    .DATA_WIDTH    (DATA_WIDTH),
    .DATA_BYTES    (DATA_BYTES),
    .MAX_WAIT      (MAX_WAIT),
    .MAX_PAYLOAD   (MAX_PAYLOAD)
  ) dut_wb_master (
    // Wishbone interface
    .rst_i (rst_i),
    .clk_i (clk_i),

    .adr_o (wb_peripherals_addr),
    .dat_i (wb_peripherals_rdata),
    .dat_o (wb_peripherals_wdata),
    .we_o  (wb_peripherals_we),
    .sel_o (wb_peripherals_sel),
    .stb_o (wb_peripherals_stb),
    .cyc_i (0),
    .cyc_o (wb_peripherals_cyc),
    .ack_i (wb_peripherals_ack),
    .cti_o (),

    // packet interface
    .transfer_address(transfer_address),
    .payload_in      (payload_in      ),
    .payload_out     (payload_out     ),
    .payload_length  (payload_length  ),
    .start_read      (start_read      ),
    .read_busy       (read_busy       ),
    .start_write     (start_write     ),
    .write_busy      (write_busy      ),
    .completed       (completed       ),
    .timeout         (timeout         )
  );

  localparam WB_SADDR_WIDTH = ADDRESS_WIDTH - 4;
  localparam WB_DATA_WIDTH = DATA_WIDTH;
  localparam WB_SEL_WIDTH  = DATA_BYTES;
  
  // Serial
  wire [WB_SADDR_WIDTH-1:0] wb_serial_addr;
  wire [WB_DATA_WIDTH-1:0]  wb_serial_rdata = 16'h1111;
  wire [WB_DATA_WIDTH-1:0]  wb_serial_wdata;
  wire                      wb_serial_we;
  wire [WB_SEL_WIDTH-1:0]   wb_serial_sel;
  reg                       wb_serial_ack;
  wire                      wb_serial_cyc;
  wire                      wb_serial_stb;
  always @(posedge clk_i) begin
    wb_serial_ack <= (wb_serial_cyc & wb_serial_stb);
  end

  // Wishbone connected LED driver.
  wire [WB_SADDR_WIDTH-1:0] wb_ledpwm_addr;
  wire [WB_DATA_WIDTH-1:0]  wb_ledpwm_rdata = 16'h2222;
  wire [WB_DATA_WIDTH-1:0]  wb_ledpwm_wdata;
  wire                      wb_ledpwm_we;
  wire [WB_SEL_WIDTH-1:0]   wb_ledpwm_sel;
  reg                       wb_ledpwm_ack;
  wire                      wb_ledpwm_cyc;
  wire                      wb_ledpwm_stb;
  always @(posedge clk_i) begin
    wb_ledpwm_ack <= (wb_ledpwm_cyc & wb_ledpwm_stb);
  end

  // Access to the display
  wire [WB_SADDR_WIDTH-1:0] wb_display_addr;
  wire [WB_DATA_WIDTH-1:0]  wb_display_rdata = 16'h3333;
  wire [WB_DATA_WIDTH-1:0]  wb_display_wdata;
  wire                      wb_display_we;
  wire [WB_SEL_WIDTH-1:0]   wb_display_sel;
  reg                       wb_display_ack;
  wire                      wb_display_cyc;
  wire                      wb_display_stb;
  always @(posedge clk_i) begin
    wb_display_ack <= (wb_display_cyc & wb_display_stb);
  end

  // SPI Interface
  wire [WB_SADDR_WIDTH-1:0] wb_spi_addr;
  wire [WB_DATA_WIDTH-1:0]  wb_spi_rdata = 16'h4444;
  wire [WB_DATA_WIDTH-1:0]  wb_spi_wdata;
  wire                      wb_spi_we;
  wire [WB_SEL_WIDTH-1:0]   wb_spi_sel;
  reg                       wb_spi_ack;
  wire                      wb_spi_cyc;
  wire                      wb_spi_stb;
  always @(posedge clk_i) begin
    wb_spi_ack <= (wb_spi_cyc & wb_spi_stb);
  end
  

  wbcrouter#(
    .NS( 4 ), // Number of slaves
    .AW( ADDRESS_WIDTH ),
    .DW( WB_DATA_WIDTH ),
    .MUXWIDTH(4),
    .SLAVE_MUX({
        { 4'h0 },  // Base address of the PWM driver.           0x40000000
        { 4'h1 },  // Base address of the USB Serial interface. 0x40010000
        { 4'h2 },  // Base address of the LED Driver interface. 0x40020000
        { 4'h3 }   // Base address of the SPI interface         0x40030000
    })
  ) vexrouter (
    .i_clk  ( clk_i ),
    .i_reset( rst_i ),

    // Crossbar Master Ports.
    .i_mcyc  ( wb_peripherals_cyc   ),
    .i_mstb  ( wb_peripherals_stb   ),
    .i_mwe   ( wb_peripherals_we    ),
    .i_maddr ( wb_peripherals_addr  ),
    .i_mdata ( wb_peripherals_wdata ),
    .i_msel  ( wb_peripherals_sel   ),
    .o_mack  ( wb_peripherals_ack   ),
    .o_merr  ( wb_peripherals_err   ),
    .o_mdata ( wb_peripherals_rdata ),

    // Crossbar Slave Ports.
    .o_scyc  ({ wb_ledpwm_cyc,   wb_serial_cyc,   wb_display_cyc,   wb_spi_cyc   }),
    .o_sstb  ({ wb_ledpwm_stb,   wb_serial_stb,   wb_display_stb,   wb_spi_stb   }),
    .o_swe   ({ wb_ledpwm_we,    wb_serial_we,    wb_display_we,    wb_spi_we    }),
    .o_saddr ({ wb_ledpwm_addr,  wb_serial_addr,  wb_display_addr,  wb_spi_addr  }),
    .o_sdata ({ wb_ledpwm_wdata, wb_serial_wdata, wb_display_wdata, wb_spi_wdata }),
    .o_ssel  ({ wb_ledpwm_sel,   wb_serial_sel,   wb_display_sel,   wb_spi_sel   }),
    .i_sack  ({ wb_ledpwm_ack,   wb_serial_ack,   wb_display_ack,   wb_spi_ack   }),
    .i_serr  ({ 1'b0,            1'b0,            1'b0,             1'b0         }),
    .i_sdata ({ wb_ledpwm_rdata, wb_serial_rdata, wb_display_rdata, wb_spi_rdata })
  );
  

  

  initial begin
    transfer_address = 16'h1000;
    payload_in       = 16'h0000;
    payload_length   = 0;
    start_read       = 1'b0;
    start_write      = 1'b0;

    wait(rst);
    wait(!rst);
    repeat(2) @(posedge clk);

    transfer_address = 16'h3000;
    payload_in       = 16'h22_11;
    payload_length   = 1;
    start_write      = 1;
    @(posedge clk);
    start_write      = 0;
    repeat(10) @(posedge clk);

    transfer_address = 16'h2000;
    payload_in       = 16'h22_11;
    payload_length   = 1;
    start_write      = 1;
    @(posedge clk);
    start_write      = 0;
    repeat(10) @(posedge clk);
        
    
    transfer_address = 16'h1000;
    payload_in       = 16'h22_11;
    payload_length   = 1;
    start_write      = 1;
    @(posedge clk);
    start_write      = 0;
    repeat(10) @(posedge clk);
        
    
    transfer_address = 16'h0000;
    payload_in       = 16'h0201;
    payload_length   = 1;
    @(posedge clk);
    start_read  = 1'b1;
    start_write = 1'b0;
    @(posedge clk);
    start_read  = 1'b0;
    start_write = 1'b0;
    
    repeat(10) @(posedge clk);
    @(posedge clk);
    start_read  = 1'b0;
    start_write = 1'b1;
    @(posedge clk);
    start_read  = 1'b0;
    start_write = 1'b0;
    
    repeat(10) @(posedge clk);
    @(posedge clk);
    start_read  = 1'b0;
    start_write = 1'b1;
    @(posedge clk);
    start_read  = 1'b0;
    start_write = 1'b0;
  end


endmodule
