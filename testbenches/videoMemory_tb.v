module video_memory_tb #() ();

  localparam ADDRESS_WIDTH = 16;
  localparam DATA_WIDTH    = 8;
  localparam DATA_BYTES    = 1;

  reg                          rst_i;
  reg                          clk_i;
                                 
  reg [ADDRESS_WIDTH-1:0]      adr;
  reg [DATA_WIDTH-1:0]         dat_i;
  wire [DATA_WIDTH-1:0]        dat_o;
  reg                          we;
  reg [DATA_BYTES-1:0]         sel;
  reg                          stb;
  reg                          cyc;
  wire                         ack;
  reg [2:0]                    cti = 0;

  wire                         clk;
  wire                         rst;
  
  wire [3:0]                   spi_d_out;
  wire [3:0]                   spi_d_dir;
  reg [3:0]                    spi_d_in;
  wire                         spi_clk;
  wire                         spi_sel;

  reg                          dfu_busy;
  
  assign clk = clk_i;
  assign rst = rst_i;
       
  video_memory #(
  ) video_memory_inst (
    .clk_i ( clk   ),
    .rst_i ( rst   ),
    .adr_i ( adr   ),
    .dat_i ( dat_i ),
    .dat_o ( dat_o ),
    .we_i  ( we    ),
    .sel_i ( sel   ),
    .stb_i ( stb   ),
    .cyc_i ( cyc   ),
    .ack_o ( ack   ),
    .cti_i ( cti   ),

    .dfu_busy  ( dfu_busy  ),
    
    .spi_clk   ( spi_clk   ),
    .spi_sel   ( spi_sel   ),
    .spi_d_out ( spi_d_out ),
    .spi_d_in  ( spi_d_in  ),
    .spi_d_dir ( spi_d_dir )
  );


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


  // Test cycle
  initial begin
    adr      = 16'h0000;
    dat_i    = 8'h00;
    we       = 0;
    sel      = 0;
    stb      = 0;
    cyc      = 0;
    cti      = 0;
    dfu_busy = 0;

    wait(rst);
    wait(!rst);
    repeat(10) @(posedge clk);

    adr   = 16'h8002;
    dat_i = 8'h11;
    we    = 1;
    sel   = 1;
    stb   = 1;
    cyc   = 1;

    while (!ack) @(posedge clk);

    adr   = 16'h8003;
    dat_i = 8'h22;

    @(posedge clk);
    
    adr   = 16'h8004;
    dat_i = 1;
    
    @(posedge clk);

    adr   = 16'h8005;
    dat_i = 0;
    
    @(posedge clk);

    adr   = 16'h8000;
    dat_i = 1;
    
    @(posedge clk);

    we    = 0;
    sel   = 0;
    stb   = 0;
    cyc   = 0;
    cti   = 0;
  end

  always @(posedge clk) begin
    spi_d_in = 0;
  end
  
  
    
endmodule



