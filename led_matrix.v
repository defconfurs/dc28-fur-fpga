`include "globals.v"

module led_matrix #(
    parameter ADDRESS_WIDTH   = 16,
    parameter DATA_WIDTH      = 8,
    parameter DATA_BYTES      = 1,
    parameter BASE_ADDRESS    = 0,
    parameter MAX_WAIT        = 8
)  (
  // Wishbone interface
  input wire                      rst_i,
  input wire                      clk_i,

  input wire [ADDRESS_WIDTH-1:0]  adr_i,
  input wire [DATA_WIDTH-1:0]     dat_i,
  output reg [DATA_WIDTH-1:0]     dat_o,
  input wire                      we_i,
  input wire [DATA_BYTES-1:0]     sel_i,
  input wire                      stb_i,
  input wire                      cyc_i,
  output reg                      ack_o,
  input wire [2:0]                cti_i,

  // Wishbone master
  output wire [ADDRESS_WIDTH-1:0] frame_adr_o,
  input wire [DATA_WIDTH-1:0]     frame_dat_i,
  output wire [DATA_WIDTH-1:0]    frame_dat_o,
  output wire                     frame_we_o,
  output wire [DATA_BYTES-1:0]    frame_sel_o,
  output wire                     frame_stb_o,
  input wire                      frame_cyc_i,
  output wire                     frame_cyc_o,
  input wire                      frame_ack_i,
  output wire [2:0]               frame_cti_o,
  
  // LED Drive Out
  output reg [3:0]                latch_row_bank,
  output reg [7:0]                row_data,
  output wire                     row_oe,
  output wire                     col_first,
  output wire                     col_advance,
  output wire                     col_rclk
  );

  localparam N_COLS             = 30;
  localparam N_ROWS             = 28;
  localparam SHIFT_CLOCK_PERIOD = 32;
  localparam TOTAL_LOAD_TIME    = MAX_WAIT * N_COLS / 4;
  localparam TOTAL_LINE_TIME    = 16'h800; // don't forget to update for the maximum PWM time

  localparam COL_STEP =  1*2;
  localparam ROW_STEP = 64*2;
  
 
  // alias so it's easier to type
  wire       clk;
  wire       rst;
  assign clk = clk_i;
  assign rst = rst_i;

  reg [N_ROWS-1:0] led_out_state;
  

  // control registers
  reg [15:0] frame_address;
  reg [7:0]  global_brightness;
  reg        enabled;

  reg [3:0]        local_clock_div = 0;
  reg              local_clk_pulse = 0;
  always @(posedge clk) begin
    if (local_clock_div) begin
      local_clock_div <= local_clock_div - 1;
      local_clk_pulse <= 0;
    end
    else begin
      local_clock_div <= 7;
      local_clk_pulse <= 1;
    end
  end
  wire local_clk;
  assign local_clk = local_clock_div[3];
  
  //===========================================================================================
  // Wishbone slave
  reg        valid_address;
  
  wire       address_in_range;
  wire [3:0] local_address;
  assign address_in_range = (adr_i & 16'hFFF0) == BASE_ADDRESS;
  assign local_address = address_in_range ? adr_i[3:0] : 4'hF;
  wire       masked_cyc = (address_in_range & cyc_i);
  
  
  always @(posedge clk_i) begin
    ack_o <= cyc_i & valid_address;
  end
  
  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      frame_address     <= `DEFAULT_FRAME_ADDRESS;
      enabled           <= 1;
      global_brightness <= 8'hFF;
    end
    else begin
      if (masked_cyc & we_i) begin
        if      (local_address == `MATRIX_CONTROL    ) { enabled } <= dat_i[0];
        else if (local_address == `MATRIX_BRIGHTNESS ) { global_brightness } <= dat_i;
        else if (local_address == `MATRIX_ADDR_L     ) { frame_address[7:0] } <= dat_i;
        else if (local_address == `MATRIX_ADDR_H     ) { frame_address[15:8] } <= dat_i;
      end
    end
  end


  always @(*) begin
    if (~masked_cyc) begin valid_address = 0; dat_o = 0; end
    else if (local_address == `MATRIX_CONTROL    ) begin  valid_address = 1;  dat_o = { 7'd0, enabled }; end
    else if (local_address == `MATRIX_BRIGHTNESS ) begin  valid_address = 1;  dat_o = { global_brightness }; end
    else if (local_address == `MATRIX_ADDR_L     ) begin  valid_address = 1;  dat_o = { frame_address[7:0] }; end
    else if (local_address == `MATRIX_ADDR_H     ) begin  valid_address = 1;  dat_o = { frame_address[15:8] }; end
    else begin 
      valid_address = 0;
      dat_o = 0;
    end
  end

  //===========================================================================================
  // Wishbone Master - Pixel Reader
  localparam MAX_PAYLOAD = 2;
  localparam INTERFACE_WIDTH = 3 * DATA_WIDTH;
  
  reg [ADDRESS_WIDTH-1:0]      pixel_address = 0;
  wire [INTERFACE_WIDTH-1:0]   payload_out;
  reg                          start_read = 0;
  wire                         read_busy;
  wire                         completed;
  wire                         timeout;

  wishbone_master #(
    .ADDRESS_WIDTH (ADDRESS_WIDTH),
    .DATA_WIDTH    (DATA_WIDTH),
    .DATA_BYTES    (DATA_BYTES),
    .MAX_WAIT      (MAX_WAIT),
    .MAX_PAYLOAD   (3)
  ) wb_master (
    // Wishbone interface
    .rst_i           ( rst_i          ),
    .clk_i           ( clk_i          ),
    .adr_o           ( frame_adr_o    ),
    .dat_i           ( frame_dat_i    ),
    .dat_o           ( frame_dat_o    ),
    .we_o            ( frame_we_o     ),
    .sel_o           ( frame_sel_o    ),
    .stb_o           ( frame_stb_o    ),
    .cyc_i           ( frame_cyc_i    ),
    .cyc_o           ( frame_cyc_o    ),
    .ack_i           ( frame_ack_i    ),
    .cti_o           ( frame_cti_o    ),

    // packet interface
    .transfer_address( pixel_address  ),
    .payload_in      ( 0              ),
    .payload_out     ( payload_out    ),
    .payload_length  ( 3              ),
    .start_read      ( start_read     ),
    .read_busy       ( read_busy      ),
    .start_write     ( 0              ),
    .write_busy      (                ),
    .completed       ( completed      ),
    .timeout         ( timeout        )
  );
  
  localparam FIELD_RED   = 3'b001;
  localparam FIELD_GREEN = 3'b010;
  localparam FIELD_BLUE  = 3'b100;
  reg [2:0] current_field = FIELD_BLUE;

  
  reg [N_COLS_SIZE-1:0]        pixel_being_updated = 0;
  reg [N_ROWS_SIZE-1:0]        current_col = 0;
  
  //===========================================================================================
  // Select component

  // this both grabs the component of the 565 encoded value as well as
  // prepending it with the offset into the LUT for the field region
  reg [7:0] field_lut_addr = 0;
  always @(*) begin
    case (current_field)
    FIELD_RED:   field_lut_addr = { 2'b00, payload_out[4:0], 1'b0 };
    FIELD_GREEN: field_lut_addr = { 2'b01, payload_out[10:5] };
    FIELD_BLUE:  field_lut_addr = { 2'b10, payload_out[15:11], 1'b0 };
    default: field_lut_addr     = 8'd0;
    endcase
  end
  
  //===========================================================================================
  // Nonlinear lookup
  localparam PIXEL_TIMER_SIZE = 16;
  reg [15:0] brightness_lut_out;
  
  reg [PIXEL_TIMER_SIZE-1:0]  brightness_lut_mem [255:0];
  
  initial begin
    $readmemh("./brightness_lut_rom.txt", brightness_lut_mem);
  end
  
  always @(posedge clk) begin
    brightness_lut_out <= brightness_lut_mem[field_lut_addr];
  end
  
  
  //===========================================================================================
  // The matrix display
  localparam N_COLS_SIZE = (N_COLS < 4 ? 2 :
                            N_COLS < 8 ? 3 :
                            N_COLS < 16 ? 4 :
                            N_COLS < 32 ? 5 : 6);
  localparam N_ROWS_SIZE = (N_ROWS < 2 ? 1 :
                            N_ROWS < 4 ? 2 :
                            N_ROWS < 8 ? 3 :
                            N_ROWS < 16 ? 4 :
                            N_ROWS < 32 ? 5 : 6);
  
  reg [PIXEL_TIMER_SIZE-1:0]   col_timer = 0;
  reg [PIXEL_TIMER_SIZE-1:0]   load_timer = 0;
  reg [15:0]                   col_address_offset = 0;

  localparam LOAD_STATE_INC_COL           = 5'b00001;
  localparam LOAD_STATE_START_REQUEST     = 5'b00010;
  localparam LOAD_STATE_COMPLETE_REQUEST  = 5'b00100;
  localparam LOAD_STATE_GET_VALUE         = 5'b01000;
  localparam LOAD_STATE_LOAD_WAIT         = 5'b10000;
  reg [4:0] load_state = LOAD_STATE_INC_COL;

  //reg [PIXEL_TIMER_SIZE-1:0]   pixel_timers [0:N_ROWS-1];
  //reg [PIXEL_TIMER_SIZE+1-1:0] pixel_accum [0:N_ROWS-1];
  //integer pdm_i;
  //always @(posedge local_clk) begin
  //  for (pdm_i = 0; pdm_i < N_ROWS; pdm_i = pdm_i+1) begin
  //    if (col_timer) begin
  //      if (pixel_accum[pdm_i] + pixel_timers[pdm_i] >= TOTAL_LINE_TIME) begin
  //        pixel_accum[pdm_i]   <= pixel_accum[pdm_i] + pixel_timers[pdm_i] - TOTAL_LINE_TIME;
  //        led_out_state[pdm_i] <= 1;
  //      end
  //      else begin
  //        pixel_accum[pdm_i]   <= pixel_accum[pdm_i] + pixel_timers[pdm_i];
  //        led_out_state[pdm_i] <= 0;
  //      end
  //    end
  //    else begin
  //      pixel_accum[pdm_i] <= TOTAL_LINE_TIME-1;
  //      led_out_state[pdm_i] <= 0;
  //    end
  //  end
  //end

  reg [PIXEL_TIMER_SIZE-1:0]   pixel_timers [0:N_ROWS-1];
  reg [PIXEL_TIMER_SIZE-1:0]   pixel_timers_active [0:N_ROWS-1];
  integer pdm_i;
  always @(posedge clk) begin
      for (pdm_i = 0; pdm_i < N_ROWS; pdm_i = pdm_i+1) begin
          if (col_timer) begin
              if (pixel_timers_active[pdm_i]) begin
                  pixel_timers_active[pdm_i] <= pixel_timers_active[pdm_i] - 1;
                  led_out_state[pdm_i]       <= 1;
              end
              else begin
                  led_out_state[pdm_i] <= 0;
              end
          end
          else begin
              pixel_timers_active[pdm_i] <= pixel_timers[pdm_i];
              led_out_state[pdm_i] <= 0;
          end
      end
  end
  
  integer i;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      col_timer     <= 0;
      load_state    <= LOAD_STATE_INC_COL;
      current_field <= FIELD_BLUE;
      for (i = 0; i < N_ROWS; i = i+1) pixel_timers[i] <= 0;
    end
    
    else begin
      if (col_timer) begin
        col_timer <= col_timer - 1;
        
        load_timer <= TOTAL_LOAD_TIME;
      end
      else begin // new col
        if (load_timer) load_timer <= load_timer -1;
        
        case (load_state)
        LOAD_STATE_INC_COL: begin
          
          if (current_col) begin
            pixel_being_updated <= 0;
            start_read          <= 1;

            case(current_field)
            FIELD_BLUE:  current_field  <= FIELD_GREEN;
            FIELD_GREEN: current_field  <= FIELD_RED;
            FIELD_RED:   begin
              current_col        <= current_col - 1;
              current_field      <= FIELD_BLUE;
              col_address_offset <= col_address_offset + COL_STEP;
              pixel_address      <= frame_address + col_address_offset + COL_STEP;
            end
            default: current_field <= FIELD_BLUE;
            endcase
          end
          else begin
            pixel_address       <= frame_address;
            pixel_being_updated <= 0;
            start_read          <= 1;

            current_col        <= N_COLS - 1;
            col_address_offset <= 0;
            current_field      <= FIELD_BLUE;
          end

          
          load_state <= LOAD_STATE_START_REQUEST;
        end
        
        LOAD_STATE_START_REQUEST: begin
          start_read <= 1;
          
          if (read_busy) load_state <= LOAD_STATE_COMPLETE_REQUEST;
        end
        
        LOAD_STATE_COMPLETE_REQUEST: begin
          start_read <= 0;
          
          if (!read_busy) load_state <= LOAD_STATE_GET_VALUE;
        end
        
        LOAD_STATE_GET_VALUE: begin
          start_read <= 0;
          
          for (i = 0; i < N_ROWS; i = i+1) begin
            if (i == pixel_being_updated) begin
              pixel_timers[i] <= brightness_lut_out;
            end
          end
          
          if (pixel_being_updated < N_COLS) begin
            pixel_being_updated <= pixel_being_updated + 1;
            pixel_address       <= pixel_address + ROW_STEP;
            load_state          <= LOAD_STATE_START_REQUEST;
          end
          else begin
            load_state <= LOAD_STATE_LOAD_WAIT;
          end
        end
        
        LOAD_STATE_LOAD_WAIT: begin
          start_read <= 0;
          if (!load_timer) begin
            load_state <= LOAD_STATE_INC_COL;
            load_timer <= TOTAL_LOAD_TIME;
            col_timer  <= TOTAL_LINE_TIME;
          end
        end
        
        endcase
      end
    end
  end

  localparam SHIFT_CLOCK_COUNTER_SIZE = (SHIFT_CLOCK_PERIOD < 16 ? 4 :
                                         SHIFT_CLOCK_PERIOD < 32 ? 5 :
                                         SHIFT_CLOCK_PERIOD < 64 ? 6 :
                                         SHIFT_CLOCK_PERIOD < 128 ? 7 :
                                         SHIFT_CLOCK_PERIOD < 256 ? 8 : 9);
  reg [SHIFT_CLOCK_COUNTER_SIZE-1:0] shift_clock_counter;
  
  wire state_is_load = (load_state == LOAD_STATE_INC_COL); // LOAD_STATE_LOAD_WAIT
  reg last_state_is_load;    
  always @(posedge clk) begin
    last_state_is_load <= state_is_load;
    
    if (state_is_load && !last_state_is_load) shift_clock_counter <= SHIFT_CLOCK_PERIOD;
    else if (shift_clock_counter) shift_clock_counter <= shift_clock_counter-1;
  end

  localparam COL_LATCH_STATE_0  = 8'b00000001;
  localparam COL_LATCH_STATE_0L = 8'b00000010;
  localparam COL_LATCH_STATE_1  = 8'b00000100;
  localparam COL_LATCH_STATE_1L = 8'b00001000;
  localparam COL_LATCH_STATE_2  = 8'b00010000;
  localparam COL_LATCH_STATE_2L = 8'b00100000;
  localparam COL_LATCH_STATE_3  = 8'b01000000;
  localparam COL_LATCH_STATE_3L = 8'b10000000;
  reg [7:0] col_latch_state;
  reg [7:0] next_col_latch_state;

  //output reg [3:0]                latch_row_bank,
  //output reg [7:0]                row_data,

  always @(*) begin
    row_data       = 8'b000000;
    latch_row_bank = 4'b0000;
    
    case (col_latch_state)
    COL_LATCH_STATE_0: begin
      row_data       = led_out_state[7:0];
      latch_row_bank = 4'b0000;
    end
    
    COL_LATCH_STATE_0L: begin
      row_data       = led_out_state[7:0];
      latch_row_bank = 4'b0001;
    end
    
    COL_LATCH_STATE_1: begin
      row_data       = led_out_state[15:8];
      latch_row_bank = 4'b0000;
    end
    
    COL_LATCH_STATE_1L: begin
      row_data       = led_out_state[15:8];
      latch_row_bank = 4'b0010;
    end
    
    COL_LATCH_STATE_2: begin
      row_data       = led_out_state[23:16];
      latch_row_bank = 4'b0000;
    end
    
    COL_LATCH_STATE_2L: begin
      row_data       = led_out_state[23:16];
      latch_row_bank = 4'b0100;
    end
    
    COL_LATCH_STATE_3: begin
      row_data       = {4'b1111, led_out_state[27:24]};
      latch_row_bank = 4'b0000;
    end
    
    COL_LATCH_STATE_3L: begin
      row_data       = {4'b1111, led_out_state[27:24]};
      latch_row_bank = 4'b1000;
    end
    endcase
  end
      
  always @(posedge clk) begin
    case (col_latch_state)
    COL_LATCH_STATE_0:  col_latch_state <= COL_LATCH_STATE_0L;
    COL_LATCH_STATE_0L: col_latch_state <= COL_LATCH_STATE_1;
    COL_LATCH_STATE_1:  col_latch_state <= COL_LATCH_STATE_1L;
    COL_LATCH_STATE_1L: col_latch_state <= COL_LATCH_STATE_2;
    COL_LATCH_STATE_2:  col_latch_state <= COL_LATCH_STATE_2L;
    COL_LATCH_STATE_2L: col_latch_state <= COL_LATCH_STATE_3;
    COL_LATCH_STATE_3:  col_latch_state <= COL_LATCH_STATE_3L;
    COL_LATCH_STATE_3L: col_latch_state <= COL_LATCH_STATE_0;
    default:            col_latch_state <= COL_LATCH_STATE_0;
    endcase
  end

  assign row_oe      = 0;
  assign col_first   = ~(|current_col);
  assign col_advance = load_state == LOAD_STATE_INC_COL;
  assign col_rclk    = ~col_advance;//|shift_clock_counter;
  
  
endmodule
