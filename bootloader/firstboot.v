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
