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
.global bootexit
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
    .word bootexit
    .word bios_printf
    .word bios_vprintf

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

    # Set the trap/interrupt handler.
    la x29, __trap_entry
    csrw mtvec, x29
    # Enable external interrupts.
    li x29, 0x800		# 0x800 External Interrupts
    csrw mie,x29
    li x29, 0x008		# 0x008 Enable Interrupts
    csrw mstatus,x29
    # CSR_INT_MASK		# VexRiscV interupt mask.
    li x29, 0x1
    csrw 0xBC0, x29
    
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

.align 4
__trap_entry:
    # Stack up the arugment registers fist, and check for ecall.
    addi sp, sp, -128
    sw x10,   10*4(sp)
    sw x11,   11*4(sp)
    sw x12,   12*4(sp)
    sw x13,   13*4(sp)
    sw x14,   14*4(sp)
    sw x15,   15*4(sp)
    sw x16,   16*4(sp)
    sw x17,   17*4(sp)

    # Pass the cause and PC as the second and third arguments.
    csrr a1, mcause
    csrr a2, mepc

    # Check if we faulted on an ecall instruction.
    li a0, 0x02         # Check for mcause == 0x02 (illegal instruction)
    bne a0, a1, __trap_not_ecall
    lh a3, 0(a2)        # Load low half of the instruction (possible misalignment)
    lh a4, 2(a2)        # Load high half of the instruction (possible misalignment)
    li a0, 0x73         # Check for instruction == 0x7C (ecall)
    bnez a4, __trap_not_ecall
    bne a0, a3, __trap_not_ecall

    # Handle the ecall instruction.
    addi a0, a2, 4  # Return passed the faulting instruction.
    csrw mepc, a0
    addi a0, a7, 0  # Pass the syscall number as the first argument.
    addi a1, sp, 40 # Pass the stacked argument registers as the second argument.
    la x1, __trap_return_ecall
    j rv_ecall

__trap_not_ecall:
    # Stack up the remaining registers.
    sw x1,   1*4(sp)
    sw x3,   3*4(sp)
    sw x4,   4*4(sp)
    sw x5,   5*4(sp)
    sw x6,   6*4(sp)
    sw x7,   7*4(sp)
    sw x8,   8*4(sp)
    sw x9,   9*4(sp)
    sw x18,  18*4(sp)
    sw x19,  19*4(sp)
    sw x20,  20*4(sp)
    sw x21,  21*4(sp)
    sw x22,  22*4(sp)
    sw x23,  23*4(sp)
    sw x24,  24*4(sp)
    sw x25,  25*4(sp)
    sw x26,  26*4(sp)
    sw x27,  27*4(sp)
    sw x28,  28*4(sp)
    sw x29,  29*4(sp)
    sw x30,  30*4(sp)
    sw x31,  31*4(sp)

    # Passed the stacked registers to the handler.
    # and return to __trap_return when done.
    add a0, zero, sp
    la x1, __trap_return
    
    # Call the exception handler.
    blt a1, zero, __trap_irq_launch
    j rv_exception

__trap_irq_launch:
    la s0, __trap_irq_vector
    andi s1, a1, 0xC
    add s0, s0, s1
    lw s0, 0(s0)
    jr s0

.type __trap_irq_vector,@object
.align 4
__trap_irq_vector:
    .word rv_irq_software
    .word rv_irq_timer
    .word rv_irq_extint

__trap_return:
    # Restore the stacked registers.
    lw x1,   1*4(sp)
    lw x3,   3*4(sp)
    lw x4,   4*4(sp)
    lw x5,   5*4(sp)
    lw x6,   6*4(sp)
    lw x7,   7*4(sp)
    lw x8,   8*4(sp)
    lw x9,   9*4(sp)
    lw x18,   18*4(sp)
    lw x19,   19*4(sp)
    lw x20,   20*4(sp)
    lw x21,   21*4(sp)
    lw x22,   22*4(sp)
    lw x23,   23*4(sp)
    lw x24,   24*4(sp)
    lw x25,   25*4(sp)
    lw x26,   26*4(sp)
    lw x27,   27*4(sp)
    lw x28,   28*4(sp)
    lw x29,   29*4(sp)
    lw x30,   30*4(sp)
    lw x31,   31*4(sp)
__trap_return_ecall:
    lw x10,   10*4(sp)
    lw x11,   11*4(sp)
    lw x12,   12*4(sp)
    lw x13,   13*4(sp)
    lw x14,   14*4(sp)
    lw x15,   15*4(sp)
    lw x16,   16*4(sp)
    lw x17,   17*4(sp)
    addi sp, sp, 128
    mret
