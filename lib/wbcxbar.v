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
module wbcxbar#(
    parameter NM = 4,
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
    input               i_clk,
    input               i_reset,

    // Wishbone Master Signals.
    input [NM-1:0]      i_mcyc,
    input [NM-1:0]      i_mstb,
    input [NM-1:0]      i_mwe,
    input [NM*AW-1:0]   i_maddr,
    input [NM*DW-1:0]   i_mdata,
    input [NM*SW-1:0]   i_msel,
    output [NM-1:0]     o_mack,
    output [NM*DW-1:0]  o_mdata,
    output [NM-1:0]     o_merr,

    // Wishbone Slave Signals.
    output [NS-1:0]     o_scyc,
    output [NS-1:0]     o_sstb,
    output [NS-1:0]     o_swe,
    output [NS*SAW-1:0] o_saddr,
    output [NS*DW-1:0]  o_sdata,
    output [NS*SW-1:0]  o_ssel,
    input [NS-1:0]      i_sack,
    input [NS*DW-1:0]   i_sdata,
    input [NS-1:0]      i_serr
);

localparam M_GRANT_BITS = $clog2(NS+1);
localparam M_GRANT_SIZE = (1 << M_GRANT_BITS);
localparam M_GRANT_NONE = {(M_GRANT_BITS){1'b1}};

localparam S_GRANT_BITS = $clog2(NM+1);
localparam S_GRANT_SIZE = (1 << S_GRANT_BITS);
localparam S_GRANT_NONE = {(S_GRANT_BITS){1'b1}};

// Muxing Selections.
wire [M_GRANT_BITS-1:0] m_decode[NM-1:0];   /* Decoded slave the master is requesting. */
wire [NM-1:0]           m_request[NS-1:0];  /* For each slave, a bit mask of the masters requesting access */
reg [M_GRANT_BITS-1:0]  m_grant[NM-1:0];    /* Slave to which a master has been granted access */

// Master input signals, padded for muxing.
wire            m_mcyc[S_GRANT_SIZE-1:0];
wire            m_mstb[S_GRANT_SIZE-1:0];
wire            m_mwe[S_GRANT_SIZE-1:0];
wire [AW-1:0]   m_maddr[S_GRANT_SIZE-1:0];
wire [DW-1:0]   m_mdata[S_GRANT_SIZE-1:0];
wire [SW-1:0]   m_msel[S_GRANT_SIZE-1:0];

// Slave input signals, padded for muxing.
wire            m_sack[M_GRANT_SIZE-1:0];
wire [DW-1:0]   m_sdata[M_GRANT_SIZE-1:0];
wire            m_serr[M_GRANT_SIZE-1:0];

genvar gM, gS;
integer iM, iS;
generate
    ///////////////////////////////////
    // Master Decoding and Multiplexing
    ///////////////////////////////////
    for (gM = 0; gM < NM; gM = gM + 1) begin
        // Wire inputs from master to the mux array.
        assign m_mcyc[gM]  = i_mcyc[gM];
        assign m_mstb[gM]  = i_mstb[gM];
        assign m_mwe[gM]   = i_mwe[gM];
        assign m_maddr[gM] = i_maddr[AW+(gM*AW)-1:(gM*AW)];
        assign m_mdata[gM] = i_mdata[DW+(gM*DW)-1:(gM*DW)];
        assign m_msel[gM]  = i_msel[SW+(gM*SW)-1:(gM*SW)];

        // Wire outputs to master from the mux array.
        assign o_mack[gM]                   = m_sack[m_grant[gM]];
        assign o_mdata[DW+(gM*DW)-1:gM*DW]  = m_sdata[m_grant[gM]];
        assign o_merr[gM]                   = m_serr[m_grant[gM]];

        // Decode the master address.
        wbcdecoder#(
            .ADDRWIDTH(AW),
            .MUXWIDTH (MUXWIDTH),
            .OUTWIDTH (M_GRANT_BITS),
            .NS       (NS),
            .SLAVE_MUX(SLAVE_MUX)
        ) m_decode_inst (
            .addr(m_maddr[gM]),
            .decode(m_decode[gM])
        );

        // Build the bitmask of requsts for arbitration.
        for (gS = 0; gS < NS; gS = gS + 1) begin
            localparam s_addr_top = SLAVE_MUX[MUXWIDTH+(gS*MUXWIDTH)-1 : (gS*MUXWIDTH)];
            assign m_request[gS][gM] = (m_maddr[gM][AW-1:AW-MUXWIDTH] == s_addr_top) && i_mcyc[gM];
        end
    end
    // Fill the remainder of the mux array with empty data, to
    // set the un-selected state of the outputs to the slave.
    for (gM = NM; gM < S_GRANT_SIZE; gM = gM + 1) begin
        assign m_mcyc[gM]  = 1'b0;
        assign m_mstb[gM]  = 1'b0;
        assign m_mwe[gM]   = 1'b0;
        assign m_maddr[gM] = {(AW){1'b0}};
        assign m_mdata[gM] = {(DW){1'b0}};
        assign m_msel[gM]  = {(DW/8){1'b0}};
    end

    ///////////////////////////////////
    // Slave Decoding and Multiplexing
    ///////////////////////////////////
    for (gS = 0; gS < NS; gS = gS + 1) begin
        // Select the reverse grant direction.
        reg [S_GRANT_BITS-1:0] s_grant;
        always @(*) begin
            s_grant = S_GRANT_NONE;
            for (iM = 0; iM < NM; iM = iM + 1) begin
                if (m_grant[iM] == gS) s_grant = iM[S_GRANT_BITS-1:0];
            end
        end

        // Wire inputs from slave to the mux array.
        assign m_sack[gS]  = i_sack[gS];
        assign m_sdata[gS] = i_sdata[DW+(gS*DW)-1:gS*DW];
        assign m_serr[gS]  = i_serr[gS];

        // Wire outputs to master from the mux array.
        assign o_scyc[gS]                     = m_mcyc[s_grant];
        assign o_sstb[gS]                     = m_mstb[s_grant];
        assign o_swe[gS]                      = m_mwe[s_grant];
        assign o_saddr[SAW+(gS*SAW)-1:gS*SAW] = m_maddr[s_grant][SAW-1:0];
        assign o_sdata[DW+(gS*DW)-1:gS*DW]    = m_mdata[s_grant];
        assign o_ssel[SW+(gS*SW)-1:gS*SW]     = m_msel[s_grant];
    end
    // Fill the remainder of the mux array with empty data, to
    // set the un-selected state of the outputs to the master.
    for (gS = NS; gS < M_GRANT_SIZE; gS = gS + 1) begin
        assign m_sdata[gS] = 32'h00000000;
        assign m_sack[gS]  = 1'b0;
        assign m_serr[gS]  = 1'b0;
    end

    ///////////////////////////////////
    // The MxS arbiter
    ///////////////////////////////////
    for (gM = 0; gM < NM; gM = gM + 1) begin
        wire [M_GRANT_BITS-1:0] m_slave;
        wire m_slave_available;
        assign m_slave = m_decode[gM];
        if (gM) begin
            assign m_slave_available = m_request[m_slave][gM-1:0] == 0;
        end else begin
            assign m_slave_available = 1'b1;
        end

        always @(posedge i_clk) begin
            if (!i_mcyc[gM]) begin
                // Master is inactive, release the grant.
                m_grant[gM] <= M_GRANT_NONE;
            end
            else if (!o_scyc[m_decode[gM]] && m_slave_available) begin
                // Slave is inactive, and no higher-priority master is
                // requesting access, therefore we can acquire the grant.
                m_grant[gM] <= m_decode[gM];
            end
        end
    end
endgenerate
endmodule
