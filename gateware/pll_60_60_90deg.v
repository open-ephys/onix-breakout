/**
 * PLL configuration
 *
 * This Verilog module was generated automatically
 * using the icepll tool from the IceStorm project.
 * Use at your own risk.
 *
 * Given input frequency:        60.000 MHz
 * Requested output frequency:   60.000 MHz
 * Achieved output frequency:    60.000 MHz
 */

module pll_60_60_90deg(
    input  clock_in,
    output clock_out,
    output locked
    );

SB_PLL40_CORE # (
    .FEEDBACK_PATH("PHASE_AND_DELAY"),
    .PLLOUT_SELECT("SHIFTREG_90deg"),
    .DIVR(4'b0000),     // DIVR =  0
    .DIVF(7'b0000000),  // DIVF =  0
    .DIVQ(3'b100),      // DIVQ =  4
    .FILTER_RANGE(3'b100)   // FILTER_RANGE = 4
) pll (
    .LOCK(locked),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .REFERENCECLK(clock_in),
    .PLLOUTCORE(clock_out)
);

endmodule
