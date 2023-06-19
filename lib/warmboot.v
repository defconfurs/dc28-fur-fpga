module warmboot (
        input wire [1:0] i_mode,       // 0: multiboot header and POR springboard, 1: DFU Bootloader, 2: This image
        input wire       i_dfu_detatch
    );

    // Image Slot 0: Multiboot header and POR springboard.
    // Image Slot 1: DFU Bootloader
    // Image Slot 2: This Image (User Application).
    SB_WARMBOOT warmboot_inst (
        .S0(i_mode[0]),
        .S1(i_mode[1]),
        .BOOT(dfu_detach)
    );

endmodule
