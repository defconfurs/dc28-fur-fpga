/*
  usb_phy_ice40

  USB PHY for the Lattice iCE40 family.

  ----------------------------------------------------
  usb_phy_ice40 u_u (
    .clk        (clk),
    .reset      (reset),

    // USB pins
    .pin_usb_p( pin_usb_p ),
    .pin_usb_n( pin_usb_n ),

    // USB signals
    input  usb_p_tx,
    input  usb_n_tx,
    output usb_p_rx,
    output usb_n_rx,
    input  usb_tx_en,
  );
*/
module usb_phy_ice40 (
  input  clk,
  output reset,

  // USB pins
  inout  pin_usb_p,
  inout  pin_usb_n,

  // USB signals
  input  usb_p_tx,
  input  usb_n_tx,
  output usb_p_rx,
  output usb_n_rx,
  input  usb_tx_en,
);

    wire usb_p_in;
    wire usb_n_in;

    assign usb_p_rx = usb_tx_en ? 1'b1 : usb_p_in;
    assign usb_n_rx = usb_tx_en ? 1'b0 : usb_n_in;

    SB_IO #(
        .PIN_TYPE(6'b 1010_01), // PIN_OUTPUT_TRISTATE - PIN_INPUT
        .PULLUP(1'b 0)
    ) iobuf_usbp (
        .PACKAGE_PIN(pin_usb_p),
        .OUTPUT_ENABLE(usb_tx_en),
        .D_OUT_0(usb_p_tx),
        .D_IN_0(usb_p_in)
    );

    SB_IO #(
        .PIN_TYPE(6'b 1010_01), // PIN_OUTPUT_TRISTATE - PIN_INPUT
        .PULLUP(1'b 0)
    ) iobuf_usbn (
        .PACKAGE_PIN(pin_usb_n),
        .OUTPUT_ENABLE(usb_tx_en),
        .D_OUT_0(usb_n_tx),
        .D_IN_0(usb_n_in)
    );

    usb_reset_det rst_detector(
        .clk(clk),
        .reset(reset),
        .usb_p_rx(usb_p_in),
        .usb_n_rx(usb_n_in),
    );
endmodule
