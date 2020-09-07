#include <stdint.h>
#include <printf.h>
#include <errno.h>

#include "badge.h"

extern void bootexit(int code);
extern void _entry(void);

void
rv_irq_software(int32_t *regs, uint32_t cause)
{
    printf("Unexpected software interrupt cause=0x%08x\n", cause);
}

void
rv_irq_timer(int32_t *regs, uint32_t cause)
{
    printf("Unexpected timer interrupt\n", cause);
}

/*
 * On button press, we want to exit the currently running program, and return back
 * to the BIOS to switch animations. We do this by overwriting the return address
 * in the mepc CSR register with bootexit() function.
 */
void
rv_irq_extint(int32_t *regs)
{
    uint8_t status = MISC->i_status;
    /* Exit the animation, and seek forwards on left button. */
    if (status & 0x08) {
        regs[10] = 1; /* set exit code */
        asm volatile ("csrw mepc, %0\n" :: "r"(&bootexit));
    }
    /* Exit the animation, and seek backwards on right button. */
    if (status & 0x04) {
        regs[10] = 2; /* set exit code */
        asm volatile ("csrw mepc, %0\n" :: "r"(&bootexit));
    }

    /* Clear button interrupt events. */
    MISC->i_status = 0xF;
}

void
rv_ecall(int32_t *regs, uint32_t excpc)
{
    printf("Unsupported ecall=0x%08x at pc=0x%08x\n", regs[7], excpc);
    printf("\t0x%08x 0x%08x 0x%08x 0x%08x\n", regs[0], regs[1], regs[2], regs[3]);
    printf("\t0x%08x 0x%08x 0x%08x 0x%08x\n", regs[4], regs[5], regs[6], regs[7]);

    /* Abort the animation. */
    regs[10] = 1;
    asm volatile ("csrw mepc, %0\n" :: "r"(&bootexit));
}

void
rv_exception(int32_t *regs, uint32_t cause, uint32_t excpc)
{
    /* Handle ecall instruction (via undefined instruction handler) */
    register unsigned int cycles;
    asm volatile("csrr %0, mcycle\n" : "=r"(cycles));
    printf("Caught Trap 0x%08x at pc=0x%08x t=%d!\n", cause, excpc, cycles);

    /* This exception is fatal, go back to the entry point. */
    asm volatile ("csrw mepc, %0\n" :: "r"(&_entry));
}
