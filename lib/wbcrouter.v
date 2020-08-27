module wbcrouter#(
    parameter NS = 8,
    parameter AW = 32,
    parameter DW = 32,
    parameter SW = DW/8,
    parameter MUXWIDTH = 3,
    localparam SAW = AW - MUXWIDTH,
    parameter [NS*MUXWIDTH-1:0] SLAVE_MUX = {
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

  localparam M_GRANT_BITS = $clog2(NS+1);
  localparam M_GRANT_SIZE = (1 << M_GRANT_BITS);

  wire          m_sack[M_GRANT_SIZE-1:0];
  wire [DW-1:0] m_sdata[M_GRANT_SIZE-1:0];
  wire          m_serr[M_GRANT_SIZE-1:0];
  
  // Muxing Selections.
  wire [M_GRANT_BITS-1:0] m_decode;   /* Decoded slave the master is requesting. */

  genvar                  gS;
  integer                 iS;
  generate
    ///////////////////////////////////
    // Master Decoding and Multiplexing
    ///////////////////////////////////
    // Decode the master address.
    wbcdecoder#(
      .ADDRWIDTH(AW),
      .MUXWIDTH(MUXWIDTH),
      .OUTWIDTH(M_GRANT_BITS),
      .SLAVE_MUX(SLAVE_MUX)
    ) m_decode_inst (
      .addr(i_maddr),
      .decode(m_decode)
    );

    ///////////////////////////////////
    // Slave Decoding and Multiplexing
    ///////////////////////////////////
    for (gS = 0; gS < NS; gS = gS + 1) begin
      // Wire inputs from slave to the mux array.
      assign m_sack[gS]  = i_sack[gS];
      assign m_sdata[gS] = i_sdata[DW+(gS*DW)-1:gS*DW];
      assign m_serr[gS]  = i_serr[gS];

      // Wire outputs to master from the mux array.
      assign o_scyc[gS]                     = m_decode[gS] & i_mcyc;
      assign o_sstb[gS]                     = m_decode[gS] & i_mstb;
      assign o_swe[gS]                      = m_decode[gS] & i_mwe;
      assign o_saddr[SAW+(gS*SAW)-1:gS*SAW] = {SAW{m_decode[gS]}} & i_maddr[SAW:0];
      assign o_sdata[DW+(gS*DW)-1:gS*DW]    = {DW{m_decode[gS]}} & i_mdata;
      assign o_ssel[SW+(gS*SW)-1:gS*SW]     = {SW{m_decode[gS]}} & i_msel;
    end
    // Fill the remainder of the mux array with empty data, to
    // set the un-selected state of the outputs to the master.
    for (gS = NS; gS < M_GRANT_SIZE; gS = gS + 1) begin
      assign m_sdata[gS] = {DW{1'b0}};
      assign m_sack[gS]  = 1'b0;
      assign m_serr[gS]  = 1'b0;
    end

    // Connect up the slave to the master
    always @(*) begin
      // set defaults
      o_mack  = 0;
      o_mdata = 0;
      o_merr  = 0;

      for (iS = 0; iS < M_GRANT_BITS; iS = iS + 1) begin
        if (m_decode[iS]) begin
          o_mack  = m_sack[iS];
          o_mdata = m_sdata[iS];
          o_merr  = m_serr[iS];
        end
      end
    end
    
endgenerate
endmodule
