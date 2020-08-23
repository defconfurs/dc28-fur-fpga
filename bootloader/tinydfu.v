/*
 *  TinyDFU Bootloader for the DC28 Furry Badge
 */
module tinydfu (
    input wire  pin_clk,

    inout wire  pin_usbp,
    inout wire  pin_usbn,
    output wire pin_pu,

    inout wire  pin_miso,
    inout wire  pin_mosi,
    output wire pin_cs,
    output wire pin_sck
);

/////////////////////////////
// Clock and Reset Generation
/////////////////////////////
wire clk_48mhz;
wire clk = clkdiv[1];
reg [1:0] clkdiv = 0;

// Use an icepll generated pll
wire clk_locked;
pll48mhz pll( .refclk(pin_clk), .clk_48mhz(clk_48mhz), .clk_locked(clk_locked) );
always @(posedge clk_48mhz) clkdiv <= clkdiv + 1;

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
    .S1(1'b1),
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
