#======================================
# Initial Boot Memory
#======================================
#
# This routine is an initial bootloader used by
# the CPU to fetch the BIOS and runtime code from
# QSPI flash. If no valid image is found, then
# it will jump to die() and flash the display
# red to indicate failure.
#
.section .text

.globl coldboot
.func coldboot
coldboot:
    la s0, (_stack_start - 64)  # SRAM location of memcpy.
    la s1, 0x30100000           # Flash location of the boot header.

    # Check if the BIOS boot header is valid.
    lw a1, 0(s1)
    la a0, 0xdeadbeef
    bne a0, a1, die

    # Relocate the memcpy function into SRAM
    addi a0, s0, 0      # SRAM location for the copy.
    la   a1, memcpy     # .text location of memcpy.
    li   a2, 64         # rough size of the memcpy routine.
    jalr a1             # Call memcpy to relocate itself.

    # Prepare arguments to memcpy to relocate the .text segment.
    addi a0, zero, 0    # copy into start of ROM (address zero)
    lw   a1, 16(s1)     # get the offset of the .text segment to relocate.
    add  a1, a1, s1     # get the address of the .text segment to relocate.
    lw   a2, 12(s1)     # get the length of data to relocate.

    # Call the SRAM version of memcpy, and return into warm boot entry point. 
    lw   ra, 8(s1)      # Set return address to warm boot entry.
    jr   s0             # call the SRAM location of memcpy.
.endfunc

# We could not load the BIOS image. Time to die.
.globl die
.func die
die:
    # Setup the display pointer.
    la a0, 0x40020004
    sw a0, -4(a0)

    # Pick a fill color (red, for badness).
    li s1, 0xF800
    li a1, 0
0:  # The dislay loop
    jal  display_fill   # Fill the display.
    li   s0, 0x200000   # Reset the delay counter.
    xor  a1, a1, s1     # Toggle the color.
1:  # The delay loop
    beqz s0, 0b         # Redraw if the counter reaches zero.
    addi s0, s0, -1     # Decrement the counter otherwise.
    beqz zero, 1b
.endfunc

.globl display_fill
.func
display_fill:
    slli a2, a1, 16
    add  a2, a2, a1
    addi a3, a0, (32*14*2)
0:
    addi a3, a3, -4
    sw   a2, 0(a3)
    bgt  a3, a0, 0b
    ret
.endfunc

# A minimal memcpy - only accepts aligned pointers.
.globl memcpy
.func
memcpy:
    beqz a2, 1f     # exit immediately if the count is zero.
    add  a3, a1, a2 # a3 holds the source end pointer.
0:                  # Start of the memcpy loop.
    lw   a4, 0(a1)  # load a word from source.
    addi a1, a1, 4
    sw   a4, 0(a0)  # store a word to dest.
    addi a0, a0, 4
    blt  a1, a3, 0b # continue as long as source < end.
    sub  a0, a0, a2 # restore the dest pointer before returning.
1:
    ret
.endfunc
