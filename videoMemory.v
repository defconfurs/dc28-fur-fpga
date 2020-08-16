`include "globals.vh"
`default_nettype none

module video_memory #(
    parameter ADDRESS_WIDTH   = 16,
    parameter DATA_WIDTH      = 8,
    parameter DATA_BYTES      = 1,
    parameter BASE_ADDRESS    = 16'h8000,
    parameter BASE_FRAME_ADDR = `FRAME_MEMORY_START + 1024
)  (
    // Wishbone interface
    input wire                     rst_i,
    input wire                     clk_i,

    input wire [ADDRESS_WIDTH-1:0] adr_i,
    input wire [DATA_WIDTH-1:0]    dat_i,
    output reg [DATA_WIDTH-1:0]    dat_o,
    input wire                     we_i,
    input wire [DATA_BYTES-1:0]    sel_i,
    input wire                     stb_i,
    input wire                     cyc_i,
    output reg                     ack_o,
    input wire [2:0]               cti_i,

    input wire                     dfu_busy,
    output reg                     mem_busy,
    
    output reg                     spi_clk,
    output reg                     spi_sel,
    output reg [3:0]               spi_d_out,
    input wire [3:0]               spi_d_in,
    output reg [3:0]               spi_d_dir
  );

  localparam ADDR_WIDTH = 15;

  reg memory_busy;

  wire [ADDR_WIDTH-1:0] ram_address;
  wire [7:0]            ram_data_in;
  reg [7:0]             ram_data_out;
  reg                   ram_we;

  
  reg [ADDR_WIDTH-1:0]  raminst_address;
  reg [7:0]             raminst_data_in;
  wire [7:0]            raminst_data_out;
  reg                   raminst_we;

  
  wire [ADDRESS_WIDTH-1:0] local_address;
  wire                     valid_address;
  reg                      valid_reg_address;
  reg [DATA_WIDTH-1:0]     reg_data;
  assign local_address = adr_i - BASE_ADDRESS;
  assign valid_address = local_address < 16'h8000;
  wire                     masked_cyc;
  assign masked_cyc = (valid_address & cyc_i);
  always @(posedge clk_i) begin
    ack_o <= cyc_i & valid_address;
  end

  always @(*) begin
    if (valid_reg_address)               dat_o = reg_data;
    else if (!mem_busy && valid_address) dat_o = raminst_data_out;
    else                                 dat_o = 0;
  end
  

  reg [15:0] read_addr;
  reg [15:0] save_addr;
  reg [15:0] read_length;
  reg        start_read;
  
  reg   [7:0] ignored;
  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      start_read  <= 0;
      read_addr   <= 0;
      read_length <= 0;
      save_addr   <= BASE_FRAME_ADDR;
    end
    else begin
      if (mem_busy) start_read <= 0;
      
      if (masked_cyc & we_i) begin
        case (local_address) 
        `VIDMEM_CONTROL       : { ignored[7:1], start_read } <= dat_i;
        `VIDMEM_READ_ADDR     : read_addr[7:0]               <= dat_i;
        `VIDMEM_READ_ADDR+1   : read_addr[15:8]              <= dat_i;
        `VIDMEM_READ_LENGTH   : read_length[7:0]             <= dat_i;
        `VIDMEM_READ_LENGTH+1 : read_length[15:8]            <= dat_i;
        `VIDMEM_SAVE_ADDR     : save_addr[7:0]               <= dat_i;
        `VIDMEM_SAVE_ADDR+1   : save_addr[15:0]              <= dat_i;
        endcase
      end
    end
  end

  always @(*) begin
    valid_reg_address = 0;
    reg_data          = 0;
    if (masked_cyc) begin 
      case (local_address)
      `VIDMEM_CONTROL       : begin valid_reg_address = 1; reg_data = {7'd0, mem_busy | start_read}; end
      `VIDMEM_READ_ADDR     : begin valid_reg_address = 1; reg_data = read_addr[7:0]; end
      `VIDMEM_READ_ADDR+1   : begin valid_reg_address = 1; reg_data = read_addr[15:8]; end
      `VIDMEM_READ_LENGTH   : begin valid_reg_address = 1; reg_data = read_length[7:0]; end
      `VIDMEM_READ_LENGTH+1 : begin valid_reg_address = 1; reg_data = read_length[15:8]; end
      `VIDMEM_SAVE_ADDR     : begin valid_reg_address = 1; reg_data = save_addr[7:0]; end
      `VIDMEM_SAVE_ADDR+1   : begin valid_reg_address = 1; reg_data = save_addr[15:0]; end
      endcase
    end
  end



  always @(*) begin
    if (mem_busy) begin
      raminst_we      = ram_we;
      raminst_data_in = ram_data_in;
      raminst_address = ram_address;
      ram_data_out    = raminst_data_out;
    end
    else begin
      raminst_we      = (stb_i & valid_address & we_i);
      raminst_data_in = dat_i;
      raminst_address = local_address;
      ram_data_out    = 0;
    end
  end
  
  wire [1:0]  wen;
  wire [15:0] dat_16;
  reg [ADDR_WIDTH-1:0]  latched_address;
  always @(posedge clk_i) latched_address <= raminst_address;
  assign wen              = raminst_we ? { raminst_address[0], ~raminst_address[0] } : 2'b00;
  assign raminst_data_out = mem_busy ? 8'b00 : (latched_address[0] ? dat_16[15:8] : dat_16[7:0]);
  SB_SPRAM256KA ram00
  (
    .ADDRESS    (raminst_address[14:1]),
    .DATAIN     ({raminst_data_in,raminst_data_in}),
    .MASKWREN   ({wen[1], wen[1], wen[0], wen[0]}),
    .WREN       (raminst_we),
    .CHIPSELECT (1),
    .CLOCK      (clk_i),
    .STANDBY    (1'b0),
    .SLEEP      (1'b0),
    .POWEROFF   (1'b1),
    .DATAOUT    (dat_16)
  );


  wire  clk, rst;
  assign clk = clk_i;
  assign rst = rst_i;

  localparam STATE_IDLE   = 4'b0001;
  localparam STATE_HEADER = 4'b0010;
  localparam STATE_DUMMY  = 4'b0100;
  localparam STATE_READ   = 4'b1000;

  reg [3:0] state;
  reg [3:0] next_state;

  localparam FLASH_COMMAND_READ = 8'h3B; // 8'h0B for FAST_READ, 8'h3B for dual, 8'h6B for quad
  localparam HEADER_LENGTH      = 24;
  localparam DUMMY_LENGTH       = 8+8; // last byte of address is always 0 so make it part of the dummy
  localparam BITS_PER_CLOCK     = 2;
  localparam CLOCKS_PER_BYTE    = 8/BITS_PER_CLOCK;

  reg [26:0] byte_count;  // extra bits for bit number
  reg [26:0] next_byte_count;
  reg [15:0] latched_read_length;
  reg [15:0] latched_save_addr;
  always @(posedge clk) if (!mem_busy) latched_read_length <= read_length;
  always @(posedge clk) if (!mem_busy) latched_save_addr   <= save_addr;
  
  reg [7:0] local_state;
  reg [7:0] next_local_state;

  reg [HEADER_LENGTH-1:0] header;
  reg [HEADER_LENGTH-1:0] next_header;
  
  reg [7:0] byte_buffer;
  reg [7:0] next_byte_buffer;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state       <= STATE_IDLE;
      byte_count  <= 0;
      local_state <= 0;
      header      <= 0;
      byte_buffer <= 0;
    end
    else begin
      state       <= next_state;
      byte_count  <= next_byte_count;
      local_state <= next_local_state;
      header      <= next_header;
      byte_buffer <= next_byte_buffer;
    end
  end
  
  always @(*) begin
    next_state       = state;
    mem_busy         = 0;
    next_header      = header;
    next_local_state = local_state;
    next_byte_buffer = byte_buffer;
    next_byte_count  = byte_count;
    spi_d_out        = 4'd0;
    spi_d_dir        = 4'b0001; // default to inputs except the MOSI
    spi_sel          = 1;
    spi_clk          = 1;
    ram_we           = 0;
    
    case (state)

    STATE_IDLE: begin
      mem_busy = 0;
      if (start_read) begin
        if (!dfu_busy) begin
          mem_busy         = 1;
          next_state       = STATE_HEADER;
          next_local_state = HEADER_LENGTH;
          next_header      = { FLASH_COMMAND_READ, read_addr };
          next_byte_count  = 0;
          next_byte_buffer = 0;
        end
      end
    end

    STATE_HEADER: begin
      mem_busy = 1;
      spi_d_out   = { 3'd0, header[HEADER_LENGTH-1] };
      spi_d_dir   = 4'b0001;
      spi_sel     = 0;
      spi_clk     = clk;
      
      if (local_state) begin
        next_local_state = local_state - 1;
        next_header      = { header[HEADER_LENGTH-2:0], 1'b0 };
      end
      else begin
        next_local_state = DUMMY_LENGTH;
        next_state       = STATE_DUMMY;
      end
    end

    STATE_DUMMY: begin
      mem_busy = 1;
      spi_d_out   = 4'b0000;
      spi_sel     = 0;
      spi_clk     = clk;
      
      if (local_state < 2) spi_d_dir = 4'b0000;
      else                 spi_d_dir = 4'b0001;

      if (local_state) begin
        next_local_state = local_state - 1;
      end
      else begin
        next_local_state = CLOCKS_PER_BYTE;
        next_state       = STATE_READ;
      end
    end
    
    STATE_READ: begin
      mem_busy = 1;
      spi_d_dir   = 4'b0000;
      spi_sel     = 0;
      spi_clk     = clk;

      next_byte_buffer = { byte_buffer[5:0], spi_d_in[1:0] };
      
      if (byte_count[26:11] < latched_read_length) begin
        next_byte_count = byte_count + BITS_PER_CLOCK;
        
        if (next_byte_count[26:3] != byte_count[26:3]) ram_we = 1;
      end
      else begin
        next_state = STATE_IDLE;
      end
    end
    
    default:
        next_state = STATE_IDLE;
    endcase
  end

  //reg [ADDR_WIDTH-1:0] ram_address;
  //reg [7:0]            ram_data_in;
  //wire [7:0]           ram_data_out;
  //reg                  ram_we;
  assign ram_data_in = byte_buffer;
  assign ram_address = byte_count[3+ADDR_WIDTH-1:3] + latched_save_addr[ADDR_WIDTH:0];
  
endmodule
