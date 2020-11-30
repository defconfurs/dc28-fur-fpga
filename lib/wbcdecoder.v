/*
 * This file is part of the DEFCON Furs DC28 badge project.
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2020 DEFCON Furs <https://dcfurs.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
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
