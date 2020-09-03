#include <stdint.h>
#include <string.h>
#include <printf.h>
#include <string.h>

#define LED_PWM_BASE    (volatile uint32_t *)0x40000000
#define LED_PWM_COUNT   4

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

//
//    static const uint32_t bitmap[] = {
//        0b11100000000000000111111111111111,
//        0b11000000000000000011111111111111,
//        0b10000000011000000001111111111111,
//        0b10000000011000000001111111111111,
//        0b10000000011000000001111111111111,
//        0b00000000011000000000111111111111,
//        0b00000000011000000000111111111111,
//        0b00000000011000000000111111111111,
//        0b00000000011000000000111111111111,
//        0b00000000011000000000111111111111,
//        0b00000000011000000000111111111111,
//        0b00000000011000000000111111111111,
//        0b00000000011000000000111111111111,
//        0b00000000011000000000111111111111,
//        0b10000000000000000001111111111111,
//        0b11100000000000000111111111111111,
//    };

static void update_frame(int framenum) {
    int x, y;
    int address;
    int offset;

    offset = framenum >> 2;

    static const uint16_t colours[] = {
        0xF800,
        0xF300,
        0xF5E0,
        0x07C0,
        0x001F,
        0x7817,
        0xFFFF
    };

    static const uint32_t bitmap[] = {
        0b00000000000000000000111111111111,
        0b00000000000000000000111111111111,
        0b00000000000000000000111111111111,
        0b00000000000000000000111111111111,
        0b00000001111110000000111111111111,
        0b01000011111111000010111111111111,
        0b01000100111100100010111111111111,
        0b00111000111100011100111111111111,
        0b00111001111110011100111111111111,
        0b00011101111110111000111111111111,
        0b00011101111110111000111111111111,
        0b00001101111110110000111111111111,
        0b00000111111111100000111111111111,
        0b00000001111110000000111111111111,
        0b00000000000000000000111111111111,
        0b00000000000000000000111111111111,
    };
        
    
    if (framenum & 1) address = 0x40020004;
    else              address = 0x40020404;
    
    for (y = 0; y < 14; y++) {
        for (x = 0; x < 10; x++) {
            if (bitmap[y] & (0x80000000 >> x)) *(uint16_t*)(address + ((  x )<<1) + (y<<6)) = colours[(offset + (x>>1) + (y>>1)) % 6];
            else                               *(uint16_t*)(address + ((  x )<<1) + (y<<6)) = 0;
            if (bitmap[y] & (0x00001000 << x)) *(uint16_t*)(address + ((19-x)<<1) + (y<<6)) = colours[(offset + (x>>1) + (y>>1)) % 6];
            else                               *(uint16_t*)(address + ((19-x)<<1) + (y<<6)) = 0;
        }
    }
    *(uint16_t*)(0x40020000) = address & 0x7FFF;
}

static int cursor_x, cursor_y;
static void update_frame_point(int framenum) {
    (void) framenum;
    int address;
    int x, y;
    if (framenum & 1) address = 0x40020004;
    else              address = 0x40020404;
    for (y = 0; y < 14; y++) {
        for (x = 0; x < 20; x++) {
            if (x == cursor_x && y == cursor_y) *(uint16_t*)(address + (x<<1) + (y<<6)) = 0x7FFF;
            else *(uint16_t*)(address + (x<<1) + (y<<6)) = 0x0000;
        }
    }
    *(uint16_t*)(0x40020000) = address & 0x7FFF;
}

static void update_frame_test_out(int framenum) {
    int address;
    int x, y;
    address = 0x40020004 + 0x80 + ((framenum % 14) * 0x400);
    *(uint16_t*)(0x40020000) = address & 0x7FFF;
}

static void update_frame_audio(int average, int peak) {
    (void) average;
    int address;
    address = 0x40020084;
    if      (peak <   80 ) address += 0x400*15; // 0
    else if (peak <  200 ) address += 0x400*16; // 1
    else if (peak <  500 ) address += 0x400*17; // 2
    else if (peak <  800 ) address += 0x400*18; // 3
    else if (peak < 1100 ) address += 0x400*19; // 4
    else if (peak < 1500 ) address += 0x400*20; // 5
    else if (peak < 1900 ) address += 0x400*21; // 6
    else if (peak < 2200 ) address += 0x400*22; // 7
    else if (peak < 2800 ) address += 0x400*23; // 8
    else                   address += 0x400*23; // 9
    
    *(uint16_t*)(0x40020000) = address & 0x7FFF;
}    

static void bootload(int slot)
{
    const uintptr_t bootsz = 64 * 1024;
    uintptr_t target = 0x20000000;
    uintptr_t userdata = 0x30000000 + (1024 * 1024);    /* User data starts 1MB into flash. */
    uintptr_t animation = userdata + (slot * bootsz);   /* Animations are spaced 64kB apart. */

    /* Copy the animation into RAM. */
    memcpy((void *)target, (void *)animation, bootsz);
    
    /* Execute it */
    asm volatile(
        "jalr %[target] \n" /* Jump to the target address */
        "j _entry       \n" /* If we happen to return - reboot */
        :: [target]"r"(target));
}

int main(void)
{
    volatile uint32_t *ledpwm = LED_PWM_BASE;
    static uint8_t val = 0xff;
    int toggle = 0;
    char ch = 'A';
    int i;
    uint32_t address;
    int x, y;
    int count = 0;
    int success = 0;
    int frame_countdown = 1000;
    int frame_num = 0;
    int peak;
    int audio_abs;
    int audio_average;
    int long_average;
    
    ledpwm[0] = 127;
    ledpwm[1] = 0;
    ledpwm[3] = 0;
    
    cursor_x = 0;
    cursor_y = 0;

    //for (i = 0; i < LED_PWM_COUNT; i++) {
    //    ledpwm[i] = val;
    //    val >>= 2;
    //}

    memcpy((uint32_t*)(0x40020004), (uint32_t*)(0x30100000), 0xFFF0);
    //for (i = 0; i < 0x3C00; i += 4) {
    //    *(uint32_t*)(0x40020004 + i) = *(uint32_t*)(0x30100004 + i);
    //}

    ledpwm[0] = 0;
    ledpwm[1] = 1;
    ledpwm[3] = 0;
    
    /* And finally - the main loop. */
    while (1) {
        audio_average = audio_average - (audio_average>>4) + *(int32_t*)(0x40000010);
        long_average = long_average - (long_average>>8) + audio_average;
        audio_abs = audio_average - (long_average>>8);
        if (audio_abs < 0) audio_abs = -audio_abs;

        if (peak > 1) peak--;
        if (audio_abs > peak) peak = audio_abs;
        
        if (frame_countdown-- == 0) {
            frame_countdown = 20000;
            update_frame_audio(audio_abs, peak);
        }
        
        /* If there are characters received, echo them back. */
        if (SERIAL->isr & 0x01) {
            uint8_t ch = SERIAL->rhr;
            ledpwm[1] = (toggle) ? 0xff : 0;
            toggle = (toggle == 0);
            count++;

            if      (ch == 'a') cursor_x--;
            else if (ch == 'd') cursor_x++;
            else if (ch == 'w') cursor_y--;
            else if (ch == 's') cursor_y++;
            cursor_x &= 0x1F;
            cursor_y &= 0x0F;

            _putchar(ch);

            if (ch == 'b') {
                /* Bootload the animation in slot 0. */
                bootload(0);
            }

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

                //// check button and audio
                //printf("%08X ", *(volatile uint32_t*)(0x4000000C));
                //printf("%08X\n\r", *(volatile uint32_t*)(0x40000010));

                printf("%d - %d\n\r", audio_abs, peak);
                
                //// read out frame
                //printf("\n\r1:\n\r");
                //address = 0x40020004;
                //for (y = 0; y < 14; y++) {
                //    for (x = 0; x < 20; x++) {
                //        printf("%04X ", *(volatile uint16_t*)(address + (x<<1) + (y<<6)));
                //    }
                //    printf("\n\r");
                //}
                //printf("2:\n\r");
                //address = 0x40020404;
                //for (y = 0; y < 14; y++) {
                //    for (x = 0; x < 20; x++) {
                //        printf("%04X ", *(volatile uint16_t*)(address + (x<<1) + (y<<6)));
                //    }
                //    printf("\n\r");
                //}
                //printf("led_matrix address: %04X\r\n", *(volatile uint16_t*)(0x40020000));

                //// read out flash region
                //i = 0;
                //for (y = 0; y < 8; y++) {
                //    for (x = 0; x < 8; x++) {
                //        printf("%08X ", *(volatile uint32_t*)(0x30100000+i));
                //        i+=4;
                //    }
                //    printf("\n\r");
                //}
            }
        }
    }
}
