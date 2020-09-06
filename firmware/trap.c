#include <stdint.h>
#include <printf.h>

#include "badge.h"

extern void bootexit(int code);
extern void _entry(void);

/*
 * On button press, we want to exit the currently running program, and return back
 * to the BIOS to switch animations. We do this by overwriting the return address
 * in the mepc CSR register with bootexit() function.
 */
static void
button_irq(int32_t *regs)
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

void trap(int32_t *regs)
{
    register unsigned int cycles;
    register unsigned int cause;
    asm volatile("csrr %0, mcycle\n" : "=r"(cycles));
    asm volatile("csrr %0, mcause\n" : "=r"(cause));
    if (cause == 0x8000000B) {
        /* External interupt handlers. */
        button_irq(regs);
    }
    else {
        /* Exception handlers go here */
        register unsigned int excpc;
        asm volatile("csrr %0, mepc\n" : "=r"(excpc));
        printf("Caught Trap 0x%08x at pc=0x%08x t=%d!\n", cause, excpc, cycles);

        /* Do not return, go back to the firmware entry point */
        asm volatile ("csrw mepc, %0\n" :: "r"(&_entry));
    }
}
