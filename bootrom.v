module bootrom#(
    parameter   AW = 32,
    parameter   DW = 32,
    parameter   SIZE = 1024
) (
    // Wishbone interface.
    input               wb_clk_i,
    input               wb_reset_i,
    input  [AW-1:0]     wb_adr_i,
    input  [DW-1:0]     wb_dat_i,
    output reg [DW-1:0] wb_dat_o,
    input               wb_we_i,
    input  [DW/8-1:0]   wb_sel_i,
    output reg          wb_ack_o,
    input               wb_cyc_i,
    input               wb_stb_i
);

localparam SIZE_BITS = $clog2(SIZE);

wire stb_valid;
assign stb_valid = wb_cyc_i && wb_stb_i && !wb_ack_o;

reg [DW-1:0] memory[SIZE-1:0];
always @(posedge wb_clk_i) begin
    wb_ack_o <= stb_valid;
    if (stb_valid && ~wb_we_i) wb_dat_o <= memory[wb_adr_i[SIZE_BITS-1:0]];
end

initial begin
    $readmemh("firmware.mem", memory);
end

endmodule
