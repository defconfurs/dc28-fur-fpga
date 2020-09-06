`timescale 1ns/100ps
`default_nettype none

module wbcrouter #(
    parameter NS = 8,
    parameter AW = 32,
    parameter DW = 32,
    parameter SW = DW/8,
    parameter MUXWIDTH = 3,
    localparam SAW = (AW - MUXWIDTH),
    parameter [NS*MUXWIDTH-1:0] SLAVE_MUX = ({
        { 3'b111 },
        { 3'b110 },
        { 3'b101 },
        { 3'b100 },
        { 3'b011 },
        { 3'b010 },
        { 3'b001 },
        { 3'b000 }
    })
) (
    input wire               i_clk,
    input wire               i_reset,

    // Wishbone Master Signals.
    input wire               i_mcyc,
    input wire               i_mstb,
    input wire               i_mwe,
    input wire [AW-1:0]      i_maddr,
    input wire [DW-1:0]      i_mdata,
    input wire [SW-1:0]      i_msel,
    output reg               o_mack,
    output reg [DW-1:0]      o_mdata,
    output reg               o_merr,

    // Wishbone Slave Signals.
    output wire [NS-1:0]     o_scyc,
    output wire [NS-1:0]     o_sstb,
    output wire [NS-1:0]     o_swe,
    output wire [NS*SAW-1:0] o_saddr,
    output wire [NS*DW-1:0]  o_sdata,
    output wire [NS*SW-1:0]  o_ssel,
    input wire [NS-1:0]      i_sack,
    input wire [NS*DW-1:0]   i_sdata,
    input wire [NS-1:0]      i_serr
  );

  // Muxing Selections.
  wire [NS-1:0]           m_decode_hit;
  wire [MUXWIDTH-1:0]     m_addr_top = i_maddr[AW-1 : AW-MUXWIDTH];

  genvar                  gS;
  integer                 iS;
  generate
    // Connect master outputs to slave inputs.
    for (gS = 0; gS < NS; gS = gS + 1) begin
      assign m_decode_hit[gS] = (m_addr_top == SLAVE_MUX[(gS*MUXWIDTH)+MUXWIDTH-1 : (gS*MUXWIDTH)]);

      // Wire outputs to master from the mux array.
      assign o_scyc[gS]                     = m_decode_hit[gS] & i_mcyc;
      assign o_sstb[gS]                     = m_decode_hit[gS] & i_mstb;
      assign o_swe[gS]                      = m_decode_hit[gS] & i_mwe;
      assign o_saddr[SAW+(gS*SAW)-1:gS*SAW] = i_maddr[SAW-1:0];
      assign o_sdata[DW+(gS*DW)-1:gS*DW]    = i_mdata;
      assign o_ssel[SW+(gS*SW)-1:gS*SW]     = i_msel;
    end

    // Connect slave outputs to master inputs.
    always @(*) begin
      // set defaults
      o_mack  = 0;
      o_mdata = 0;
      o_merr  = 0;

      for (iS = 0; iS < NS; iS = iS + 1) begin
        if (m_decode_hit[iS]) begin
          o_mack  = i_sack[iS];
          o_mdata = i_sdata[DW+(iS*DW)-1 : iS*DW];
          o_merr  = i_serr[iS];
        end
      end
    end
    
  endgenerate
endmodule

`default_nettype wire
