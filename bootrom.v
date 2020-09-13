`default_nettype none

module wbbootmem#(
    parameter   AW = 32,
    parameter   DW = 32,
    parameter   SIZE = 1024
) (
    // Wishbone interface.
    input wire            wb_clk_i,
    input wire            wb_reset_i,
    input wire [AW-1:0]   wb_adr_i,
    input wire [DW-1:0]   wb_dat_i,
    output reg [DW-1:0]   wb_dat_o,
    input wire            wb_we_i,
    input wire [DW/8-1:0] wb_sel_i,
    output reg            wb_ack_o,
    input wire            wb_cyc_i,
    input wire            wb_stb_i
  );

  wire [$clog2(SIZE)-1:0] sram_addr;
  assign sram_addr = wb_adr_i[$clog2(SIZE)-1:0];

  wire   stb_valid;
  assign stb_valid = wb_cyc_i && wb_stb_i && ~wb_ack_o;

  reg [DW-1:0] memory[SIZE-1:0];
  always @(posedge wb_clk_i) begin
    wb_ack_o <= stb_valid;
    if (stb_valid && ~wb_we_i) wb_dat_o <= memory[sram_addr];
  end

  // Handle writes, with byte-masking.
  genvar i;
  generate
    for (i = 0; i < DW; i = i + 8) begin
      always @(posedge wb_clk_i) begin
        if (stb_valid && wb_we_i && wb_sel_i[i / 8]) begin
          memory[sram_addr][i+7:i] <= wb_dat_i[i+7:i];
        end
      end
    end
  endgenerate

  initial begin
    $readmemh("firmware.mem", memory);
  end

endmodule

`default_nettype wire
