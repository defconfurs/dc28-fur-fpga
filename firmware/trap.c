#include <stdint.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>
#include <machine/syscall.h>

#include "badge.h"

extern void bootexit(int code);
extern void _putchar(int ch);
extern void _entry(void);

void
rv_irq_software(int32_t *regs, uint32_t cause)
{
    bios_printf("Unexpected software interrupt cause=0x%08x\n", cause);
}

void
rv_irq_timer(int32_t *regs, uint32_t cause)
{
    bios_printf("Unexpected timer interrupt\n", cause);
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

/* Local error number, used by syscalls. */
static int32_t rv_errno;

static int
rv_write(int fd, const void *buf, size_t count)
{
    /* You can write to stdin */
    if (fd == STDIN_FILENO) {
        return 0;
    }
    /* Handle writes to stdout/stderr */
    if ((fd == STDOUT_FILENO) || (fd == STDERR_FILENO)) {
        const uint8_t *data = buf;
        const uint8_t *end = data + count;
        while (data < end) {
            _putchar(*data++);
        }
        return data - (const uint8_t *)buf;
    }
    /* No other file descriptors supported */
    rv_errno = EBADF;
    return -1;
}

static int
rv_fstat(int32_t *regs, int fd, struct stat *st)
{
    /* The only open file descriptors should be stdin/stdout/stderr */
    if (fd > STDERR_FILENO) {
        rv_errno = EBADF;
        return -1;
    }
    memset(st, 0, sizeof(struct stat));
    st->st_ino = fd;
    st->st_mode = S_IFCHR | (S_IRUSR | S_IRGRP | S_IROTH) | ( S_IWUSR | S_IWGRP | S_IWOTH);
    return 0;
}

void
rv_ecall(uint32_t syscall, int32_t *regs, uint32_t excpc)
{
    rv_errno = 0;
    switch (syscall) {
        case SYS_exit:
            regs[0] = 1;
            asm volatile ("csrw mepc, %0" :: "r"(&bootexit));
            break;
        
        case SYS_write:
            regs[0] = rv_write(regs[0], (void *)(uintptr_t)regs[1], regs[2]);
            break;
        
        case SYS_fstat:
            regs[0] = rv_fstat(regs, regs[0], (void *)regs[1]);
            break;
        
        default:
            bios_printf("Caught ecall=0x%08x at pc=0x%08x\n", regs[7], excpc);
            bios_printf("\t0x%08x 0x%08x 0x%08x 0x%08x\n", regs[0], regs[1], regs[2], regs[3]);
            bios_printf("\t0x%08x 0x%08x 0x%08x 0x%08x\n", regs[4], regs[5], regs[6], regs[7]);

            /* Abort the animation */
            regs[0] = 1;
            asm volatile ("csrw mepc, %0\n" :: "r"(&bootexit));
            break;
    }
    regs[1] = rv_errno;
}

void
rv_exception(int32_t *regs, uint32_t cause, uint32_t excpc)
{
    /* Handle ecall instruction (via undefined instruction handler) */
    register unsigned int cycles;
    asm volatile("csrr %0, mcycle\n" : "=r"(cycles));
    bios_printf("Caught Trap 0x%08x at pc=0x%08x t=%d!\n", cause, excpc, cycles);

    /* This exception is fatal, go back to the entry point. */
    asm volatile ("csrw mepc, %0\n" :: "r"(&_entry));
}
