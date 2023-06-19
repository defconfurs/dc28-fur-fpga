module wbcxbar_2x8 #(
        parameter HAW = 32, // Host address-width
        parameter DAW = 24, // Device address-width; must be at least 4-bits smaller than HAW
        parameter DW = 32,
        parameter SW = DW/8
    ) (
        input wire clk,
        input wire rst,

        //----------------------------------------------------------
        // Host-facing interfaces (device signals)
        input  wire           wb_host0_cyc,
        input  wire           wb_host0_stb,
        input  wire           wb_host0_we,
        input  wire [HAW-1:0] wb_host0_addr,
        input  wire [DW-1:0]  wb_host0_wdata,
        input  wire [SW-1:0]  wb_host0_sel,
        output wire           wb_host0_ack,
        output wire           wb_host0_err,
        output wire [DW-1:0]  wb_host0_rdata,

        input  wire           wb_host1_cyc,
        input  wire           wb_host1_stb,
        input  wire           wb_host1_we,
        input  wire [HAW-1:0] wb_host1_addr,
        input  wire [DW-1:0]  wb_host1_wdata,
        input  wire [SW-1:0]  wb_host1_sel,
        output wire           wb_host1_ack,
        output wire           wb_host1_err,
        output wire [DW-1:0]  wb_host1_rdata,

        //----------------------------------------------------------
        // Device-facing interfaces (host signals)
        output wire           wb_dev0_cyc,
        output wire           wb_dev0_stb,
        output wire           wb_dev0_we,
        output wire [DAW-1:0] wb_dev0_addr,
        output wire [DW-1:0]  wb_dev0_wdata,
        output wire [SW-1:0]  wb_dev0_sel,
        input  wire           wb_dev0_ack,
        input  wire           wb_dev0_err,
        input  wire [DW-1:0]  wb_dev0_rdata,

        output wire           wb_dev1_cyc,
        output wire           wb_dev1_stb,
        output wire           wb_dev1_we,
        output wire [DAW-1:0] wb_dev1_addr,
        output wire [DW-1:0]  wb_dev1_wdata,
        output wire [SW-1:0]  wb_dev1_sel,
        input  wire           wb_dev1_ack,
        input  wire           wb_dev1_err,
        input  wire [DW-1:0]  wb_dev1_rdata,

        output wire           wb_dev2_cyc,
        output wire           wb_dev2_stb,
        output wire           wb_dev2_we,
        output wire [DAW-1:0] wb_dev2_addr,
        output wire [DW-1:0]  wb_dev2_wdata,
        output wire [SW-1:0]  wb_dev2_sel,
        input  wire           wb_dev2_ack,
        input  wire           wb_dev2_err,
        input  wire [DW-1:0]  wb_dev2_rdata,

        output wire           wb_dev3_cyc,
        output wire           wb_dev3_stb,
        output wire           wb_dev3_we,
        output wire [DAW-1:0] wb_dev3_addr,
        output wire [DW-1:0]  wb_dev3_wdata,
        output wire [SW-1:0]  wb_dev3_sel,
        input  wire           wb_dev3_ack,
        input  wire           wb_dev3_err,
        input  wire [DW-1:0]  wb_dev3_rdata,

        output wire           wb_dev4_cyc,
        output wire           wb_dev4_stb,
        output wire           wb_dev4_we,
        output wire [DAW-1:0] wb_dev4_addr,
        output wire [DW-1:0]  wb_dev4_wdata,
        output wire [SW-1:0]  wb_dev4_sel,
        input  wire           wb_dev4_ack,
        input  wire           wb_dev4_err,
        input  wire [DW-1:0]  wb_dev4_rdata,

        output wire           wb_dev5_cyc,
        output wire           wb_dev5_stb,
        output wire           wb_dev5_we,
        output wire [DAW-1:0] wb_dev5_addr,
        output wire [DW-1:0]  wb_dev5_wdata,
        output wire [SW-1:0]  wb_dev5_sel,
        input  wire           wb_dev5_ack,
        input  wire           wb_dev5_err,
        input  wire [DW-1:0]  wb_dev5_rdata,

        output wire           wb_dev6_cyc,
        output wire           wb_dev6_stb,
        output wire           wb_dev6_we,
        output wire [DAW-1:0] wb_dev6_addr,
        output wire [DW-1:0]  wb_dev6_wdata,
        output wire [SW-1:0]  wb_dev6_sel,
        input  wire           wb_dev6_ack,
        input  wire           wb_dev6_err,
        input  wire [DW-1:0]  wb_dev6_rdata,

        output wire           wb_dev7_cyc,
        output wire           wb_dev7_stb,
        output wire           wb_dev7_we,
        output wire [DAW-1:0] wb_dev7_addr,
        output wire [DW-1:0]  wb_dev7_wdata,
        output wire [SW-1:0]  wb_dev7_sel,
        input  wire           wb_dev7_ack,
        input  wire           wb_dev7_err,
        input  wire [DW-1:0]  wb_dev7_rdata
    );

    // Create the Wishbone crossbar.
    wbcxbar#(
        .NM(2), // One port each for instruction and data access from the CPU.
        .AW(AW),
        .DW(DW),
        .MUXWIDTH(4),
        .NS(8),
        .SAW(DAW),
        .SLAVE_MUX({
            { 4'h0 },
            { 4'h1 },
            { 4'h2 },
            { 4'h3 },
            { 4'h4 },
            { 4'h5 },
            { 4'h6 },
            { 4'h7 }
        })
    ) vexcrossbar (
        .i_clk  ( clk ),
        .i_reset( rst ),
    
        // Crossbar Master Ports.
        .i_mcyc  ({ wb_host0_cyc,   wb_host1_cyc   }),
        .i_mstb  ({ wb_host0_stb,   wb_host1_stb   }),
        .i_mwe   ({ wb_host0_we,    wb_host1_we    }),
        .i_maddr ({ wb_host0_addr,  wb_host1_addr  }),
        .i_mdata ({ wb_host0_wdata, wb_host1_wdata }),
        .i_msel  ({ wb_host0_sel,   wb_host1_sel   }),
        .o_mack  ({ wb_host0_ack,   wb_host1_ack   }),
        .o_merr  ({ wb_host0_err,   wb_host1_err   }),
        .o_mdata ({ wb_host0_rdata, wb_host1_rdata }),
    
        // Crossbar Slave Ports.
        .o_scyc  ({ wb_dev0_cyc,    wb_dev1_cyc,    wb_dev2_cyc,    wb_dev3_cyc,    wb_dev4_cyc,    wb_dev5_cyc,    wb_dev6_cyc,    wb_dev7_cyc   }),
        .o_sstb  ({ wb_dev0_stb,    wb_dev1_stb,    wb_dev2_stb,    wb_dev3_stb,    wb_dev4_stb,    wb_dev5_stb,    wb_dev6_stb,    wb_dev7_stb   }),
        .o_swe   ({ wb_dev0_we,     wb_dev1_we,     wb_dev2_we,     wb_dev3_we,     wb_dev4_we,     wb_dev5_we,     wb_dev6_we,     wb_dev7_we    }),
        .o_saddr ({ wb_dev0_addr,   wb_dev1_addr,   wb_dev2_addr,   wb_dev3_addr,   wb_dev4_addr,   wb_dev5_addr,   wb_dev6_addr,   wb_dev7_addr  }),
        .o_sdata ({ wb_dev0_wdata,  wb_dev1_wdata,  wb_dev2_wdata,  wb_dev3_wdata,  wb_dev4_wdata,  wb_dev5_wdata,  wb_dev6_wdata,  wb_dev7_wdata }),
        .o_ssel  ({ wb_dev0_sel,    wb_dev1_sel,    wb_dev2_sel,    wb_dev3_sel,    wb_dev4_sel,    wb_dev5_sel,    wb_dev6_sel,    wb_dev7_sel   }),
        .i_sack  ({ wb_dev0_ack,    wb_dev1_ack,    wb_dev2_ack,    wb_dev3_ack,    wb_dev4_ack,    wb_dev5_ack,    wb_dev6_ack,    wb_dev7_ack   }),
        .i_serr  ({ wb_dev0_err,    wb_dev1_err,    wb_dev2_err,    wb_dev3_err,    wb_dev4_err,    wb_dev5_err,    wb_dev6_err,    wb_dev7_err   }),
        .i_sdata ({ wb_dev0_rdata,  wb_dev1_rdata,  wb_dev2_rdata,  wb_dev3_rdata,  wb_dev4_rdata,  wb_dev5_rdata,  wb_dev6_rdata,  wb_dev7_rdata }) 
    );

endmodule
