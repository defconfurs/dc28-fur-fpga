`include "globals.vh"
`default_nettype none

module spi_interface #(
    parameter ADDRESS_WIDTH   = 16,
    parameter DATA_WIDTH      = 32,
    parameter DATA_BYTES      = 4,
    parameter BASE_ADDRESS    = 16'h0000,
    parameter MEM_ADDRESS     = 16'h1000
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

    output reg                     spi_clk,
    output reg                     spi_sel,
    output reg [3:0]               spi_d_out,
    input wire [3:0]               spi_d_in,
    output reg [3:0]               spi_d_dir
  );

  wire  clk, rst;
  assign clk = clk_i;
  assign rst = rst_i;

  localparam ADDR_WIDTH = 8;

  reg memory_busy;


  reg [ADDR_WIDTH-1:0]  raminst_address;
  reg [31:0]            raminst_data_in;
  wire [31:0]           raminst_data_out;
  reg                   raminst_we;

  reg [ADDR_WIDTH-1:0]  ram_address;
  reg [31:0]            ram_data_in;
  wire [31:0]           ram_data_out;
  reg                   ram_we;

  
  wire [ADDRESS_WIDTH-1:0] local_address;
  wire                     valid_address;
  reg                      valid_reg_address;
  reg [DATA_WIDTH-1:0]     reg_data;
  reg [DATA_WIDTH-1:0]     reg_data_1;
  wire [ADDRESS_WIDTH-1:0] base_address     = BASE_ADDRESS;
  wire [ADDRESS_WIDTH-1:0] mem_base_address = MEM_ADDRESS;

  wire                     valid_reg_bank = (adr_i == base_address[ADDRESS_WIDTH-1:REG_ADDR_SIZE]);
  wire                     valid_mem_bank = (adr_i == mem_base_address[ADDRESS_WIDTH-1:ADDR_WIDTH]);

  assign local_address = adr_i[REG_ADDR_SIZE-1:0];
  assign valid_address = (valid_reg_bank && valid_reg_address) || valid_mem_bank;
  wire                     masked_cyc;
  assign masked_cyc = (valid_address & cyc_i);
  always @(posedge clk_i) begin
    ack_o <= cyc_i & valid_address;
  end

  always @(*) begin
    if      (valid_reg_bank) dat_o = reg_data_1;
    else if (valid_mem_bank) dat_o = raminst_data_out;
    else                     dat_o = 0;
  end

  // latch the reg_data
  always @(posedge clk_i) reg_data_1 <= reg_data;
  

  reg [32:0]             read_addr;
  reg [ADDR_WIDTH+1-1:0] read_length;
  reg                    start_read;

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      start_read  <= 0;
      read_addr   <= 0;
      read_length <= 0;
    end
    else begin
      if (mem_busy) start_read <= 0;
      
      if (masked_cyc & we_i) begin
        case (local_address) 
        `SPIMEM_CONTROL       : start_read  <= dat_i[0];
        `SPIMEM_READ_ADDR     : read_addr   <= dat_i;
        `SPIMEM_READ_LENGTH   : read_length <= dat_i[ADDR_WIDTH+1-1:0];
        endcase
      end
    end
  end

  always @(*) begin
    valid_reg_address = 0;
    reg_data          = 0;
    if (masked_cyc) begin 
      case (local_address)
      `SPIMEM_CONTROL       : begin valid_reg_address = 1; reg_data = {31'd0, mem_busy | start_read}; end
      `SPIMEM_READ_ADDR     : begin valid_reg_address = 1; reg_data = read_addr; end
      `SPIMEM_READ_LENGTH   : begin valid_reg_address = 1; reg_data = read_length; end
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

  
  simple_ram #(//512x8
    .addr_width( ADDR_WIDTH ),
    .data_width( DATA_WIDTH )
  ) ram_inst (
    .clk     ( clk_i ),
    .address ( raminst_address ), 
    .din     ( raminst_data_in ),
    .dout    ( raminst_data_out ),
    .we      ( raminst_we )
  );


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
  localparam CLOCKS_PER_WORD    = DATA_WIDTH/BITS_PER_CLOCK;

  localparam EXTRA_BITS = $clog2(CLOCKS_PER_WORD);
  reg [ADDR_WIDTH+EXTRA_BITS-1:0] word_count;
  reg [26:0] next_word_count;
  reg [ADDR_WIDTH+1-1:0] latched_read_length;
  always @(posedge clk) if (!mem_busy) latched_read_length <= read_length;
  
  reg [7:0] local_state;
  reg [7:0] next_local_state;

  reg [HEADER_LENGTH-1:0] header;
  reg [HEADER_LENGTH-1:0] next_header;
  
  reg [31:0] word_buffer;
  reg [31:0] next_word_buffer;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state       <= STATE_IDLE;
      word_count  <= 0;
      local_state <= 0;
      header      <= 0;
      word_buffer <= 0;
    end
    else begin
      state       <= next_state;
      word_count  <= next_word_count;
      local_state <= next_local_state;
      header      <= next_header;
      word_buffer <= next_word_buffer;
    end
  end
  
  always @(*) begin
    next_state       = state;
    mem_busy         = 0;
    next_header      = header;
    next_local_state = local_state;
    next_word_buffer = word_buffer;
    next_word_count  = word_count;
    spi_d_out        = 4'd0;
    spi_d_dir        = 4'b0001; // default to inputs except the MOSI
    spi_sel          = 1;
    spi_clk          = 1;
    ram_we           = 0;
    
    case (state)

    STATE_IDLE: begin
      mem_busy = 0;
      if (start_read) begin
        mem_busy         = 1;
        next_state       = STATE_HEADER;
        next_local_state = HEADER_LENGTH;
        next_header      = { FLASH_COMMAND_READ, read_addr };
        next_word_count  = 0;
        next_word_buffer = 0;
      end
    end

    STATE_HEADER: begin
      mem_busy  = 1;
      spi_d_out = { 3'd0, header[HEADER_LENGTH-1] };
      spi_d_dir = 4'b0001;
      spi_sel   = 0;
      spi_clk   = clk;
      
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
      mem_busy  = 1;
      spi_d_out = 4'b0000;
      spi_sel   = 0;
      spi_clk   = clk;
      
      if (local_state < 2) spi_d_dir = 4'b0000;
      else                 spi_d_dir = 4'b0001;

      if (local_state) begin
        next_local_state = local_state - 1;
      end
      else begin
        next_local_state = CLOCKS_PER_WORD;
        next_state       = STATE_READ;
      end
    end
    
    STATE_READ: begin
      mem_busy  = 1;
      spi_d_dir = 4'b0000;
      spi_sel   = 0;
      spi_clk   = clk;
      
      next_word_buffer = { word_buffer[DATA_WIDTH-BITS_PER_CLOCK-1:0], spi_d_in[BITS_PER_CLOCK-1:0] };
      
      if (word_count[ADDR_WIDTH+EXTRA_BITS-1:EXTRA_BITS] < latched_read_length) begin
        next_word_count = word_count + 1;
        
        if (next_word_count[26:3] != word_count[26:3]) ram_we = 1;
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
  assign ram_data_in = word_buffer;
  assign ram_address = word_count[ADDR_WIDTH+EXTRA_BITS-1:EXTRA_BITS];
  
endmodule
