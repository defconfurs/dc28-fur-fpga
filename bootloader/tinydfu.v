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
module tinydfu (
    input wire  pin_clk,

    inout wire  pin_usbp,
    inout wire  pin_usbn,
    output wire pin_pu,

    inout wire  pin_miso,
    inout wire  pin_mosi,
    output wire pin_cs,
    output wire pin_sck,

    output wire pin_stat_r,
    output wire pin_stat_g,
    output wire pin_stat_b
);


wire          stat_r;
wire          stat_g;
wire          stat_b;
wire          stat_en;

SB_RGBA_DRV #(
  .CURRENT_MODE ( "0b1"        ), // half current mode
  .RGB0_CURRENT ( "0b00000001" ),
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

assign stat_r = 1;
assign stat_g = 0;
assign stat_b = 1;
assign stat_en = 1;
  
/////////////////////////////
// Clock and Reset Generation
/////////////////////////////
wire clk_96mhz;
wire clk_48mhz = clkdiv[0];
wire clk = clkdiv[2];
reg [2:0] clkdiv = 0;

// Use an icepll generated pll
wire clk_locked;
pll96mhz pll( .refclk(pin_clk), .clk_output(clk_96mhz), .clk_locked(clk_locked) );
always @(posedge clk_96mhz) clkdiv <= clkdiv + 1;

wire rst;
reg [7:0] rst_delay = 8'hFF;
always @(posedge pin_clk) begin
    if (clk_locked && (rst_delay != 0)) rst_delay <= rst_delay - 1;
end
assign rst = (rst_delay != 0);

// Image Slot 0: Multiboot header and POR springboard.
// Image Slot 1: This Image (DFU Bootloader).
// Image Slot 2: User Application.
wire dfu_detach;
wire [7:0] dfu_state;
SB_WARMBOOT warmboot_inst (
    .S1(1'b0),
    .S0(1'b0),
    .BOOT(!rst && dfu_detach)
);

/////////////////////////////
// USB DFU Device
/////////////////////////////
wire usb_p_tx;
wire usb_n_tx;
wire usb_p_rx;
wire usb_n_rx;
wire usb_tx_en;

// USB DFU - this instanciates the entire USB device.
usb_dfu_core dfu (
    .clk_48mhz  (clk_48mhz),
    .clk        (clk),
    .reset      (rst),

    // USB signals
    .usb_p_tx( usb_p_tx ),
    .usb_n_tx( usb_n_tx ),
    .usb_p_rx( usb_p_rx ),
    .usb_n_rx( usb_n_rx ),
    .usb_tx_en( usb_tx_en ),

    // SPI
    .spi_csel( pin_cs ),
    .spi_clk( pin_sck ),
    .spi_mosi( pin_mosi ),
    .spi_miso( pin_miso ),  

    .dfu_detach( dfu_detach ),
    .dfu_state( dfu_state )
);

// USB Physical interface
usb_phy_ice40 phy (
    .pin_usb_p (pin_usbp),
    .pin_usb_n (pin_usbn),

    .usb_p_tx( usb_p_tx ),
    .usb_n_tx( usb_n_tx ),
    .usb_p_rx( usb_p_rx ),
    .usb_n_rx( usb_n_rx ),
    .usb_tx_en( usb_tx_en ),
);

// USB Host Detect Pull Up
assign pin_pu = 1'b1;

endmodule
