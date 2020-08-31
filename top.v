`include "globals.vh"

module top (
        input wire  pin_clk,
     
        inout wire  pin_usbp,
        inout wire  pin_usbn,
        output wire pin_pu,
        
        output wire pin_col_first,
        output wire pin_col_advance,
        output wire pin_row_oe_n,
        output wire pin_row_bank0,
        output wire pin_row_bank1,
        output wire pin_row_bank2,
        output wire pin_row_bank3,
        output wire pin_rclk,
        output wire pin_r0a,
        output wire pin_r0b,
        output wire pin_r1a,
        output wire pin_r1b,
        output wire pin_r2a,
        output wire pin_r2b,
        output wire pin_r3a,
        output wire pin_r3b,
        
        input wire  pin_mic_data,
        output wire pin_mic_clk,
        
        inout wire  pin_miso,
        inout wire  pin_mosi,
        inout wire  pin_wp,
        inout wire  pin_hold,
        output wire pin_cs,
        output wire pin_sck,
     
        input wire  pin_button_up,
        input wire  pin_button_down,
     
        output wire pin_stat_r,
        output wire pin_stat_g,
        output wire pin_stat_b,
                
        // addon header
        //                            GND
        output wire  pin_iob_9b, //  pin 3
        output wire  pin_iob_8a, //  pin 4
        output wire  pin_iob_13b, // pin 6
        //                           +3.3V
     
        input wire  pin_iot_38b, // pin 27
        input wire  pin_iob_29b, // pin 19
        input wire  pin_iob_23b  // pin 21
    );

    localparam WB_DATA_WIDTH = 32;
    localparam WB_SEL_WIDTH  = (WB_DATA_WIDTH / 8);
    localparam WB_ADDR_WIDTH = 32 - $clog2(WB_SEL_WIDTH);
    localparam WB_MUX_WIDTH  = 4;
    
    
    wire          stat_r;
    wire          stat_g;
    wire          stat_b;
    wire          stat_en;
  
    SB_RGBA_DRV #(
        .CURRENT_MODE ( "0b1"        ), // half current mode
        .RGB0_CURRENT ( "0b00000001" ), // 4mA
        .RGB1_CURRENT ( "0b00000001" ),
        .RGB2_CURRENT ( "0b00000001" )
    ) rgb_drv_inst (
        .RGBLEDEN ( stat_en    ),
        .CURREN   ( stat_en    ),
        .RGB0PWM  ( stat_r     ),
        .RGB1PWM  ( stat_g     ),
        .RGB2PWM  ( stat_b     ),
        .RGB0     ( pin_stat_r ),
        .RGB1     ( pin_stat_g ),
        .RGB2     ( pin_stat_b )
    );
    assign stat_en = 1;
  
    wire [15:0]   debug;
      
    wire [3:0]    latch_row_bank;
    wire [7:0]    row_data;
    wire          row_oe;
    wire          col_first;
    wire          col_advance;
    wire          col_rclk;
      
    assign pin_col_first   = col_first;
    assign pin_col_advance = col_advance;
    assign pin_row_oe_n    = row_oe;
    assign pin_row_bank0   = latch_row_bank[0];
    assign pin_row_bank1   = latch_row_bank[1];
    assign pin_row_bank2   = latch_row_bank[2];
    assign pin_row_bank3   = latch_row_bank[3];
    assign pin_rclk        = col_rclk;
    assign pin_r0a         = row_data[0];
    assign pin_r0b         = row_data[1];
    assign pin_r1a         = row_data[2];
    assign pin_r1b         = row_data[3];
    assign pin_r2a         = row_data[4];
    assign pin_r2b         = row_data[5];
  
    assign pin_r3a         = row_data[6];
    assign pin_r3b         = row_data[7];
  
  
    wire flash_busy;
    assign flash_busy = 0;
    
    wire       frame_complete;
      
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    ////////
    //////// Generate Clocks
    ////////
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    wire clk_48mhz;
    wire clk_locked;
    pll48mhz pll(
      .refclk(pin_clk),
      .clk_48mhz(clk_48mhz),
      .clk_locked(clk_locked)
    );
  
    wire lf_clk;
    SB_LFOSC LF_OscInst (
      .CLKLFPU (1),
      .CLKLFEN (1),
      .CLKLF   (lf_clk)
    );
  
    // Generate reset signal
    reg [3:0]     reset_cnt = 7;
    reg           reset;
    
    always @(posedge lf_clk) begin
      if (reset_cnt) begin
        reset     <= 1;
        reset_cnt <= reset_cnt - 1;
      end
      else begin
        reset     <= 0;
        reset_cnt <= 0;
      end
    end
  
    reg  clk_24mhz     = 0;
    always @(posedge clk_48mhz) clk_24mhz <= ~clk_24mhz;
    
    reg  clk_12mhz = 0;
    always @(posedge clk_24mhz) clk_12mhz <= ~clk_12mhz;
  
    reg  clk_6mhz = 0;
    always @(posedge clk_12mhz) clk_6mhz <= ~clk_6mhz;
    
    wire clk;
    wire rst;
    localparam CLK_FREQ = 12000000;
    assign clk = clk_12mhz;
    assign rst = reset;
  
    assign pin_iob_9b = 0;//clk_48mhz;
    assign pin_iob_8a = 0;//clk;
    assign pin_iob_13b = 0;//rst;
  
    localparam XBAR_ADDR_WIDTH = 4;
    localparam SELECTOR_ADDR_WIDTH = 4;
  
    localparam WB_XADDR_WIDTH = WB_ADDR_WIDTH - XBAR_ADDR_WIDTH;
    localparam WB_SADDR_WIDTH = WB_XADDR_WIDTH - SELECTOR_ADDR_WIDTH - 8;
    
    //---------------------------------------------------------------
    // CPU wishbone components
    wire [WB_SADDR_WIDTH-1:0] wb_serial_addr;
    wire [WB_DATA_WIDTH-1:0]  wb_serial_rdata;
    wire [WB_DATA_WIDTH-1:0]  wb_serial_wdata;
    wire                      wb_serial_we;
    wire [WB_SEL_WIDTH-1:0]   wb_serial_sel;
    wire                      wb_serial_ack;
    wire                      wb_serial_cyc;
    wire                      wb_serial_stb;
    
    // Wishbone connected LED driver.
    wire [WB_SADDR_WIDTH-1:0] wb_misc_addr;
    wire [WB_DATA_WIDTH-1:0]  wb_misc_rdata;
    wire [WB_DATA_WIDTH-1:0]  wb_misc_wdata;
    wire                      wb_misc_we;
    wire [WB_SEL_WIDTH-1:0]   wb_misc_sel;
    wire                      wb_misc_ack;
    wire                      wb_misc_cyc;
    wire                      wb_misc_stb;
  
    // Instantiate the boot ROM.
    wire [WB_XADDR_WIDTH-1:0] wb_bootrom_addr;
    wire [WB_DATA_WIDTH-1:0]  wb_bootrom_rdata;
    wire [WB_DATA_WIDTH-1:0]  wb_bootrom_wdata;
    wire                      wb_bootrom_we;
    wire [WB_SEL_WIDTH-1:0]   wb_bootrom_sel;
    wire                      wb_bootrom_ack;
    wire                      wb_bootrom_cyc;
    wire                      wb_bootrom_stb;
  
    // Instantiate the SRAM.
    wire [WB_XADDR_WIDTH-1:0] wb_sram_addr;
    wire [WB_DATA_WIDTH-1:0]  wb_sram_rdata;
    wire [WB_DATA_WIDTH-1:0]  wb_sram_wdata;
    wire                      wb_sram_we;
    wire [WB_SEL_WIDTH-1:0]   wb_sram_sel;
    wire                      wb_sram_ack;
    wire                      wb_sram_cyc;
    wire                      wb_sram_stb;
  
    // Instantiate the SPRAM.
    wire [WB_XADDR_WIDTH-1:0] wb_spram_addr;
    wire [WB_DATA_WIDTH-1:0]  wb_spram_rdata;
    wire [WB_DATA_WIDTH-1:0]  wb_spram_wdata;
    wire                      wb_spram_we;
    wire [WB_SEL_WIDTH-1:0]   wb_spram_sel;
    wire                      wb_spram_ack;
    wire                      wb_spram_cyc;
    wire                      wb_spram_stb;
  
    // SPI Interface
    wire [WB_XADDR_WIDTH-1:0] wb_spi_addr;
    wire [WB_DATA_WIDTH-1:0]  wb_spi_rdata;
    wire [WB_DATA_WIDTH-1:0]  wb_spi_wdata;
    wire                      wb_spi_we;
    wire [WB_SEL_WIDTH-1:0]   wb_spi_sel;
    wire                      wb_spi_ack;
    wire                      wb_spi_cyc;
    wire                      wb_spi_stb;
  
    // Access to the display
    wire [WB_SADDR_WIDTH-1:0] wb_display_addr;
    wire [WB_DATA_WIDTH-1:0]  wb_display_rdata;
    wire [WB_DATA_WIDTH-1:0]  wb_display_wdata;
    wire                      wb_display_we;
    wire [WB_SEL_WIDTH-1:0]   wb_display_sel;
    wire                      wb_display_ack;
    wire                      wb_display_cyc;
    wire                      wb_display_stb;
  
    // Peripherals to simplify the mux component
    wire [WB_XADDR_WIDTH-1:0] wb_peripherals_addr;
    wire [WB_DATA_WIDTH-1:0]  wb_peripherals_rdata;
    wire [WB_DATA_WIDTH-1:0]  wb_peripherals_wdata;
    wire                      wb_peripherals_we;
    wire [WB_SEL_WIDTH-1:0]   wb_peripherals_sel;
    wire                      wb_peripherals_ack;
    wire                      wb_peripherals_cyc;
    wire                      wb_peripherals_stb;
    wire                      wb_peripherals_err;
    
    // Instruction Bus wishbone signals (classic)
    wire [WB_ADDR_WIDTH-1:0] wbc_ibus_addr;
    wire [WB_DATA_WIDTH-1:0] wbc_ibus_rdata;
    wire [WB_DATA_WIDTH-1:0] wbc_ibus_wdata;
    wire                     wbc_ibus_we;
    wire [WB_SEL_WIDTH-1:0]  wbc_ibus_sel;
    wire                     wbc_ibus_ack;
    wire                     wbc_ibus_cyc;
    wire                     wbc_ibus_stb;
    wire                     wbc_ibus_err;
    wire [1:0]               wbc_ibus_bte;
    wire [2:0]               wbc_ibus_cti;
    
    // Data Bus wishbone signals (classic)
    wire [WB_ADDR_WIDTH-1:0] wbc_dbus_addr;
    wire [WB_DATA_WIDTH-1:0] wbc_dbus_rdata;
    wire [WB_DATA_WIDTH-1:0] wbc_dbus_wdata;
    wire                     wbc_dbus_we;
    wire [WB_SEL_WIDTH-1:0]  wbc_dbus_sel;
    wire                     wbc_dbus_ack;
    wire                     wbc_dbus_cyc;
    wire                     wbc_dbus_stb;
    wire                     wbc_dbus_err;
    wire [1:0]               wbc_dbus_bte;
    wire [2:0]               wbc_dbus_cti;
  
  
    // Create the Wishbone crossbar.
    wbcxbar#(
      .NM(2), // One port each for instruction and data access from the CPU.
      .AW(WB_ADDR_WIDTH),
      .DW(WB_DATA_WIDTH),
      .MUXWIDTH(4),
      .NS(5), // One port for SRAM, boot ROM and PWM LED driver.
      .SLAVE_MUX({
          { 4'h0 },  // Base address of the boot ROM.                 0x00000000
          { 4'h1 },  // Base address of the SRAM.                     0x10000000
          { 4'h2 },  // Base address of the SPRAM or bulk 32 bit ram  0x20000000
          { 4'h3 },  // Base address of the spi memory                0x30000000
          { 4'h4 }   // Base address of the Peripherals               0x40000000
      })
    ) vexcrossbar (
      .i_clk  ( clk ),
      .i_reset( rst ),
  
      // Crossbar Master Ports.
      .i_mcyc  ({ wbc_ibus_cyc,   wbc_dbus_cyc   }),
      .i_mstb  ({ wbc_ibus_stb,   wbc_dbus_cyc   }),
      .i_mwe   ({ wbc_ibus_we,    wbc_dbus_we    }),
      .i_maddr ({ wbc_ibus_addr,  wbc_dbus_addr  }),
      .i_mdata ({ wbc_ibus_wdata, wbc_dbus_wdata }),
      .i_msel  ({ wbc_ibus_sel,   wbc_dbus_sel   }),
      .o_mack  ({ wbc_ibus_ack,   wbc_dbus_ack   }),
      .o_merr  ({ wbc_ibus_err,   wbc_dbus_err   }),
      .o_mdata ({ wbc_ibus_rdata, wbc_dbus_rdata }),
  
      // Crossbar Slave Ports.
      .o_scyc  ({ wb_bootrom_cyc,   wb_sram_cyc,   wb_spram_cyc,   wb_spi_cyc,   wb_peripherals_cyc   }),
      .o_sstb  ({ wb_bootrom_stb,   wb_sram_stb,   wb_spram_stb,   wb_spi_stb,   wb_peripherals_stb   }),
      .o_swe   ({ wb_bootrom_we,    wb_sram_we,    wb_spram_we,    wb_spi_we,    wb_peripherals_we    }),
      .o_saddr ({ wb_bootrom_addr,  wb_sram_addr,  wb_spram_addr,  wb_spi_addr,  wb_peripherals_addr  }),
      .o_sdata ({ wb_bootrom_wdata, wb_sram_wdata, wb_spram_wdata, wb_spi_wdata, wb_peripherals_wdata }),
      .o_ssel  ({ wb_bootrom_sel,   wb_sram_sel,   wb_spram_sel,   wb_spi_sel,   wb_peripherals_sel   }),
      .i_sack  ({ wb_bootrom_ack,   wb_sram_ack,   wb_spram_ack,   wb_spi_ack,   wb_peripherals_ack   }),
      .i_serr  ({ 1'b0,             1'b0,          1'b0,           1'b0,         wb_peripherals_err   }),
      .i_sdata ({ wb_bootrom_rdata, wb_sram_rdata, wb_spram_rdata, wb_spi_rdata, wb_peripherals_rdata }) 
    );
  
    wbcrouter#(
      .AW( WB_XADDR_WIDTH - 8 ),
      .DW( WB_DATA_WIDTH ),
      .MUXWIDTH(4),
      .NS( 3 ), // Number of slaves
      .SLAVE_MUX({
          { 4'h0 },  // Base address of the misc registers        0x40000000
          { 4'h1 },  // Base address of the USB Serial interface. 0x40010000
          { 4'h2 }   // Base address of the LED Driver interface. 0x40020000
      })
    ) vexrouter (
      .i_clk  ( clk ),
      .i_reset( rst ),
  
      // Crossbar Master Ports.
      .i_mcyc  ( wb_peripherals_cyc   ),
      .i_mstb  ( wb_peripherals_stb   ),
      .i_mwe   ( wb_peripherals_we    ),
      .i_maddr ( wb_peripherals_addr[WB_XADDR_WIDTH-8-1:0] ),
      .i_mdata ( wb_peripherals_wdata ),
      .i_msel  ( wb_peripherals_sel   ),
      .o_mack  ( wb_peripherals_ack   ),
      .o_merr  ( wb_peripherals_err   ),
      .o_mdata ( wb_peripherals_rdata ),
  
      // Crossbar Slave Ports.
      .o_scyc  ({ wb_misc_cyc,   wb_serial_cyc,   wb_display_cyc    }),
      .o_sstb  ({ wb_misc_stb,   wb_serial_stb,   wb_display_stb    }),
      .o_swe   ({ wb_misc_we,    wb_serial_we,    wb_display_we     }),
      .o_saddr ({ wb_misc_addr,  wb_serial_addr,  wb_display_addr   }),
      .o_sdata ({ wb_misc_wdata, wb_serial_wdata, wb_display_wdata  }),
      .o_ssel  ({ wb_misc_sel,   wb_serial_sel,   wb_display_sel    }),
      .i_sack  ({ wb_misc_ack,   wb_serial_ack,   wb_display_ack    }),
      .i_serr  ({ 1'b0,          1'b0,            1'b0              }),
      .i_sdata ({ wb_misc_rdata, wb_serial_rdata, wb_display_rdata  })
    );
    
  
    //---------------------------------------------------------------
    // CPU
    VexRiscv vexcore(
      .externalResetVector(32'h00000000),
      .timerInterrupt(1'b0),
      .softwareInterrupt(1'b0),
      .externalInterruptArray(32'h00000000),
  
      // Instruction Bus.
      .iBusWishbone_CYC(wbc_ibus_cyc),
      .iBusWishbone_STB(wbc_ibus_stb),
      .iBusWishbone_ACK(wbc_ibus_ack),
      .iBusWishbone_WE(wbc_ibus_we),
      .iBusWishbone_ADR(wbc_ibus_addr),
      .iBusWishbone_DAT_MISO(wbc_ibus_rdata),
      .iBusWishbone_DAT_MOSI(wbc_ibus_wdata),
      .iBusWishbone_SEL(wbc_ibus_sel),
      .iBusWishbone_ERR(wbc_ibus_err),
      .iBusWishbone_BTE(wbc_ibus_bte),
      .iBusWishbone_CTI(wbc_ibus_cti), 
  
      // Data Bus.
      .dBusWishbone_CYC(wbc_dbus_cyc),
      .dBusWishbone_STB(wbc_dbus_stb),
      .dBusWishbone_ACK(wbc_dbus_ack),
      .dBusWishbone_WE(wbc_dbus_we),
      .dBusWishbone_ADR(wbc_dbus_addr),
      .dBusWishbone_DAT_MISO(wbc_dbus_rdata),
      .dBusWishbone_DAT_MOSI(wbc_dbus_wdata),
      .dBusWishbone_SEL(wbc_dbus_sel),
      .dBusWishbone_ERR(wbc_dbus_err),
      .dBusWishbone_BTE(wbc_dbus_bte),
      .dBusWishbone_CTI(wbc_dbus_cti),
  
      .clk(clk),
      .reset(rst)
    );
  
  
    
    //---------------------------------------------------------------
    led_matrix #(
      .AW ( WB_SADDR_WIDTH ),
      .DW ( WB_DATA_WIDTH )
    ) led_matrix_inst (
      // Wishbone interface
      .wb_clk_i   ( clk ),
      .wb_reset_i ( rst ),
      .wb_adr_i   ( wb_display_addr  ),
      .wb_dat_i   ( wb_display_wdata ),
      .wb_dat_o   ( wb_display_rdata ),
      .wb_we_i    ( wb_display_we    ),
      .wb_sel_i   ( wb_display_sel   ),
      .wb_ack_o   ( wb_display_ack   ),
      .wb_cyc_i   ( wb_display_cyc   ),
      .wb_stb_i   ( wb_display_stb   ),

      // LED Drive Out
      .latch_row_bank ( latch_row_bank ),
      .row_data       ( row_data       ),
      .row_oe         ( row_oe         ),
      .col_first      ( col_first      ),
      .col_advance    ( col_advance    ),
      .col_rclk       ( col_rclk       ),
  
      .frame_complete ( frame_complete ),
                     
      .debug          ( debug )
    );
  
    
    assign debug = { 0 };
  
  
    //---------------------------------------------------------------
    // spi interface
  
    
    //---------------------------------------------------------------
    // uart and protocol
    
    wire usb_p_tx;
    wire usb_n_tx;
    wire usb_p_rx;
    wire usb_n_rx;
    wire usb_tx_en;
    
    wire dfu_detach;
  
    // USB Serial Core.
    wb_usb_serial#(
      .AW( WB_SADDR_WIDTH ),
      .DW(WB_DATA_WIDTH)
    ) usb_serial(
      .wb_clk_i  (clk),
      .wb_reset_i(rst),
    
      // Wishbone bus.
      .wb_adr_i  (wb_serial_addr),
      .wb_dat_i  (wb_serial_wdata),
      .wb_dat_o  (wb_serial_rdata),
      .wb_we_i   (wb_serial_we),
      .wb_sel_i  (wb_serial_sel),
      .wb_ack_o  (wb_serial_ack),
      .wb_cyc_i  (wb_serial_cyc),
      .wb_stb_i  (wb_serial_stb),
    
      // USB lines.
      .usb_clk   (clk_48mhz),
      .usb_p_tx  (usb_p_tx),
      .usb_n_tx  (usb_n_tx),
      .usb_p_rx  (usb_p_rx),
      .usb_n_rx  (usb_n_rx),
      .usb_tx_en (usb_tx_en),
      
      // DFU state and debug
      .dfu_detach(dfu_detach),
      .debug()
    );
    usb_phy_ice40 usb_phy(
      .pin_usb_p (pin_usbp),
      .pin_usb_n (pin_usbn),
    
      .usb_p_tx  (usb_p_tx),
      .usb_n_tx  (usb_n_tx),
      .usb_p_rx  (usb_p_rx),
      .usb_n_rx  (usb_n_rx),
      .usb_tx_en (usb_tx_en)
    );
    assign pin_pu = 1'b1;
  
  
    //---------------------------------------------------------------
    // wishbone connected LED PWM driver
    wire [1:0] buttons;
    wire [11:0] audio;

    assign buttons = { pin_button_up, pin_button_down };
    
    wb_misc #(
      .AW( WB_SADDR_WIDTH ),
      .DW(WB_DATA_WIDTH)
    ) wb_misc_inst (
      .wb_clk_i   ( clk ),
      .wb_reset_i ( rst ),
      .wb_adr_i   ( wb_misc_addr ),
      .wb_dat_i   ( wb_misc_wdata ),
      .wb_dat_o   ( wb_misc_rdata ),
      .wb_we_i    ( wb_misc_we ),
      .wb_sel_i   ( wb_misc_sel ),
      .wb_ack_o   ( wb_misc_ack ),
      .wb_cyc_i   ( wb_misc_cyc ),
      .wb_stb_i   ( wb_misc_stb ),
  
      .leds       ( { stat_b, stat_g, stat_r } ),
      .buttons    ( buttons ),
      .audio      ( audio )
    );
  
    //---------------------------------------------------------------
    // Boot ROM
    bootrom#(
      .AW(WB_XADDR_WIDTH),
      .DW(WB_DATA_WIDTH)
    ) vexbootrom(
      .wb_clk_i  (clk),
      .wb_reset_i(rst),
      .wb_adr_i(wb_bootrom_addr),
      .wb_dat_i(wb_bootrom_wdata),
      .wb_dat_o(wb_bootrom_rdata),
      .wb_we_i(wb_bootrom_we),
      .wb_sel_i(wb_bootrom_sel),
      .wb_ack_o(wb_bootrom_ack),
      .wb_cyc_i(wb_bootrom_cyc),
      .wb_stb_i(wb_bootrom_stb)
    );
  
    //---------------------------------------------------------------
    // SRAM
    wbsram#(
      .AW(WB_XADDR_WIDTH),
      .DW(WB_DATA_WIDTH)
    ) vexsram(
      .wb_clk_i  ( clk ),
      .wb_reset_i( rst ),
      .wb_adr_i  ( wb_sram_addr  ),
      .wb_dat_i  ( wb_sram_wdata ),
      .wb_dat_o  ( wb_sram_rdata ),
      .wb_we_i   ( wb_sram_we    ),
      .wb_sel_i  ( wb_sram_sel   ),
      .wb_ack_o  ( wb_sram_ack   ),
      .wb_cyc_i  ( wb_sram_cyc   ),
      .wb_stb_i  ( wb_sram_stb   )
    );
  
    //---------------------------------------------------------------
    // SPRAM
    wbspram #(
      .AW ( WB_XADDR_WIDTH ),
      .DW ( WB_DATA_WIDTH )
    ) spram_inst (
      // Wishbone interface.
      .wb_clk_i   ( clk ),
      .wb_reset_i ( rst ),
      .wb_adr_i   ( wb_spram_addr  ),
      .wb_dat_i   ( wb_spram_wdata ),
      .wb_dat_o   ( wb_spram_rdata ),
      .wb_we_i    ( wb_spram_we    ),
      .wb_sel_i   ( wb_spram_sel   ),
      .wb_ack_o   ( wb_spram_ack   ),
      .wb_cyc_i   ( wb_spram_cyc   ),
      .wb_stb_i   ( wb_spram_stb   )
    );
  
    //---------------------------------------------------------------
    // qspi
    wire                     spi_clk;
    wire                     spi_sel;
    wire [3:0]               spi_d_out;
    wire [3:0]               spi_d_in;
    wire [3:0]               spi_d_dir;
  
    wb_qspi_flash #(
      .AW( WB_XADDR_WIDTH ),
      .DW( WB_DATA_WIDTH )
    ) wb_qspi_flash_inst (
      .wb_clk_i   ( clk ),
      .wb_reset_i ( rst ),
    
      // Wishbone interface
      .wb_adr_i ( wb_spi_addr  ),
      .wb_dat_i ( wb_spi_wdata ),
      .wb_dat_o ( wb_spi_rdata ),
      .wb_we_i  ( wb_spi_we    ),
      .wb_sel_i ( wb_spi_sel   ),
      .wb_stb_i ( wb_spi_stb   ),
      .wb_cyc_i ( wb_spi_cyc   ),
      .wb_ack_o ( wb_spi_ack   ),
    
      // (Q)SPI interface
      .spi_clk   ( spi_clk   ),
      .spi_sel   ( spi_sel   ),
      .spi_d_out ( spi_d_out ),
      .spi_d_in  ( spi_d_in  ),
      .spi_d_dir ( spi_d_dir )
    );
  
    
    assign pin_sck = spi_clk;
    assign pin_cs  = spi_sel;
    
    SB_IO #(
      .PIN_TYPE( 6'b1010_01 ), // PIN_OUTPUT_TRISTATE - PIN_INPUT
      .PULLUP  ( 1'b0       )
    ) iobuf_d0 (
      .PACKAGE_PIN   ( pin_mosi     ),
      .OUTPUT_ENABLE ( spi_d_dir[0] ),
      .D_OUT_0       ( spi_d_out[0] ),
      .D_IN_0        ( spi_d_in[0]  )
    );
    SB_IO #(
      .PIN_TYPE( 6'b1010_01 ), // PIN_OUTPUT_TRISTATE - PIN_INPUT
      .PULLUP  ( 1'b0       )
    ) iobuf_d1 (
      .PACKAGE_PIN   ( pin_miso     ),
      .OUTPUT_ENABLE ( spi_d_dir[1] ),
      .D_OUT_0       ( spi_d_out[1] ),
      .D_IN_0        ( spi_d_in[1]  )
    );
    SB_IO #(
      .PIN_TYPE( 6'b1010_01 ), // PIN_OUTPUT_TRISTATE - PIN_INPUT
      .PULLUP  ( 1'b1       )
    ) iobuf_d2 (
      .PACKAGE_PIN   ( pin_wp       ),
      .OUTPUT_ENABLE ( spi_d_dir[2] ),
      .D_OUT_0       ( spi_d_out[2] ),
      .D_IN_0        ( spi_d_in[2]  )
    );
    SB_IO #(
      .PIN_TYPE( 6'b1010_01 ), // PIN_OUTPUT_TRISTATE - PIN_INPUT
      .PULLUP  ( 1'b1       )
    ) iobuf_d3 (
      .PACKAGE_PIN   ( pin_hold     ),
      .OUTPUT_ENABLE ( spi_d_dir[3] ),
      .D_OUT_0       ( spi_d_out[3] ),
      .D_IN_0        ( spi_d_in[3]  )
    );
    
    
  
    //---------------------------------------------------------------
    // Audio
  
    pdm_mic #(
      .SAMPLE_DEPTH      ( 12 ),
      .FIR_SAMPLE_LENGTH ( 8192 ),
      .INPUT_FREQUENCY   ( CLK_FREQ ),
      .FREQUENCY         (  2000000 )
    ) mic_inst (
      .clk ( clk ),
      .rst ( rst ),
    
      .mic_clk  ( pin_mic_clk ),
      .mic_data ( pin_mic_data ),
    
      .audio1 ( audio )
    );

                     
    
  
    // Image Slot 0: Multiboot header and POR springboard.
    // Image Slot 1: DFU Bootloader
    // Image Slot 2: This Image (User Application).
    SB_WARMBOOT warmboot_inst (
      .S1(1'b0),
      .S0(1'b1),
      .BOOT(dfu_detach)
    );
  


  
endmodule
