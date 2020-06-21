`include "globals.v"

module test_pattern #(
  parameter ADDRESS_WIDTH   = 16,
  parameter DATA_WIDTH      = 8,
  parameter DATA_BYTES      = 1,
  parameter BASE_ADDRESS    = 0,
  parameter MAX_WAIT        = 8,
  parameter FRAME_ADDRESS   = 0
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
  output wire [2:0]               cti_o
  );

  wire rst;
  wire clk;
  assign clk = clk_i;
  assign rst = rst_i;
  
  localparam MAX_PAYLOAD = 2;
  localparam INTERFACE_WIDTH = 3 * DATA_WIDTH;
  
  wire [INTERFACE_WIDTH-1:0] payload_out = 0;
  reg [ADDRESS_WIDTH-1:0]    address = 0;
  reg [ADDRESS_WIDTH-1:0]    next_address;
  reg [INTERFACE_WIDTH-1:0]  payload_in;
  reg [INTERFACE_WIDTH-1:0]  next_payload_in;
  reg                        start_read  = 0;
  wire                       read_busy;
  reg                        start_write = 0;
  wire                       write_busy;
  wire                       completed;
  wire                       timeout;

  wishbone_master #(
    .ADDRESS_WIDTH (ADDRESS_WIDTH),
    .DATA_WIDTH    (DATA_WIDTH),
    .DATA_BYTES    (DATA_BYTES),
    .MAX_WAIT      (MAX_WAIT),
    .MAX_PAYLOAD   (3)
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
    .transfer_address( address  ),
    .payload_in      ( payload_in     ),
    .payload_out     (                ),
    .payload_length  ( 3              ),
    .start_read      ( 0              ),
    .read_busy       (                ),
    .start_write     ( start_write    ),
    .write_busy      ( write_busy     ),
    .completed       ( completed      ),
    .timeout         ( timeout        )
  );

  localparam FRAME_DELAY_START = 24'd100;
  localparam FRAME_TIME        = 24'd12000000;
  reg [23:0] frame_delay;
  reg        frame_trigger;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      frame_delay <= FRAME_DELAY_START;
      frame_trigger <= 0;
    end
    else begin
      if (frame_delay) begin
        frame_delay   <= frame_delay - 1;
        frame_trigger <= 0;
      end
      else begin
        frame_delay   <= FRAME_TIME;
        frame_trigger <= 1;
      end
    end
  end

  localparam colour_red    = 16'hF800;
  localparam colour_orange = 16'hE524;
  localparam colour_yellow = 16'hFFE0;
  localparam colour_green  = 16'h1680;
  localparam colour_blue   = 16'h20FF;
  localparam colour_purple = 16'hD016;

  localparam SAVE_STATE_CH_VALUES         = 5'b0001;
  localparam SAVE_STATE_START_REQUEST     = 5'b0010;
  localparam SAVE_STATE_COMPLETE_REQUEST  = 5'b0100;
  localparam SAVE_STATE_WAIT              = 5'b1000;
  reg [3:0] save_state = SAVE_STATE_WAIT;
  reg [3:0] next_save_state;
  
  reg [5:0] offset;
  reg [5:0] next_offset;

  reg [7:0] row;
  reg [7:0] next_row;
  reg [7:0] col;
  reg [7:0] next_col;
  reg [4:0] colour;
  reg [4:0] next_colour;
  reg       mirror;
  reg       next_mirror;

  always @(*) begin
    next_save_state = save_state;
    next_row        = row;
    next_col        = col;
    next_colour     = colour;
    next_offset     = offset;
    next_payload_in = payload_in;
    next_address    = address;
    next_mirror     = mirror;

    start_write     = 0;
               
    case (save_state)
    SAVE_STATE_CH_VALUES: begin
      case (colour[4:2])
      3'd0: begin  next_payload_in = colour_red; end
      3'd1: begin  next_payload_in = colour_orange; end
      3'd2: begin  next_payload_in = colour_yellow; end
      3'd3: begin  next_payload_in = colour_green; end
      3'd4: begin  next_payload_in = colour_blue;  end
      3'd5: begin  next_payload_in = colour_purple; end
      default:
          next_payload_in = 0;
      endcase

      if (mirror) begin
        next_address = FRAME_ADDRESS + (row << 5) + 19 - col;
      end
      else begin
        next_address = FRAME_ADDRESS + (row << 5) + col;
      end
      
      next_save_state = SAVE_STATE_START_REQUEST;
    end

    SAVE_STATE_START_REQUEST: begin
      start_write     = 1;

      if (timeout)        next_save_state = SAVE_STATE_CH_VALUES;
      else if (completed) next_save_state = SAVE_STATE_COMPLETE_REQUEST;
    end

    SAVE_STATE_COMPLETE_REQUEST: begin
      next_mirror     = ~mirror;
      next_save_state = SAVE_STATE_CH_VALUES;
      
      if (mirror) begin
        if (col >= 9) begin
          if (row >= 14) begin
            next_save_state = SAVE_STATE_WAIT;
            if (offset < 8'd24)
                next_offset = offset + 1;
            else
                next_offset = 0;
          end
          else begin
            next_col = 0;
            next_row = row + 1;

            if (offset + row >= 8'd24) 
                next_colour = offset + row - 8'd24;
            else 
                next_colour = offset + row;
          end
        end
        else begin
          next_col = col + 1;

          if (colour < (5'd24)) next_colour = colour + 1;
          else                  next_colour = 0;
        end
      end
    end
    
    SAVE_STATE_WAIT: begin
      next_row    = 0;
      next_col    = 0;
      next_colour = offset;

      if (frame_trigger) next_save_state = SAVE_STATE_CH_VALUES;
    end

    default:
        next_save_state = SAVE_STATE_WAIT;
    endcase
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      save_state <= SAVE_STATE_WAIT;
      row        <= 0;
      col        <= 0;
      address    <= 0;
      colour     <= 0;
      offset     <= 0;
      payload_in <= 0;
      address    <= BASE_ADDRESS;
      mirror     <= 0;
    end
    else begin
      save_state <= next_save_state;
      row        <= next_row;
      col        <= next_col;
      address    <= next_address;
      colour     <= next_colour;
      offset     <= next_offset;
      payload_in <= next_payload_in;
      address    <= next_address;
      mirror     <= next_mirror;
    end
  end
  
  
  
endmodule
