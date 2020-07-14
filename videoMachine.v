`include "globals.vh"
`include "boardinfo.vh"

module video_machine #(
  parameter ADDRESS_WIDTH       = 16,
  parameter DATA_WIDTH          = 8,
  parameter DATA_BYTES          = 1,
  parameter MAX_WAIT            = 8,
  parameter LED_MATRIX_ADDR     = `MATRIX_START,
  parameter LED_MATRIX_REG_ADDR = `MATRIX_ADDR_L,
  parameter BASE_FRAME_ADDR     = `FRAME_MEMORY_START + 1024,
  parameter FRAME_SIZE          = 1024,
  parameter HEADER_SIZE         = 128,
  parameter CLOCK_MHZ           = 12
)(// Wishbone master
  input wire                      rst_i,
  input wire                      clk_i,
  output wire [ADDRESS_WIDTH-1:0] adr_o,
  input wire [DATA_WIDTH-1:0]     dat_i,
  output wire [DATA_WIDTH-1:0]    dat_o,
  output wire                     we_o,
  output wire [DATA_BYTES-1:0]    sel_o,
  output wire                     stb_o,
  input wire                      cyc_i,
  output wire                     cyc_o,
  input wire                      ack_i,
  output wire [2:0]               cti_o,
  
  input wire                      frame_complete,
  input wire                      mem_busy,

  input wire [3:0]                volume_in,
  
  output wire [7:0]               debug
  );

  wire rst;
  wire clk;
  assign clk = clk_i;
  assign rst = rst_i;
  
  localparam MAX_PAYLOAD     = 4;
  localparam INTERFACE_WIDTH = MAX_PAYLOAD * DATA_WIDTH;

  reg [2:0]                  payload_length;
  reg [2:0]                  next_payload_length;
  wire [INTERFACE_WIDTH-1:0] payload_out;
  reg [ADDRESS_WIDTH-1:0]    address;
  reg [ADDRESS_WIDTH-1:0]    next_address;
  reg [INTERFACE_WIDTH-1:0]  payload_in;
  reg [INTERFACE_WIDTH-1:0]  next_payload_in;
  reg                        start_read;
  wire                       read_busy;
  reg                        start_write;
  wire                       write_busy;
  wire                       completed;
  wire                       timeout;

  wishbone_master #(
    .ADDRESS_WIDTH (ADDRESS_WIDTH),
    .DATA_WIDTH    (DATA_WIDTH),
    .DATA_BYTES    (DATA_BYTES),
    .MAX_WAIT      (MAX_WAIT),
    .MAX_PAYLOAD   (MAX_PAYLOAD)
  ) wb_master (
    // Wishbone interface
    .rst_i           ( rst_i ),
    .clk_i           ( clk_i ),
    .adr_o           ( adr_o ),
    .dat_i           ( dat_i ),
    .dat_o           ( dat_o ),
    .we_o            ( we_o  ),
    .sel_o           ( sel_o ),
    .stb_o           ( stb_o ),
    .cyc_i           ( cyc_i ),
    .cyc_o           ( cyc_o ),
    .ack_i           ( ack_i ),
    .cti_o           ( cti_o ),

    // packet interface
    .transfer_address( address        ),
    .payload_in      ( payload_in     ),
    .payload_out     ( payload_out    ),
    .payload_length  ( payload_length ),
    .start_read      ( start_read     ),
    .read_busy       ( read_busy      ),
    .start_write     ( start_write    ),
    .write_busy      ( write_busy     ),
    .completed       ( completed      ),
    .timeout         ( timeout        )
  );
  assign debug = { payload_in[7:0], start_write, write_busy, completed, timeout };


  localparam MS_PERIOD = CLOCK_MHZ * 1000;
  localparam MS_COUNTER_LENGTH = $clog2(MS_PERIOD+1);

  reg [MS_COUNTER_LENGTH-1:0] ms_counter;
  reg [15:0]                  current_time;
  reg                         ms_pulse;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      ms_counter   <= MS_PERIOD;
      current_time <= 0;
    end
    else begin
      if (ms_counter) begin
        ms_counter <= ms_counter - 1;
        ms_pulse   <= 0;
      end
      else begin
        ms_counter   <= MS_PERIOD;
        current_time <= current_time + 1;
        ms_pulse     <= 1;
      end
    end
  end

  reg last_frame_complete;
  reg frame_pulse;
  always @(posedge clk) begin
    last_frame_complete = frame_complete;
    
    if (last_frame_complete != frame_complete && frame_complete) frame_pulse <= 1;
    else                                                         frame_pulse <= 0;
  end
  

  
  reg now_active;
  reg next_now_active;
  reg frames_active;
  reg next_frames_active;
  reg time_active;
  reg next_time_active;
  reg volume_list_active;
  reg next_volume_list_active;
  reg boop_active;
  reg next_boop_active;
  
  reg [7:0]  now_next_frame;
  reg [7:0]  next_now_next_frame;
  reg [7:0]  frames_next_frame;
  reg [7:0]  next_frames_next_frame;
  reg [7:0]  time_next_frame;
  reg [7:0]  next_time_next_frame;
  reg [7:0]  volume_list_frame_base;
  reg [7:0]  next_volume_list_frame_base;
  reg [7:0]  boop_next_frame;
  reg [7:0]  next_boop_next_frame;
  reg [15:0] frames_value;
  reg [15:0] next_frames_value;
  reg [15:0] time_value;
  reg [15:0] next_time_value;
  reg [15:0] volume_list_value;
  reg [15:0] next_volume_list_value;

  localparam STATE_LOAD_MEM            = 10'b0000000001;
  localparam STATE_LOAD_MEM_COMPLETE   = 10'b0000000010;
  localparam STATE_LOAD_START          = 10'b0000000100;
  localparam STATE_LOAD_START_COMPLETE = 10'b0000001000;
  localparam STATE_LOAD_RUN            = 10'b0000010000;
  localparam STATE_CHANGE_FRAME        = 10'b0000100000;
  localparam STATE_CHANGE_COMPLETE     = 10'b0001000000;
  localparam STATE_HEADER_REQ          = 10'b0010000000;
  localparam STATE_HEADER_RCV          = 10'b0100000000;
  localparam STATE_WAITING             = 10'b1000000000;
  
  reg [9:0] state;
  reg [9:0] next_state;

  reg [15:0] frame_address;
  reg [15:0] next_frame_address;
  reg [5:0]  frame_header_address;
  reg [5:0]  next_frame_header_address;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state                <= STATE_LOAD_MEM;
      frame_address        <= BASE_FRAME_ADDR;
      payload_length       <= 0;
      address              <= 0;
      payload_in           <= 0;
      frame_header_address <= 0;
    end
    else begin
      state                  <= next_state;
      frame_address          <= next_frame_address;
      payload_length         <= next_payload_length;
      address                <= next_address;
      payload_in             <= next_payload_in;
      frame_header_address   <= next_frame_header_address;
      time_value             <= next_time_value;
      frames_value           <= next_frames_value;

      now_active             <= next_now_active;
      frames_active          <= next_frames_active;
      time_active            <= next_time_active;
      volume_list_active     <= next_volume_list_active;
      boop_active            <= next_boop_active;
      now_next_frame         <= next_now_next_frame;
      frames_next_frame      <= next_frames_next_frame;
      time_next_frame        <= next_time_next_frame;
      volume_list_frame_base <= next_volume_list_frame_base;
      boop_next_frame        <= next_boop_next_frame;
      volume_list_value      <= next_volume_list_value;
    end
  end

  always @(*) begin
    next_state                  = state;
    next_frame_address          = frame_address;
    next_payload_length         = payload_length;
    next_address                = address;
    next_payload_in             = payload_in;
    next_frame_header_address   = frame_header_address;
    next_time_value             = time_value;
    next_frames_value           = frames_value;
    next_now_active             = now_active;
    next_frames_active          = frames_active;
    next_time_active            = time_active;
    next_volume_list_active     = volume_list_active;
    next_boop_active            = boop_active;
    next_now_next_frame         = now_next_frame;
    next_frames_next_frame      = frames_next_frame;
    next_time_next_frame        = time_next_frame;
    next_volume_list_frame_base = volume_list_frame_base;
    next_boop_next_frame        = boop_next_frame;
    next_volume_list_value      = volume_list_value;

    start_write                 = 0;
    start_read                  = 0;
    
    case(state)
    STATE_LOAD_MEM: begin
      next_address           = `FRAME_MEMORY_START + `VIDMEM_READ_ADDR;
      next_payload_in[15:0]  = DATAPART_START / 256;
      next_payload_in[31:16] = 127;
      next_payload_length    = 4;
      next_state             = STATE_LOAD_MEM_COMPLETE;
    end
    
    STATE_LOAD_MEM_COMPLETE: begin
      start_write = 1;
      if (timeout | completed) begin
        next_state           = STATE_LOAD_START;
      end
    end

    STATE_LOAD_START: begin
      next_address         = `FRAME_MEMORY_START + `VIDMEM_CONTROL;
      next_payload_in[7:0] = 1;
      next_payload_length  = 1;
      next_state           = STATE_LOAD_START_COMPLETE;
    end

    STATE_LOAD_START_COMPLETE: begin
      if (!(timeout | completed)) start_write = 1;
      else                        start_write = 0;
      
      if (mem_busy) begin
        next_state = STATE_CHANGE_FRAME;
      end
    end
    STATE_LOAD_RUN: begin
      if (!mem_busy) begin
        next_state = STATE_CHANGE_FRAME;
      end
    end
    
    STATE_CHANGE_FRAME: begin
      next_address          = LED_MATRIX_ADDR + LED_MATRIX_REG_ADDR;
      next_payload_in[15:0] = frame_address + HEADER_SIZE;
      next_payload_length   = 2;

      next_now_active            = 0;
      next_frames_active         = 0;
      next_time_active           = 0;      
      next_volume_list_active    = 0;
      next_boop_active           = 0;
      
      next_state            = STATE_CHANGE_COMPLETE;
    end

    STATE_CHANGE_COMPLETE: begin
      start_write = 1;
      if (timeout | completed) begin
        next_address              = frame_address;
        next_frame_header_address = frame_address;
        
        next_state                = STATE_HEADER_REQ;
      end
    end
    
    STATE_HEADER_REQ: begin
      next_address        = frame_header_address;
      next_payload_length = 4;

      next_state          = STATE_HEADER_RCV;
    end

    STATE_HEADER_RCV: begin
      start_read = 1;
      if (timeout | completed) begin
        case (payload_out[7:0])
        8'h00: begin next_now_active         = 1; next_now_next_frame         = payload_out[15:8]; end
        8'h01: begin next_frames_active      = 1; next_frames_next_frame      = payload_out[15:8]; next_frames_value      = payload_out[31:16]; end
        8'h02: begin next_time_active        = 1; next_time_next_frame        = payload_out[15:8]; next_time_value        = payload_out[31:16]; end
        8'h03: begin next_volume_list_active = 1; next_volume_list_frame_base = payload_out[15:8]; next_volume_list_value = payload_out[31:16]; end
        8'h04: begin next_boop_active        = 1; next_boop_next_frame        = payload_out[15:8]; end
        endcase

        next_frame_header_address = frame_header_address + 4;

        if (|payload_out) next_state = STATE_HEADER_REQ;
        else              next_state = STATE_WAITING;
      end
    end

    STATE_WAITING: begin
      // if now, immediately change to the given frame
      if (now_active) begin
        next_frame_address = BASE_FRAME_ADDR + { now_next_frame, 10'd0 };
        next_state         = STATE_CHANGE_FRAME;
      end

      // if time, wait until time has ellapsed
      if (time_active && ms_pulse) begin
        if (time_value) next_time_value = time_value - 1;
        else begin
          next_frame_address = BASE_FRAME_ADDR + { time_next_frame, 10'd0 };
          next_state         = STATE_CHANGE_FRAME;
        end
      end

      // once a certain number of frames is shown, switch frames
      if (frames_active && frame_pulse) begin
        if (frames_value) next_frames_value = frames_value - 1;
        else begin
          next_frame_address = BASE_FRAME_ADDR + { frames_next_frame, 10'd0 };
          next_state         = STATE_CHANGE_FRAME;
        end
      end

      // on a new frame, reselect which frame to use
      if (volume_list_active && frame_pulse) begin
        if (volume_list_value == 1) next_frame_address = BASE_FRAME_ADDR + { (volume_list_frame_base + volume_in[3]), 10'd0 };
        if (volume_list_value == 2) next_frame_address = BASE_FRAME_ADDR + { (volume_list_frame_base + volume_in[3:2]), 10'd0 };
        if (volume_list_value == 3) next_frame_address = BASE_FRAME_ADDR + { (volume_list_frame_base + volume_in[3:1]), 10'd0 };
        else                        next_frame_address = BASE_FRAME_ADDR + { (volume_list_frame_base + volume_in[3:0]), 10'd0 };

        next_state = STATE_CHANGE_FRAME;
      end
    end
    
    default:
        next_state = STATE_CHANGE_FRAME;
    endcase
  end

  //wire [INTERFACE_WIDTH-1:0] payload_out = 0;
  //reg [ADDRESS_WIDTH-1:0]    address = 0;
  //reg [ADDRESS_WIDTH-1:0]    next_address;
  //reg [INTERFACE_WIDTH-1:0]  payload_in;
  //reg [INTERFACE_WIDTH-1:0]  next_payload_in;
  //reg                        start_read  = 0;
  //wire                       read_busy;
  //reg                        start_write = 0;
  //wire                       write_busy;
  //wire                       completed;
  //wire                       timeout;

  
endmodule
