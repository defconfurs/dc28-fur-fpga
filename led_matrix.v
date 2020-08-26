`include "globals.vh"

module led_matrix #(
    parameter ADDRESS_WIDTH    = 30,
    parameter DATA_WIDTH       = 32,
    localparam DATA_BYTES      = DATA_WIDTH/8,
    parameter BASE_ADDRESS     = 0
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

  // LED Drive Out
  output reg [3:0]                latch_row_bank,
  output reg [7:0]                row_data,
  output wire                     row_oe,
  output wire                     col_first,
  output wire                     col_advance,
  output wire                     col_rclk,

  // extra control signals
  output wire                     frame_complete,
    
  input wire [15:0]               debug
  );

  wire [15:0] localdebug;
  
  localparam N_COLS             = 10;
  localparam N_ROWS             = 14;
  localparam SHIFT_CLOCK_PERIOD = 64;
  localparam TOTAL_LOAD_TIME    = 2 * N_COLS / 2;
  localparam TOTAL_LINE_TIME    = 'h400; // don't forget to update for the maximum PWM time

  localparam TOTAL_LOAD_TIME_SIZE = $clog2(TOTAL_LOAD_TIME+1);
  localparam TOTAL_LINE_TIME_SIZE = $clog2(TOTAL_LINE_TIME+1);

  localparam COL_STEP =  1*2;
  localparam ROW_STEP = 32*2;

  localparam N_COLS_SIZE = $clog2(N_COLS+1);
  localparam N_ROWS_SIZE = $clog2(N_ROWS+1);
  
  // alias so it's easier to type
  wire       clk;
  wire       rst;
  assign clk = clk_i;
  assign rst = rst_i;

  reg [31:0] led_out_state;


  localparam MEM_ADDR_WIDTH = 14;

  reg                       mem_busy;
  wire [MEM_ADDR_WIDTH-1:0] ram_address;
  wire [15:0]               ram_data_in;
  reg [15:0]                ram_data_out;
  wire                      ram_we;

  
  wire [MEM_ADDR_WIDTH-1:0] wb_mem_address;
  wire [15:0]               wb_mem_data_out;
  wire [15:0]               wb_mem_data_in;
  wire                      wb_mem_we;

  
  // control registers
  reg [MEM_ADDR_WIDTH-1:0] frame_address;
  reg [MEM_ADDR_WIDTH-1:0] latched_frame_address;

  assign localdebug = latched_frame_address;
  
  //===========================================================================================
  // Wishbone slave
  wire       address_in_range;
  assign address_in_range = adr_i == BASE_ADDRESS && |sel_i[1:0];

  wire [13:0] local_address;
  wire        upper_hword;
  assign upper_hword = !(|sel_i[1:0]);
  assign wb_mem_address = { adr_i[MEM_ADDR_WIDTH-1:0], upper_hword };
  
  wire       masked_cyc = (cyc_i);
  assign wb_mem_we = (stb_i & |we_i);
  assign wb_mem_data_in = upper_hword ? dat_i[31:16] : dat_i[15:0];

  always @(posedge clk_i) begin
    if (!address_in_range && mem_busy) ack_o = 0;
    else ack_o <= masked_cyc;
  end

  // note - this is hard-coded for only one register at address 0
  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      frame_address     <= `DEFAULT_FRAME_ADDRESS;
    end
    else begin
      if (masked_cyc & we_i & address_in_range) begin
        frame_address <= dat_i[MEM_ADDR_WIDTH+1-1:1];
      end
    end
  end

  // note - this is hard-coded for only one register at address 0
  always @(*) begin
    if (~masked_cyc)           dat_o = 0;
    else if (address_in_range) dat_o = { frame_address, 1'b0 };
    else                       dat_o = upper_hword ? { wb_mem_data_out, 16'd0 } : { 16'd0, wb_mem_data_out };
  end

  //===========================================================================================
  // Wishbone Master - Pixel Reader

  assign ram_data_in = 0;
  
  reg [MEM_ADDR_WIDTH-1:0]  raminst_address;
  reg [15:0]                raminst_data_in;
  wire [15:0]               raminst_data_out;
  reg [1:0]                 raminst_wen;
  always @(*) begin
    if (mem_busy) begin
      raminst_wen     = { ram_we, ram_we };
      raminst_data_in = ram_data_in;
      raminst_address = ram_address;
      ram_data_out    = raminst_data_out;
      wb_mem_data_out = 0;
    end
    else begin
      raminst_wen     = (sel_i[3:2] | sel_i[1:0]) & { DATA_BYTES { wb_mem_we }};
      raminst_data_in = wb_mem_data_in;
      raminst_address = wb_mem_address;
      wb_mem_data_out = raminst_data_out;
      ram_data_out    = 0;
    end
  end
  assign ram_we = 0;
  
  reg [MEM_ADDR_WIDTH-1:0]  latched_address;
  always @(posedge clk_i) latched_address <= raminst_address;
  SB_SPRAM256KA ram00
  (
    .ADDRESS    (raminst_address),
    .DATAIN     (raminst_data_in),
    .MASKWREN   ({raminst_wen[1], raminst_wen[1], raminst_wen[0], raminst_wen[0]}),
    .WREN       (raminst_wen[0] | raminst_wen[1]),
    .CHIPSELECT (1),
    .CLOCK      (clk_i),
    .STANDBY    (1'b0),
    .SLEEP      (1'b0),
    .POWEROFF   (1'b1),
    .DATAOUT    (raminst_data_out)
  );
  
  localparam FIELD_RED   = 3'b001;
  localparam FIELD_GREEN = 3'b010;
  localparam FIELD_BLUE  = 3'b100;
  reg [2:0] current_field = FIELD_BLUE;
  
  reg [5:0] pixel_out;

  always @(*) begin
    if (latched_frame_address == 0) pixel_out <= 0;
    else begin
      case (current_field)
      FIELD_RED:   pixel_out <= { raminst_data_out[15:11], 1'b0 };
      FIELD_GREEN: pixel_out <= { raminst_data_out[10:5] };
      FIELD_BLUE:  pixel_out <= { raminst_data_out[4:0], 1'b0 };
      default:     pixel_out <= { raminst_data_out[4:0], 1'b0 };
      endcase
    end
  end
  
  reg [N_ROWS_SIZE:0]          pixel_being_updated = 0;
  reg [N_COLS_SIZE-1:0]        current_col = 0;
  

  reg [TOTAL_LINE_TIME_SIZE-1:0]   col_timer = 0;
  reg [TOTAL_LOAD_TIME_SIZE-1:0]   load_timer = 0;

  //===========================================================================================
  // Nonlinear timer
  reg [7:0] brightness_lut_out;
  reg [7:0] brightness_lut_mem [63:0];

  reg [7:0] pwm_pos_timer;
  reg [5:0] pwm_pos;
  
  initial begin
    $readmemh("./brightness_lut_rom.txt", brightness_lut_mem);
  end
  
  always @(posedge clk) begin
    brightness_lut_out <= brightness_lut_mem[pwm_pos];
  end
  
  always @(posedge clk) begin
    if (col_timer) begin
      if (pwm_pos_timer) pwm_pos_timer <= pwm_pos_timer - 1;
      else if (pwm_pos < 63) begin
        pwm_pos <= pwm_pos + 1;
        pwm_pos_timer <= brightness_lut_out;
      end
    end
    else begin
      pwm_pos <= 0;
      pwm_pos_timer <= 1;
    end
  end
  
  
  //===========================================================================================
  // The matrix display
  

  localparam LOAD_STATE_START_REQUEST     = 5'b00001;
  localparam LOAD_STATE_REQUEST_DELAY     = 5'b00010;
  localparam LOAD_STATE_COMPLETE_REQUEST  = 5'b00100;
  localparam LOAD_STATE_GET_VALUE         = 5'b01000;
  localparam LOAD_STATE_LOAD_WAIT         = 5'b10000;
  reg [4:0] load_state = LOAD_STATE_START_REQUEST;

  wire [4:0] xpos;
  wire [3:0] ypos;
  assign xpos = { current_col, pixel_being_updated[0] };
  assign ypos = { pixel_being_updated[4:1] };

  assign ram_address = (latched_frame_address + 
                        { ypos, xpos[4:1], xpos[0]^ypos[0] });


  //==============================
  // PWM engine
  reg [5:0]  latched_pixels[0:(N_ROWS<<1)-1];
  wire       col_timer_active = |col_timer;
  reg        last_col_timer_active;
  integer pix_i;
  always @(posedge clk) begin
    last_col_timer_active <= col_timer_active;

    if (last_col_timer_active != col_timer_active && col_timer_active) begin
      for (pix_i = 0; pix_i < N_ROWS<<1; pix_i = pix_i+1) begin
        if (latched_pixels[pix_i] != 0) led_out_state[pix_i] <= 1;
      end
    end
    else if (col_timer) begin
      for (pix_i = 0; pix_i < N_ROWS<<1; pix_i = pix_i+1) begin
        if (latched_pixels[pix_i] == pwm_pos) led_out_state[pix_i] <= 0;
      end
    end
    else begin
      for (pix_i = 0; pix_i < N_ROWS<<1; pix_i = pix_i+1) begin
        led_out_state[pix_i] <= 0;
      end
    end
  end
  //==============================
  
  
  integer i;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      mem_busy              <= 0;
      col_timer             <= TOTAL_LINE_TIME;
      load_state            <= LOAD_STATE_START_REQUEST;
      current_field         <= FIELD_BLUE;
      current_col           <= 0;
      pixel_being_updated   <= 0;
      latched_frame_address <= 0;
      for (i = 0; i < N_ROWS<<1; i = i+1) latched_pixels[i] <= 0;
    end
    
    else begin
      if (col_timer) begin
        col_timer      <= col_timer - 1;
        
        load_timer     <= TOTAL_LOAD_TIME;
        mem_busy       <= 0;
        frame_complete <= 1;
      end
      else begin // new col
        if (load_timer) load_timer <= load_timer -1;
        frame_complete <= 0;
        
        case (load_state)
        LOAD_STATE_START_REQUEST: begin
          mem_busy       <= 1;
          frame_complete <= 0;
          load_state     <= LOAD_STATE_REQUEST_DELAY;
        end
        
        LOAD_STATE_REQUEST_DELAY: begin
          mem_busy   <= 1;
          load_state <= LOAD_STATE_COMPLETE_REQUEST;
        end
        
        LOAD_STATE_COMPLETE_REQUEST: begin
          mem_busy   <= 0;
          load_state <= LOAD_STATE_GET_VALUE;
        end
        
        LOAD_STATE_GET_VALUE: begin
          mem_busy <= 0;
          
          for (i = 0; i < N_ROWS<<1; i = i+1) begin
            if (i == pixel_being_updated) begin
              latched_pixels[i] <= pixel_out;
            end
          end
          
          if (pixel_being_updated < N_ROWS<<1) begin
            pixel_being_updated <= pixel_being_updated + 1;

            load_state          <= LOAD_STATE_START_REQUEST;
          end
          else begin
            pixel_being_updated <= 0;
            
            case(current_field)
            FIELD_BLUE:  begin  current_field <= FIELD_GREEN;  end
            FIELD_GREEN: begin  current_field <= FIELD_RED;    end
            FIELD_RED:   begin  current_field <= FIELD_BLUE;   end
            default:     begin  current_field <= FIELD_BLUE;   end
            endcase
            
            load_state <= LOAD_STATE_LOAD_WAIT;
          end
        end
        
        LOAD_STATE_LOAD_WAIT: begin
          mem_busy <= 0;

          if (!load_timer) begin
            load_state <= LOAD_STATE_START_REQUEST;
            load_timer <= TOTAL_LOAD_TIME;
            col_timer  <= TOTAL_LINE_TIME;
            
            if (current_field == FIELD_BLUE) begin
              if (current_col < N_COLS-1) begin
                current_col <= current_col + 1;
              end
              else begin
                current_col           <= 0;
                latched_frame_address <= frame_address;
                frame_complete        <= 1;
              end
            end
          end
        end
        
        endcase
      end
    end
  end

  localparam SHIFT_CLOCK_COUNTER_SIZE = $clog2(SHIFT_CLOCK_PERIOD+1);
  reg [SHIFT_CLOCK_COUNTER_SIZE-1:0] shift_clock_counter;
  
  wire state_is_load = (load_state != LOAD_STATE_LOAD_WAIT); // LOAD_STATE_LOAD_WAIT
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
      row_data       = led_out_state[7:0];//debug[7:0];//
      latch_row_bank = 4'b0000;
    end
    
    COL_LATCH_STATE_0L: begin
      row_data       = led_out_state[7:0];//debug[7:0];//
      latch_row_bank = 4'b0001;
    end
    
    COL_LATCH_STATE_1: begin
      row_data       = led_out_state[15:8];//debug[15:8];//
      latch_row_bank = 4'b0000;
    end
    
    COL_LATCH_STATE_1L: begin
      row_data       = led_out_state[15:8];//debug[15:8];//
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
      row_data       = led_out_state[31:24];
      latch_row_bank = 4'b0000;
    end
    
    COL_LATCH_STATE_3L: begin
      row_data       = led_out_state[31:24];
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
  assign col_first   = (current_col == 0) && (current_field == FIELD_BLUE);
  assign col_advance = shift_clock_counter < (SHIFT_CLOCK_PERIOD >> 4) && shift_clock_counter > 0;
  assign col_rclk    = shift_clock_counter > (SHIFT_CLOCK_PERIOD >> 4) && shift_clock_counter > 0;
  
  
endmodule
