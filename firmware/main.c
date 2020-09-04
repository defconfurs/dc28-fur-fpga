#include <stdint.h>
#include <string.h>
#include <printf.h>
#include <string.h>

#define LED_PWM_BASE    (volatile uint32_t *)0x40000000
#define LED_PWM_COUNT   4

/*=====================================
 * Animation Number
 *=====================================
 */
#define ANIM_NUM (*(volatile uint32_t *)0x10000FFC)

// NS16650 Serial Interface
typedef uint32_t serial_reg_t;
struct serial_regmap {
    union {
        serial_reg_t thr;   // Transmit Holding Register.
        serial_reg_t rhr;   // Receive Holding Register.
    };
    serial_reg_t ier;   // Interrupt Enable Register.
    serial_reg_t isr;   // Interrupt Status Register.
} __attribute__((packed));
#define SERIAL ((volatile struct serial_regmap *)0x40010000)

/*=====================================
 * Miscellaneous Peripherals
 *=====================================
 */
struct misc_regs {
    uint32_t leds[3];   /* Status LED PWM intensity: Red, Green and Blue */
    uint32_t button;    /* Button Status */
    uint32_t mic;       /* Microphone Data */
};
#define MISC ((volatile struct misc_regs *)0x40000000)


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


void bootload(int slot)
{
    uint32_t current_animation = 0;
    const uintptr_t bootsz = 64 * 1024;
    uintptr_t target = 0x20000000;
    uintptr_t userdata = 0x30000000 + (1024 * 1024);    /* User data starts 1MB into flash. */
    uintptr_t animation = userdata + (slot * bootsz);   /* Animations are spaced 64kB apart. */

    //printf("about to copy data\n\r");
    /* Copy the animation into RAM. */
    memcpy((void *)target, (void *)animation, bootsz);
    //printf("copy done\n\r");

    while (*(uint32_t*)target == 0xFFFFFFFF) {
        //printf("anim %d invalid; moving back one\n\r");
        if (ANIM_NUM == 0) {
            // no valid image - drop into the main loop
            //printf("no valid animations\n\r");
            return;
        }
        // otherwise go back an image and see if that one's valid
        ANIM_NUM--;
        animation = userdata + (ANIM_NUM * bootsz);   /* Animations are spaced 64kB apart. */
        memcpy((void *)target, (void *)animation, bootsz);
    }
    //printf("running image\n\r");
    
    /* Execute it */
    asm volatile(
        "jalr %[target] \n" /* Jump to the target address */
        "j _entry       \n" /* If we happen to return - reboot */
        :: [target]"r"(target));
}

int main(void)
{
    volatile uint32_t *ledpwm = LED_PWM_BASE;
    int toggle = 0;
    char ch = 'A';
    int i;
    int count = 0;

    ledpwm[0] = 0;
    ledpwm[1] = 1;
    ledpwm[3] = 0;

    ANIM_NUM = 0;

    bootload(ANIM_NUM);
    
    /* And finally - the main loop. */
    while (1) {
        /* If there are characters received, echo them back. */
        if (SERIAL->isr & 0x01) {
            uint8_t ch = SERIAL->rhr;
            //ledpwm[1] = (toggle) ? 0xff : 0;
            toggle = (toggle == 0);
            count++;

            _putchar(ch);

            if (ch == 'b') {
                /* Bootload the animation in slot 0. */
                bootload(0);
            }
        }
    }
}
