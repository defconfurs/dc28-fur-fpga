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
