/*
 * This file is part of the DEFCON Furs DC28 badge project.
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2020 DEFCON Furs <https://dcfurs.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

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
