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

// First stage boot header - just check the button status on coldboot
// and either jump to user image 1 for the DFU bootloader, to user
// image 2 for the application.
module firstboot (
    input wire  pin_clk,
    input wire  pin_button_up
);


// Delay the boot selection to give the user time to press the button.
reg [7:0] rst_delay = 8'hFF;
always @(posedge pin_clk) begin
    if (rst_delay) rst_delay <= rst_delay - 1;
end

// Image Slot 0: This image.
// Image Slot 1: DFU Bootloader.
// Image Slot 2: User Application.
SB_WARMBOOT warmboot_inst (
    .S1( pin_button_up),
    .S0(~pin_button_up),
    .BOOT(rst_delay == 0)
);

endmodule
