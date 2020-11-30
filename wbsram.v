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

`default_nettype none

module wbsram#(
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

  localparam SIZE_BITS = $clog2(SIZE);

  wire [SIZE_BITS-1:0] sram_addr;
  assign sram_addr = wb_adr_i[SIZE_BITS-1:0];

  ///////////////////////////////////////
  // The SRAM memory block.
  ///////////////////////////////////////
  wire   stb_valid;
  assign stb_valid = wb_cyc_i && wb_stb_i && ~wb_ack_o;

  reg [DW-1:0] memory[SIZE-1:0];
  always @(posedge wb_clk_i) begin
    wb_ack_o <= stb_valid;
    if (stb_valid && ~wb_we_i) wb_dat_o <= memory[wb_adr_i[SIZE_BITS-1:0]];
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

endmodule


module wbspram #(
    parameter AW = 32,
    parameter DW = 32
)  (
    // Wishbone interface.
    input wire            wb_clk_i,
    input wire            wb_reset_i,
    input wire [AW-1:0]   wb_adr_i,
    input wire [DW-1:0]   wb_dat_i,
    output wire [DW-1:0]  wb_dat_o,
    input wire            wb_we_i,
    input wire [DW/8-1:0] wb_sel_i,
    output reg            wb_ack_o,
    input wire            wb_cyc_i,
    input wire            wb_stb_i
  );

  ///////////////////////////////////////
  // The SRAM memory block.
  ///////////////////////////////////////
  wire   stb_valid;
  assign stb_valid = wb_cyc_i && wb_stb_i && ~wb_ack_o;

  always @(posedge wb_clk_i) begin
    wb_ack_o <= stb_valid;
  end

  wire   write_cycle;
  assign write_cycle = stb_valid | wb_we_i;
  
  SB_SPRAM256KA ramfn_inst1 (
    .CLOCK      ( wb_clk_i ),
    .STANDBY    (1'b0),
    .SLEEP      (1'b0),
    .POWEROFF   (1'b1),

    .ADDRESS    ( wb_adr_i[13:0] ),
    .DATAIN     ( wb_dat_i[15:0] ),
    .MASKWREN   ( { wb_sel_i[1], wb_sel_i[1], wb_sel_i[0], wb_sel_i[0] } & { (DW/8) { wb_we_i }} ),
    .WREN       ( (wb_sel_i[1] | wb_sel_i[0]) && wb_we_i && stb_valid ),
    .CHIPSELECT ( 1 ),
    .DATAOUT    ( wb_dat_o[15:0] )
  );

  SB_SPRAM256KA ramfn_inst2 (
    .CLOCK      ( wb_clk_i ),
    .STANDBY    (1'b0),
    .SLEEP      (1'b0),
    .POWEROFF   (1'b1),

    .ADDRESS    ( wb_adr_i[13:0] ),
    .DATAIN     ( wb_dat_i[31:16] ),
    .MASKWREN   ( { wb_sel_i[3], wb_sel_i[3], wb_sel_i[2], wb_sel_i[2] } & { (DW/8) { wb_we_i }} ),
    .WREN       ( (wb_sel_i[3] | wb_sel_i[2]) && wb_we_i && stb_valid ),
    .CHIPSELECT ( 1 ),
    .DATAOUT    ( wb_dat_o[31:16] )
  );
  
endmodule

`default_nettype wire
