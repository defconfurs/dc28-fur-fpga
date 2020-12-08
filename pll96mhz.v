/**
 * PLL configuration
 *
 * This Verilog module was generated automatically
 * using the icepll tool from the IceStorm project.
 * Use at your own risk.
 *
 * Given input frequency:        12.000 MHz
 * Requested output frequency:   96.000 MHz
 * Achieved output frequency:    96.000 MHz
 */

module pll96mhz(
    input refclk,
    output clk_output,
    output clk_locked
);

SB_PLL40_CORE #(
    .FEEDBACK_PATH("SIMPLE"),
    .DIVR(4'b0000),        // DIVR =  0
    .DIVF(7'b1011111),     // DIVF = 63
    .DIVQ(3'b011),         // DIVQ =  3
    .FILTER_RANGE(3'b001)  // FILTER_RANGE = 1
) usb_pll_inst (
    .LOCK(clk_locked),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .REFERENCECLK(refclk),
    .PLLOUTCORE(clk_output)
);
endmodule
