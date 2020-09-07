
#include <stdarg.h>
#include <stdint.h>

extern void _putchar(int ch);

#define PRINTF_FLAG_JUSTIFY     (1 << 0)
#define PRINTF_FLAG_ZERO_PAD    (1 << 1)
#define PRINTF_FLAG_SIGN_PAD    (1 << 2)
#define PRINTF_FLAG_FORCE_SIGN  (1 << 3)

#define PRINTF_DIGITS_SIZE      (sizeof(uint32_t) * 3 + 1)

/* The version built into libc uses a lookup table - we don't have space for that. */
static inline int bios_isdigit(int x)
{
    return (x >= '0') && (x <= '9');
}

/* The version built into libc is way too complex, we can be smaller. */
static inline int bios_strlen(const char *str)
{
    const char *start = str;
    while (*str != '\0') str++;
    return (str - start);
}

/* Bithacking to get a divide-by-10 */
/* Copied from the 'Hacker's Delight' algorithm */
static inline unsigned int
bios_div10(unsigned int n)
{
    unsigned int q, r;
    q = (n >> 1) + (n >> 2);
    q = q + (q >> 4);
    q = q + (q >> 8);
    q = q + (q >> 16);
    q = q >> 3;
    r = n - (((q << 2) + q) << 1);
    return q + (r > 9);
}

static char *
bios_hex_digits(uint32_t value, char alpha, char *outbuf)
{
    int offset = PRINTF_DIGITS_SIZE;
    outbuf[--offset] = '\0';

    /* Special case */
    if (value == 0) {
        outbuf[--offset] = '0';
    }
    /* Build the hex string */
    while (value) {
        int nibble = value & 0xF;
        value >>= 4;
        outbuf[--offset] = (nibble >= 10) ? (alpha + nibble - 10) : ('0' + nibble);
    }

    return &outbuf[offset];
}

static char *
bios_decimal_digits(uint32_t value, char *outbuf)
{
    int offset = PRINTF_DIGITS_SIZE;
    outbuf[--offset] = '\0';

    /* Special Case */
    if (value == 0) {
        outbuf[--offset] = '0';
    }
    /* Build the decimal string */
    while (value) {
        /* We pray to our compiler gods to make this efficient */
        unsigned int vdiv10 = bios_div10(value);
        unsigned int rem = value - (vdiv10 << 2) - (vdiv10 << 8);
        outbuf[--offset] = '0' + rem;
        value = vdiv10;
    }
    return &outbuf[offset];
}

/* Print a string of digits out the uart, while honoring the flags. */
static void
bios_print_digits(int sign, unsigned int flags, unsigned int width, const char *digits)
{
    int len = bios_strlen(digits);
    char signchar = '\0';

    /* Generate the sign character */
    if (sign < 0) signchar = '-';
    else if (flags & PRINTF_FLAG_FORCE_SIGN) signchar = '+';
    else if (flags & PRINTF_FLAG_SIGN_PAD) signchar = ' ';

    /* Count the sign as part of the digits */
    if (signchar) len++;

    /* Zero-padding version - always right-justified. */
    if (flags & PRINTF_FLAG_ZERO_PAD) {
        if (signchar) _putchar(signchar);            /* Sign */
        for (;len < width; width--) _putchar('0');   /* Padding */
        while (*digits != '\0') _putchar(*digits++); /* Digits */
    }
    /* Left-justified version. */
    else if (flags & PRINTF_FLAG_JUSTIFY) {
        if (signchar) _putchar(signchar);            /* Sign */
        while (*digits != '\0') _putchar(*digits++); /* Digits */
        for (;len < width; width--) _putchar(' ');   /* Padding */
    }
    /* Right-justified version. */
    else {
        for (;len < width; width--) _putchar(' ');   /* Padding */
        if (signchar) _putchar(signchar);            /* Sign */
        while (*digits != '\0') _putchar(*digits++); /* Digits */
    }
}

static void
bios_print_hex(uint32_t value, unsigned int flags, int width, char alpha)
{
    char temp[PRINTF_DIGITS_SIZE];
    char *digits = bios_hex_digits(value, alpha, temp);

    bios_print_digits(0, flags, width, digits);
}

static void
bios_print_unsigned(uint32_t value, unsigned int flags, int width)
{
    char temp[PRINTF_DIGITS_SIZE];
    char *digits = bios_decimal_digits(value, temp);
    
    bios_print_digits(0, flags, width, digits);
}

static void
bios_print_signed(int32_t value, unsigned int flags, int width)
{
    char temp[PRINTF_DIGITS_SIZE];
    char *digits;

    if (value < 0) {
        digits = bios_decimal_digits(-value, temp);
    } else {
        digits = bios_decimal_digits(value, temp);
    }

    bios_print_digits(value, flags, width, digits);
}

static void
bios_print_string(const char *val, unsigned int flags, int width)
{
    bios_print_digits(0, flags, width, val);
}

/* An extremely minimal printf. */
void
bios_vprintf(const char *fmt, va_list ap)
{
    unsigned int flags;
    unsigned int width;
    unsigned int precision;
    char mods;
    char specifier;

    while (1) {
        char ch = *fmt++;
        unsigned int flags = 0;
        unsigned int precision = 0;
        unsigned int mods = 0;
        int width = 0;

        /* Handle non-escape sequences */
        if (ch == '\0') {
            return;
        }
        if (ch != '%') {
            _putchar(ch);
            continue;
        }

        /* Parse the flags, if any. */
        for (;;) {
            ch = *fmt;
            if (ch == '-')      flags |= PRINTF_FLAG_JUSTIFY;
            else if (ch == '+') flags |= PRINTF_FLAG_FORCE_SIGN;
            else if (ch == ' ') flags |= PRINTF_FLAG_SIGN_PAD;
            else if (ch == '0') flags |= PRINTF_FLAG_ZERO_PAD;
            else break;
            fmt++;
        }
        /* Parse the width, if present. */
        while (bios_isdigit(*fmt)) {
            width = (width * 10) + (*fmt++ - '0');
        }

        /* Parse out the precision, even though we don't use it. */
        if (*fmt == '.') {
            for (fmt++; bios_isdigit(*fmt); fmt++) {
                precision = (precision * 10) + (*fmt - '0');
            }
        }
        /* Parse the modifiers, even though we don't use them. */
        for (;;) {
            ch = *fmt;
            if (ch == 'h' || ch == 'l' || ch == 'j' || ch == 'z' || ch == 't') {
                mods = ch;
                fmt++;
            }
            else break;
        }

        /* And finally, handle the specifier */
        ch = *fmt++;
        switch (ch) {
            case '%':
                _putchar('%');
                break;
            case 'p':
            case 'x': {
                uint32_t val = va_arg(ap, uint32_t);
                bios_print_hex(val, flags, width, 'a');
                break;
            }
            case 'X': {
                uint32_t val = va_arg(ap, uint32_t);
                bios_print_hex(val, flags, width, 'A');
                break;
            }
            /* TODO: Octal? No one uses octal anymore */
            case 'u': {
                uint32_t val = va_arg(ap, uint32_t);
                bios_print_unsigned(val, flags, width);
                break;
            }
            case 'i':
            case 'd': {
                int32_t val = va_arg(ap, int32_t);
                bios_print_signed(val, flags, width);
                break;
            }
            case 'c': {
                char val = va_arg(ap, int);
                _putchar(val);
                break;
            }
            case 's': {
                const char *val = va_arg(ap, const char *);
                bios_print_string(val, flags, width);
                break;
            }
            case '\0':
                return;
            default:
                break;
        }
    } /* while */
}

void
bios_printf(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    bios_vprintf(fmt, ap);
    va_end(ap);
}