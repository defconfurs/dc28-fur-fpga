module test_pattern_tb #() ();

    localparam ADDRESS_WIDTH = 16;
    localparam DATA_WIDTH    = 8;
    localparam DATA_BYTES    = 1;

    reg                          rst_i;
    reg                          clk_i;
                                 
    wire [ADDRESS_WIDTH-1:0]     adr_o;
    reg [DATA_WIDTH-1:0]         dat_i;
    wire [DATA_WIDTH-1:0]        dat_o;
    wire                         we_o;
    wire [DATA_BYTES-1:0]        sel_o;
    wire                         stb_o;
    reg                          cyc_i;
    wire                         cyc_o;
    reg                          ack_i;
    wire [2:0]                   cti_o;

    wire                         clk;
    wire                         rst;
    
  test_pattern #(
  ) test_pattern_inst (
    .rst_i ( rst_i ),
    .clk_i ( clk_i ),
    .adr_o ( adr_o ),
    .dat_i ( dat_i ),
    .dat_o ( dat_o ),
    .we_o  ( we_o ),
    .sel_o ( sel_o ),
    .stb_o ( stb_o ),
    .cyc_i ( cyc_i ),
    .cyc_o ( cyc_o ),
    .ack_i ( ack_i ),
    .cti_o ( cti_o )
  );


  localparam  CLOCK_PERIOD            = 100; // Clock period in ps
  localparam  INITIAL_RESET_CYCLES    = 10;  // Number of cycles to reset when simulation starts
  // Clock signal generator
  initial clk_i = 1'b0;
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

  assign clk = clk_i;
  assign rst = rst_i;

  // Test cycle
  initial begin
  end

        
  initial begin
    dat_i = 0;
    cyc_i = 0;
  end
  always @(posedge clk) begin
    ack_i <= cyc_o;
    if (cyc_o) begin
      dat_i <= adr_o + 8'h10;
    end
  end
    
endmodule



