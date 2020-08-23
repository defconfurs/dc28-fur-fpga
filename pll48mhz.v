module pll48mhz(
    input refclk,
    output clk_48mhz,
    output clk_locked
);

SB_PLL40_CORE #(
    .DIVR(4'd0),
    .DIVF(7'd63), // was 47 - 7'b0101111 = 0x2F (31 for first prototype)
    .DIVQ(3'd4),
    .FILTER_RANGE(3'd1),
    .FEEDBACK_PATH("SIMPLE"),
    .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
    .FDA_FEEDBACK(4'd0),
    .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
    .FDA_RELATIVE(4'd0),
    .SHIFTREG_DIV_MODE(2'd0),
    .PLLOUT_SELECT("GENCLK"),
    .ENABLE_ICEGATE(1'b0)
) usb_pll_inst (
    .REFERENCECLK(refclk),
    .PLLOUTCORE(clk_48mhz),
    .PLLOUTGLOBAL(),
    .EXTFEEDBACK(),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .LATCHINPUTVALUE(),
    .LOCK(clk_locked),
    .SDI(),
    .SDO(),
    .SCLK()
);
endmodule
