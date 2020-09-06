#include <stdint.h>
#include <string.h>
#include <printf.h>
#include <string.h>
#include <setjmp.h>

#include "badge.h"

void _putchar(char ch)
{
    /* Cook line endings to play nicely with terminals. */
    static char prev = '\0';
    if ((ch == '\n') && (prev != '\r')) _putchar('\r');
    prev = ch;

    /* Output the character */
    while ((SERIAL->isr & 0x02) == 0) { /* nop */}
    SERIAL->thr = ch;
}

/* Use setjmp/longjmp when returning from an animation. */
static jmp_buf bootjmp;

static const struct boot_header *
bootaddr(int slot)
{
    const uintptr_t bootsz = 64 * 1024;
    uintptr_t userdata = 0x30000000 + (1024 * 1024);    /* User data starts 1MB into flash. */
    uintptr_t animation = userdata + (slot * bootsz);   /* Animations are spaced 64kB apart. */
    return (const struct boot_header *)animation;
}

void bootexit(int code)
{
    longjmp(bootjmp, code);
}

void bootload(int slot)
{
    const uintptr_t bootsz = 64 * 1024;
    uintptr_t prog_target = 0x20000000;
    uintptr_t frame_target = 0x40020000;
    const struct boot_header *hdr = bootaddr(slot);

    /* For the animation to be valid - the tag must match, and the entry point should be sane */
    if (hdr->tag != BOOT_HDR_TAG) {
        printf("Bad animation found at slot %d\n", slot);
        printf("\ttag = 0x%08x, start=%d, size = %d\n", hdr->tag, hdr->data_start, hdr->data_size);
        bootexit(1);
    }

    /* Copy the animation program into SPRAM. */
    memcpy((void *)prog_target,  (uint8_t *)hdr + hdr->data_start,  hdr->data_size);

    /* Copy the frame data into the framebuffer */
    memcpy((void *)frame_target, (uint8_t *)hdr + hdr->frame_start, hdr->frame_size);
    
    /* Execute it */
    asm volatile(
        "jalr %[target] \n" /* Jump to the target address */
        "j _entry       \n" /* We should never get here, reboot if we do. */
        :: [target]"r"(hdr->entry));
}

static int
check_bootslot(int slot)
{
    const uintptr_t bootsz = 64 * 1024;
    uintptr_t target = 0x20000000;
    const struct boot_header *hdr = bootaddr(slot);

    /* For the animation to be valid - the tag must match, and the entry point should be sane */
    if (hdr->tag != BOOT_HDR_TAG) return 0;
    if ((hdr->data_start + hdr->data_size) > bootsz) return 0;
    if ((hdr->frame_start + hdr->frame_size) > bootsz) return 0;
    if (hdr->entry < target) return 0;
    if (hdr->entry > target + hdr->data_size) return 0;

    /* Otherwise, the animation is valid */
    return 1;
}

int main(void)
{
    static int slot = 0;
    int toggle = 0;
    char ch = 'A';
    int retcode;
    int count;

    MISC->leds[0] = 0;
    MISC->leds[1] = 255;
    MISC->leds[3] = 0;

    /* DEBUG: Wait for a character press before starting */
    while ((SERIAL->isr & 0x01) == 0) {
        /* nop */
    }

    /* Enable interrupts for testing */
    /* Not sure if this is a hardware problem, but BT0 is extremely noisy. */
    MISC->i_status = 0xF;
    MISC->i_enable = 0x8;

    /* Count the number of animations present. */
    count = 0;
    while (check_bootslot(count)) count++;

    /* Return here after an animation exits. */
    retcode = setjmp(bootjmp);
    if (retcode != 0) {
        printf("Animation at slot %d exitied with code=%d\n", slot, retcode);
        if (retcode == 1) {
            /* Seek the animation forward. */
            if (slot < count-1) slot++;
            else slot = 0;
        }
        else {
            /* Seek the animation backawrd. */
            if (slot != 0) slot--;
            else slot = count - 1;
        }
    }

    MISC->leds[0] = 0;
    MISC->leds[1] = 1;
    MISC->leds[3] = 0;

    /* Load the next animation */
    bootload(slot);
}
