MEMORY
{
    BOOT (rwx) : ORIGIN = 0x00000000, LENGTH = 4096
    SRAM (rwx) : ORIGIN = 0x10000000, LENGTH = 4096
}

ENTRY(coldboot)

SECTIONS
{
    /* Place program code directly into ROM */
    .text : {
        *(.entry)           /* entry point must go first */

        . = ALIGN(4);
        *(.text)            /* .text sections (code) */
        *(.text*)           /* .text sections (code) */
        *(.rodata)          /* .rodata sections (constants, strings, etc) */
        *(.rodata*)         /* .rodata sections (constants, strings, etc) */
        *(.srodata)         /* .rodata sections (constants, strings, etc) */
        *(.srodata*)        /* .rodata sections (constants, strings, etc) */
        . = ALIGN(4);
        _etext = .;         /* Mark the end of the code section */

        _sdata = .;         /* Mark the start of initialized data */
        . = ALIGN(4);
        *(.data)            /* .data sections (static and global variables) */
        *(.data*)           /* .data sections (static and global variables) */
        *(.sdata)           /* .data sections (static and global variables) */
        *(.sdata*)          /* .data sections (static and global variables) */
        . = ALIGN(4);
        _edata = .;         /* Mark the end of initialized data */

        . = ALIGN(4);
        _sbss = .;
        *(.bss)
        *(.bss*)
        *(.sbss)
        *(.sbss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > BOOT

    /* Initial stack should start at the end of SRAM. */
    _stack_start = ORIGIN(SRAM) + LENGTH(SRAM);
}
