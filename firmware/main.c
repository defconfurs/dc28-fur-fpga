#include <stdint.h>
#include <printf.h>

#define LED_PWM_BASE    (volatile uint32_t *)0x40000000
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
#define SERIAL ((volatile struct serial_regmap *)0x40010000)

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
    int x, y;
    int count = 0;
    int success = 0;

    ledpwm[0] = 127;
    ledpwm[1] = 0;
    ledpwm[3] = 0;
    
    //for (i = 0; i < LED_PWM_COUNT; i++) {
    //    ledpwm[i] = val;
    //    val >>= 2;
    //}

    for (y = 0; y < 14; y++) {
        for (x = 0; x < 32; x++) {
            *(uint16_t*)(0x40020004 + (x<<1) + (y<<6)) = x<<11 | y<<1;
        }
    }
    *(uint16_t*)(0x40020000) = 4;

    ledpwm[0] = 0;
    ledpwm[1] = 1;
    ledpwm[3] = 0;
    
    /* And finally - the main loop. */
    while (1) {
        /* If there are characters received, echo them back. */
        if (SERIAL->isr & 0x01) {
            uint8_t ch = SERIAL->rhr;
            ledpwm[1] = (toggle) ? 0xff : 0;
            toggle = (toggle == 0);
            count++;

            if (ch == 0x20) {
                //*(uint8_t*)(0x10000008) = 0x5A;
                //*(uint8_t*)(0x10000009) = 0x01;
                //*(uint8_t*)(0x1000000A) = 0x02;
                //*(uint8_t*)(0x1000000B) = 0x03;
                //printf(" u8: %08X\n\r", *(volatile uint32_t*)(0x10000008));
                //
                //*(uint16_t*)(0x1000000C) = 0x345A;
                //*(uint16_t*)(0x1000000E) = 0x0102;
                //printf("u16: %08X\n\r", *(volatile uint32_t*)(0x1000000C));
                //
                //*(uint32_t*)(0x10000010) = 0x0607345A;
                //printf("u32: %08X\n\r", *(volatile uint32_t*)(0x10000010));
                //
                //printf("array write/read\n\r");
                //for (i = 0; i < 16; i++) {
                //    *(volatile uint16_t*)(0x10001000+(i<<1)) = i;
                //}
                //for (i = 0; i < 16; i++) {
                //    printf("%08X\n\r", *(volatile uint16_t*)(0x10001000+(i<<1)));
                //}
                //for (i = 0; i < 8; i++) {
                //    printf("%08X\n\r", *(volatile uint32_t*)(0x10001000+(i<<2)));
                //}

                for (i = 0; i < 32; i++) {
                    printf("%08X\n\r", *(volatile uint32_t*)(0x30000000+(i<<2)));
                }
            }
            
#if 1
            if ((count % 64) == 0) {
                printf("Hello World %d\n", count);
                //for (i=0; i < 64; i++) {
                //    *(uint16_t*)(0x50000100+(i<<1)) = i;
                //}
                //for (i=0; i < 32; i++) {
                //    printf("%08X\n\r", *(volatile uint32_t*)(0x50000100+i<<2));
                //}
                //if (success) printf("Mem check passed\n\r");
                //else         printf("Mem check failed\n\r");
            }
#else
            serial_putc(ch);
#endif
        }
    }
}
