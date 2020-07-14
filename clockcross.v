module cc_reg #(
    parameter WIDTH = 1,
    parameter DELAY = 2  // 2 for metastability, larger for testing
) (
    input wire              in_clk,
    input wire [WIDTH-1:0]  in,
    input wire              out_clk,
    output wire [WIDTH-1:0] out
  );

  reg [WIDTH-1:0] data_in;
  reg [WIDTH-1:0] data [DELAY-1:0];

  always @(posedge in_clk) data_in <= in;
  
  genvar          i;
  generate
    if (DELAY > 1) begin
      for (i = 1; i < DELAY; i = i+1) begin
        always @(posedge out_clk) data[i] <= data[i-1];
      end
    end
  endgenerate
  
  always @(posedge out_clk) data[0] <= data_in;

  assign out = data[DELAY-1];
    
endmodule

