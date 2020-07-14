`include "globals.vh"

module test_intensity #(
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
  output wire [2:0]               cti_o,

  input wire [3:0]               volume_in,
  input wire [3:0]               peak_in
  );

  wire rst;
  wire clk;
  assign clk = clk_i;
  assign rst = rst_i;
  
  localparam MAX_PAYLOAD = 2;
  localparam INTERFACE_WIDTH = 2 * DATA_WIDTH;
  
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
    .MAX_PAYLOAD   (2)
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
    .payload_length  ( 2              ),
    .start_read      ( 0              ),
    .read_busy       (                ),
    .start_write     ( start_write    ),
    .write_busy      ( write_busy     ),
    .completed       ( completed      ),
    .timeout         ( timeout        )
  );
  

  localparam FRAME_DELAY_START = 24'd100;
  localparam FRAME_TIME        = 24'd60000;
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
  localparam colour_grey   = 16'h60DF;

  localparam SAVE_STATE_CH_VALUES          = 7'b0000001;
  localparam SAVE_STATE_LATCH_DELAY        = 7'b0000010;
  localparam SAVE_STATE_START_REQUEST      = 7'b0000100;
  localparam SAVE_STATE_COMPLETE_REQUEST   = 7'b0001000;
  localparam SAVE_STATE_UPDATE_FB_REQUEST  = 7'b0010000;
  localparam SAVE_STATE_UPDATE_FB_COMPLETE = 7'b0100000;
  localparam SAVE_STATE_WAIT               = 7'b1000000;
  reg [6:0] save_state = SAVE_STATE_WAIT;
  reg [6:0] next_save_state;
  
  reg [7:0] row;
  reg [7:0] next_row;
  reg [7:0] col;
  reg [7:0] inv_col;
  reg [7:0] next_col;
  reg [7:0] next_inv_col;
  reg       mirror;
  reg       next_mirror;
  reg       page;
  reg       next_page;

  always @(*) begin
    next_save_state = save_state;
    next_row        = row;
    next_col        = col;
    next_inv_col    = inv_col;
    next_payload_in = payload_in;
    next_address    = address;
    next_mirror     = mirror;
    next_page       = page;

    start_write     = 0;
               
    case (save_state)
    SAVE_STATE_CH_VALUES: begin
      //if (row == 5 && col == 5) next_payload_in = 16'hFFFF;
      //else                      next_payload_in = 0;

      if (row[3:0] >= 4 && row[3:0] <= 10) begin
        if (col == (10-peak_in)) next_payload_in = colour_grey;
        else if (col < (10-volume_in)) next_payload_in = 0;
        else begin
          if (col > 6) next_payload_in = colour_green;
          else if (col > 3) next_payload_in = colour_orange;
          else next_payload_in = colour_red;
        end
      end
      else next_payload_in = 0;
      

      if (mirror) begin
        next_address = (FRAME_ADDRESS + {5'd0, row[3:0], inv_col[4:0], 1'b0}) + (page ? 16'h0400 : 16'h0000);
      end
      else begin
        next_address = (FRAME_ADDRESS + {5'd0, row[3:0], col[4:0], 1'b0}) + (page ? 16'h0400 : 16'h0000);
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
          end
          else begin
            next_col = 0;
            next_inv_col = 19;
            next_row = row + 1;
          end
        end
        else begin
          next_col = col + 1;
          next_inv_col = inv_col - 1;

        end
      end
    end

    SAVE_STATE_UPDATE_FB_REQUEST: begin
      next_address    = `MATRIX_START + `MATRIX_ADDR_L;
      next_payload_in = FRAME_ADDRESS + (page ? 16'h0400 : 16'h0000);
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
      payload_in <= next_payload_in;
      address    <= next_address;
      mirror     <= next_mirror;
      page       <= next_page;
    end
  end
  
  
  
endmodule
