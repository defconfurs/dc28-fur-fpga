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

`default_nettype none

`define FRAME_MEMORY_START (16'h0000)
`define FRAME_MEMORY_END   (16'hFFFF)
`define DEFAULT_FRAME_ADDRESS (`FRAME_MEMORY_START + 1)

`define MATRIX_START (16'h0000)

`define MEM2_START (16'h0000)


`define MATRIX_ADDR       (4'h0)


`define SPIMEM_CONTROL     ('h00)
`define SPIMEM_READ_ADDR   ('h01)
`define SPIMEM_READ_LENGTH ('h02)
