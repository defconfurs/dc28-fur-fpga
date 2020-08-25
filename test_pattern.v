`include "globals.vh"

module test_pattern #(
  parameter ADDRESS_WIDTH   = 16,
  parameter DATA_WIDTH      = 16,
  parameter DATA_BYTES      = 2,
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
  output wire [2:0]               cti_o,
  
  output wire [15:0]               debug
  );

  wire rst;
  wire clk;
  assign clk = clk_i;
  assign rst = rst_i;
  
  localparam MAX_PAYLOAD = 2;
  localparam INTERFACE_WIDTH = DATA_WIDTH;
  
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
    .MAX_PAYLOAD   (1)
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
    .transfer_address( next_address   ),
    .payload_in      ( payload_in     ),
    .payload_out     (                ),
    .payload_length  ( 1              ),
    .start_read      ( 0              ),
    .read_busy       (                ),
    .start_write     ( start_write    ),
    .write_busy      ( write_busy     ),
    .completed       ( completed      ),
    .timeout         ( timeout        )
  );
  assign debug = { payload_in[7:0], start_write, write_busy, completed, timeout, 1'b0 };
  

  localparam FRAME_DELAY_START = 24'd100;
  localparam FRAME_TIME        = 24'd2400000;
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
  localparam colour_orange = 16'hF300;
  localparam colour_yellow = 16'hF5E0;
  localparam colour_green  = 16'h07C0;
  localparam colour_blue   = 16'h001F;
  localparam colour_purple = 16'h7817;

  localparam SAVE_STATE_CH_VALUES          = 7'b0000001;
  localparam SAVE_STATE_LATCH_DELAY        = 7'b0000010;
  localparam SAVE_STATE_START_REQUEST      = 7'b0000100;
  localparam SAVE_STATE_COMPLETE_REQUEST   = 7'b0001000;
  localparam SAVE_STATE_UPDATE_FB_REQUEST  = 7'b0010000;
  localparam SAVE_STATE_UPDATE_FB_COMPLETE = 7'b0100000;
  localparam SAVE_STATE_WAIT               = 7'b1000000;
  reg [6:0] save_state = SAVE_STATE_WAIT;
  reg [6:0] next_save_state;
  
  reg [5:0] offset = 1;
  reg [5:0] next_offset;

  reg [7:0] row;
  reg [7:0] next_row;
  reg [7:0] col;
  reg [7:0] inv_col;
  reg [7:0] next_col;
  reg [7:0] next_inv_col;
  reg [4:0] colour;
  reg [4:0] next_colour;
  reg       mirror;
  reg       next_mirror;
  reg       page;
  reg       next_page;

  always @(*) begin
    next_save_state = save_state;
    next_row        = row;
    next_col        = col;
    next_inv_col    = inv_col;
    next_colour     = colour;
    next_offset     = offset;
    next_payload_in = payload_in;
    next_address    = address;
    next_mirror     = mirror;
    next_page       = page;

    start_write     = 0;
               
    case (save_state)
    SAVE_STATE_CH_VALUES: begin
      //if (row == 5 && col == 5) next_payload_in = 16'hFFFF;
      //else                      next_payload_in = 0;
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
        next_address = (FRAME_ADDRESS + 
                          {5'd0, row[3:0], inv_col[4:0]}) + (page ? 16'h0400 : 16'h0000);
      end
      else begin
        next_address = (FRAME_ADDRESS + 
                          {5'd0, row[3:0], col[4:0]}) + (page ? 16'h0400 : 16'h0000);
      end
      
      next_save_state = SAVE_STATE_LATCH_DELAY;
    end

    SAVE_STATE_LATCH_DELAY: begin
      next_save_state = SAVE_STATE_START_REQUEST;
    end

    SAVE_STATE_START_REQUEST: begin
      start_write = 1;

      if (timeout)        next_save_state = SAVE_STATE_CH_VALUES;
      else if (completed) next_save_state = SAVE_STATE_COMPLETE_REQUEST;
    end

    SAVE_STATE_COMPLETE_REQUEST: begin
      next_mirror     = ~mirror;
      next_save_state = SAVE_STATE_CH_VALUES;
      
      if (mirror) begin
        if (col >= 9) begin
          if (row >= 14) begin
            next_save_state = SAVE_STATE_UPDATE_FB_REQUEST;
            if (offset >= 8'd22)
                next_offset = 0;
            else
                next_offset = offset + 2;
          end
          else begin
            next_col = 0;
            next_inv_col = 19;
            next_row = row + 1;

            if (offset + row >= 24)
                next_colour = offset + row - 24;
            else 
                next_colour = offset + row;
          end
        end
        else begin
          next_col = col + 1;
          next_inv_col = inv_col - 1;

          if (colour < (5'd24)) next_colour = colour + 1;
          else                  next_colour = 0;
        end
      end
    end

    SAVE_STATE_UPDATE_FB_REQUEST: begin
      next_address    = `MATRIX_START;
      next_payload_in = { (FRAME_ADDRESS + (page ? 16'h0400 : 16'h0000)), 1'b0 };
      next_page   = ~page;
      
      next_save_state = SAVE_STATE_UPDATE_FB_COMPLETE;
    end

    SAVE_STATE_UPDATE_FB_COMPLETE: begin
      start_write = 1;
      if (timeout || completed) 
          next_save_state = SAVE_STATE_WAIT;
    end
    
    
    SAVE_STATE_WAIT: begin
      next_row    = 0;
      next_col    = 0;
      next_inv_col = 19;
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
      inv_col    <= 19;
      address    <= 0;
      colour     <= 0;
      offset     <= 0;
      payload_in <= 0;
      address    <= BASE_ADDRESS;
      mirror     <= 0;
      page       <= 0;
    end
    else begin
      save_state <= next_save_state;
      row        <= next_row;
      col        <= next_col;
      inv_col    <= next_inv_col;
      address    <= next_address;
      colour     <= next_colour;
      offset     <= next_offset;
      payload_in <= next_payload_in;
      address    <= next_address;
      mirror     <= next_mirror;
      page       <= next_page;
    end
  end
  
  
  
endmodule
