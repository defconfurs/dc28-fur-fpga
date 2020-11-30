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

/* DFU Board information definitions for the DC28 dcfurs badge */
localparam SPI_FLASH_SIZE = (8 * 1024 *1024);
localparam SPI_ERASE_SIZE = 4096;
localparam SPI_PAGE_SIZE  = 256;

/* Flash partition layout */
localparam IMAGE_SIZE    = (128 * 1024);
localparam BOOTPART_SIZE = IMAGE_SIZE;
localparam USERPART_SIZE = IMAGE_SIZE;

localparam BOOTPART_START = IMAGE_SIZE;
localparam USERPART_START = BOOTPART_START + BOOTPART_SIZE;
localparam DATAPART_START = (1024 * 1024);
localparam DATAPART_SIZE = (SPI_FLASH_SIZE - DATAPART_START);

/* How many security registers are there? */
localparam SPI_SECURITY_REGISTERS = 3;
localparam SPI_SECURITY_REG_SHIFT = 8;

/* USB VID/PID Definitions */
localparam BOARD_VID = 'h26F3;  /* Raven Systems Design, Inc */
`ifdef BOOTLOADER
localparam BOARD_PID = 'h1338;  /* DEFCON Furs DC28 Booploader */
`else
localparam BOARD_PID = 'h1337;  /* DEFCON Furs DC28 Badge */
`endif

/* String Descriptors */
localparam BOARD_MFR_NAME = "DEFCON Furs";
`ifdef BOOTLOADER
localparam BOARD_PRODUCT_NAME = "DEFCON Furs DC28 Booploader";
localparam BOARD_SERIAL = "FEE5h";
`else
localparam BOARD_PRODUCT_NAME = "DEFCON Furs DC28 Badge";
localparam BOARD_SERIAL = "OwO ~notices your badge~";
`endif
