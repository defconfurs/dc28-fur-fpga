#include <stdint.h>
#include <printf.h>

#define LED_PWM_BASE    (volatile uint32_t *)0x20000000
#define LED_PWM_COUNT   4

// NS16650 Serial Interface
typedef uint32_t serial_reg_t;
struct serial_regmap {
    union {
        serial_reg_t thr;   // Transmit Holding Register.
        serial_reg_t rhr;   // Receive Holding Register.
        serial_reg_t dll;   // Baudrate Divisor LSB 
    };
    union {
        serial_reg_t ier;   // Interrupt Enable Register.
        serial_reg_t dlm;   // Baudrate Divisor MSB
    };
    union {
        serial_reg_t isr;   // Interrupt Status Register.
        serial_reg_t fcr;   // FIFO Configuration Register.
        serial_reg_t pld;   // Prescaler Divider.
    };
    serial_reg_t    lcr;    // Line Control Register.
    serial_reg_t    mcr;    // Modem Control Register.
    serial_reg_t    lsr;    // Line Status Register.
    serial_reg_t    msr;    // Modem Status Register.
    serial_reg_t    scratch; // Scratch Value Register.
} __attribute__((packed));
#define SERIAL ((volatile struct serial_regmap *)0x30000000)

static void serial_putc(int ch)
{
    while ((SERIAL->isr & 0x02) == 0) { /* nop */}
    SERIAL->thr = ch;
}

void _putchar(char ch)
{
    while ((SERIAL->isr & 0x02) == 0) { /* nop */}
    SERIAL->thr = ch;
}

static void serial_puthex(int value)
{
    int nibble = value & 0xF;
    if (value >= 16) {
        serial_puthex(value >> 4);
    } else {
        serial_putc('0');
        serial_putc('x');
    }
    serial_putc(nibble >= 10 ? ('A'+nibble-10) : ('0'+nibble));
}

int main(void)
{
    volatile uint32_t *ledpwm = LED_PWM_BASE;
    static uint8_t val = 0xff;
    int toggle = 0;
    char ch = 'A';
    int i;
    int count = 0;

    for (i = 0; i < LED_PWM_COUNT; i++) {
        ledpwm[i] = val;
        val >>= 2;
    }

    /* And finally - the main loop. */
    while (1) {
        /* If there are characters received, echo them back. */
        if (SERIAL->isr & 0x01) {
            uint8_t ch = SERIAL->rhr;
            ledpwm[0] = (toggle) ? 0xff : 0;
            toggle = (toggle == 0);
            count++;
#if 1
            if ((count % 64) == 0) {
                printf("Hello World %d\n", count);
            }
#else
            serial_putc(ch);
#endif
        }
    }
}
