# Global symbols from the linker file.
.global _etext
.global _sidata
.global _sdata
.global _edata
.global _sbss
.global _ebss
.global _heap_start
.global _stack_start
.global main
.global start
.global bootload
.global printf_
.global vprintf_

.section .entry

# Boot entry point is at address zero.
.globl _entry
.type _entry,@function
_entry:
    la x2, _stack_start
    j setup_crt

# BIOS function vtable is at address 0x10.
.balign 16
.globl _bios_vtable
.type _bios_vtable,@object
_bios_vtable:
    .word bootload
    .word printf_
    .word vprintf_

.balign 16
setup_crt:
    # initialize the register file
    addi x1, zero, 0
    addi x3, zero, 0
    addi x4, zero, 0
    addi x5, zero, 0
    addi x6, zero, 0
    addi x7, zero, 0
    addi x8, zero, 0
    addi x9, zero, 0
    addi x10, zero, 0
    addi x11, zero, 0
    addi x12, zero, 0
    addi x13, zero, 0
    addi x14, zero, 0
    addi x15, zero, 0
    addi x16, zero, 0
    addi x17, zero, 0
    addi x18, zero, 0
    addi x19, zero, 0
    addi x20, zero, 0
    addi x21, zero, 0
    addi x22, zero, 0
    addi x23, zero, 0
    addi x24, zero, 0
    addi x25, zero, 0
    addi x26, zero, 0
    addi x27, zero, 0
    addi x28, zero, 0
    addi x29, zero, 0
    addi x30, zero, 0
    addi x31, zero, 0

    # Copy data from _sreldata to _sdata.
    la a0, _sreldata
    la a1, _sdata
    la a2, _edata
    beq a1, a2, sreldata_skip
sreldata_loop:
    lw a3, 0(a0)
    sw a3, 0(a1)
    addi a0,a0,4
    addi a1,a1,4
    bne a1, a2, sreldata_loop
sreldata_skip:

    # Zero-fill the .bss section.
    la a0, _sbss
    la a1, _ebss
    beq a0, a1, bss_zfill_skip
bss_zfill_loop:
    sw x0, 0(a0)
    addi a0,a0,4
    bne a0, a1, bss_zfill_loop
bss_zfill_skip:

    # C-Runtime is ready. Jump to main().
    j main
