`default_nettype none

`define FRAME_MEMORY_START (16'h8000)
`define FRAME_MEMORY_END   (16'h2FFF)
`define DEFAULT_FRAME_ADDRESS (`FRAME_MEMORY_START)

`define MATRIX_START (16'h0400)
`define MATRIX_END   (16'h040F)

`define MEM2_START (16'h8000)


`define MATRIX_CONTROL    (4'h0)
`define MATRIX_BRIGHTNESS (4'h1)
`define MATRIX_ADDR_L     (4'h2)
`define MATRIX_ADDR_H     (4'h3)


`define VIDMEM_CONTROL     ('h00)
`define VIDMEM_READ_ADDR   ('h02) /* 2 byte */
`define VIDMEM_READ_LENGTH ('h04) /* 2 byte */
`define VIDMEM_SAVE_ADDR   ('h06) /* 2 byte */


`define SPIMEM_CONTROL     ('h00)
`define SPIMEM_READ_ADDR   ('h01)
`define SPIMEM_READ_LENGTH ('h02)
