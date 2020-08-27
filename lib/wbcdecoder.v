module wbcdecoder#(
    parameter ADDRWIDTH = 32,
    parameter OUTWIDTH = 4,
    parameter MUXWIDTH = 3,
    parameter NS = 8,
    parameter SLAVE_MUX = {
        { 3'b111 },
        { 3'b110 },
        { 3'b101 },
        { 3'b100 },
        { 3'b011 },
        { 3'b010 },
        { 3'b001 },
        { 3'b000 }
    }
) (
    input [ADDRWIDTH-1:0] addr,
    output reg [OUTWIDTH-1:0] decode
);

wire [NS-1:0] addr_hit;
wire [MUXWIDTH-1:0] addr_top;
assign addr_top = addr[ADDRWIDTH-1:ADDRWIDTH-MUXWIDTH];

genvar i;
integer x;
generate
    for (i = 0; i < NS*MUXWIDTH; i = i + MUXWIDTH) begin
        assign addr_hit[i/MUXWIDTH] = (addr_top == SLAVE_MUX[i+MUXWIDTH-1 : i]);
    end
    always @(*) begin
        decode = {(OUTWIDTH){1'b1}};
        for (x = 0; x < NS; x = x + 1) begin
            if (addr_hit[x]) decode = x[OUTWIDTH-1:0];
        end
    end
endgenerate
endmodule
