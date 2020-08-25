MEMORY
{
    ROM  (rx) : ORIGIN = 0x00000000, LENGTH = 4096
    SRAM (rwx) : ORIGIN = 0x10000000, LENGTH = 4096
}

ENTRY(start)

SECTIONS
{
    /* Place program code directly into ROM */
    .text : {
        . = ALIGN(4);
        *(.text)            /* .text sections (code) */
        *(.text*)           /* .text sections (code) */
        *(.rodata)          /* .rodata sections (constants, strings, etc) */
        *(.rodata*)         /* .rodata sections (constants, strings, etc) */
        *(.srodata)         /* .rodata sections (constants, strings, etc) */
        *(.srodata*)        /* .rodata sections (constants, strings, etc) */
        . = ALIGN(4);
        _etext = .;         /* Mark the end of the code section */
        _sreldata = _etext;   /* Mark the start of initialized .data */
    } > ROM

    /* Store initialized .data in ROM to be relocated. */
    .data : AT( _sreldata ) {
        _sdata = .;         /* Mark the start of initialized data */
        . = ALIGN(4);
        *(.data)            /* .data sections (static and global variables) */
        *(.data*)           /* .data sections (static and global variables) */
        *(.sdata)           /* .data sections (static and global variables) */
        *(.sdata*)          /* .data sections (static and global variables) */
        . = ALIGN(4);
        _edata = .;         /* Mark the end of initialized data */
    } > SRAM

    /* Uninitialized data sections to be zero-filled */
    .bss : {
        . = ALIGN(4);
        _sbss = .;
        *(.bss)
        *(.bss*)
        *(.sbss)
        *(.sbss*)
        *(COMMON)

        . = ALIGN(4);
        _ebss = .;
    } > SRAM

    .heap : {
        . = ALIGN(4);
        _heap_start = .;    /* Mark the start of free memory */
    } > SRAM

    /* Initial stack should start at the end of SRAM. */
    _stack_start = ORIGIN(SRAM) + LENGTH(SRAM) - 4;
}
