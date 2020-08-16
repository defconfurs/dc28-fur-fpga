/*
  usb_phy_ecp5

  USB PHY for the Lattice ECP5 family.

  ----------------------------------------------------
  usb_phy_ecp5 u_u (
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
module usb_phy_ecp5 (
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

  // T = TRISTATE (not transmit)
  BB io_p( .I( usb_p_tx ), .T( !usb_tx_en ), .O( usb_p_in ), .B( pin_usb_p ) );
  BB io_n( .I( usb_n_tx ), .T( !usb_tx_en ), .O( usb_n_in ), .B( pin_usb_n ) );

  usb_reset_det rst_detector(
    .clk(clk),
    .reset(reset),
    .usb_p_rx(usb_p_in),
    .usb_n_rx(usb_n_in),
  );

endmodule
