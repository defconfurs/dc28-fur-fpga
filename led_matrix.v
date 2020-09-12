`include "globals.vh"

module led_matrix #(
    parameter AW = 32,
    parameter DW = 32,
    parameter CLK_FREQ = 12000000
)  (
    // Wishbone interface.
    input wire            wb_clk_i,
    input wire            wb_reset_i,
    input wire [AW-1:0]   wb_adr_i,
    input wire [DW-1:0]   wb_dat_i,
    output reg [DW-1:0]   wb_dat_o,
    input wire            wb_we_i,
    input wire [DW/8-1:0] wb_sel_i,
    output reg            wb_ack_o,
    input wire            wb_cyc_i,
    input wire            wb_stb_i,

    // LED Drive Out
    output wire [3:0]     latch_row_bank,
    output reg [7:0]      row_data,
    output wire           row_oe,
    output wire           col_first,
    output wire           col_advance,
    output wire           col_rclk,

    // extra control signals
    output reg            frame_complete,
    
    input wire [15:0]     debug
    );

    reg ram_ready;
    
    ///////////////////////////////////////
    // The SRAM memory block.
    ///////////////////////////////////////
    wire   stb_valid;
    assign stb_valid = wb_cyc_i && wb_stb_i && ~wb_ack_o;
    wire   ram_stb_valid;
    assign ram_stb_valid = wb_adr_i != 0 && ram_ready & stb_valid;
    
    always @(posedge wb_clk_i) begin
        if (wb_adr_i == 0) wb_ack_o <= stb_valid;
        else               wb_ack_o <= ram_stb_valid;
    end
    
    wire   write_cycle;
    assign write_cycle = stb_valid | wb_we_i;

    reg [14:0] frame_address;
    reg [14:0] latched_frame_address;

    wire [31:0] raminst_data_out;
    reg [31:0]  raminst_data_in;
    reg [13:0]  raminst_address;
    reg [7:0]   raminst_maskwen;

    wire [14:0] ram_address;
    wire [15:0] ram_data_in;
    reg [15:0]  ram_data_out;
    
    always @(*) begin
        if (ram_ready) begin
            raminst_maskwen = ({ wb_sel_i[3], wb_sel_i[3], wb_sel_i[2], wb_sel_i[2], wb_sel_i[1], wb_sel_i[1], wb_sel_i[0], wb_sel_i[0] } & { (2*DW/8) { wb_we_i }});
            raminst_data_in = wb_dat_i;
            raminst_address = wb_adr_i[13:0];
            wb_dat_o        = wb_adr_i == 0 ? {frame_address != latched_frame_address, 15'd0,  frame_address, 1'b0 } : raminst_data_out;
            ram_data_out    = 16'h001F;
        end
        else begin
            raminst_maskwen = 8'hFF;
            raminst_data_in = 0;
            raminst_address = ram_address[14:1];
            ram_data_out    = ram_address[0] ? raminst_data_out[31:16] : raminst_data_out[15:0];
            wb_dat_o        = wb_adr_i == 0 ? {frame_address != latched_frame_address, 15'd0,  frame_address, 1'b0 } : 0;;
        end
    end

    always @(posedge wb_clk_i or posedge wb_reset_i) begin
        if (wb_reset_i) frame_address <= `DEFAULT_FRAME_ADDRESS;
        else if (wb_adr_i == 0 && stb_valid && wb_we_i) begin
            frame_address <= wb_dat_i[15:1];
        end
    end

  
    SB_SPRAM256KA ramfn_inst1 (
        .CLOCK      ( wb_clk_i ),
        .STANDBY    (1'b0),
        .SLEEP      (1'b0),
        .POWEROFF   (1'b1),
    
        .ADDRESS    ( raminst_address ),
        .DATAIN     ( raminst_data_in[15:0] ),
        .MASKWREN   ( raminst_maskwen[3:0] ),
        .WREN       ( (wb_sel_i[1] | wb_sel_i[0]) && wb_we_i && ram_stb_valid ),
        .CHIPSELECT ( 1 ),
        .DATAOUT    ( raminst_data_out[15:0] )
    );
  
    SB_SPRAM256KA ramfn_inst2 (
        .CLOCK      ( wb_clk_i ),
        .STANDBY    (1'b0),
        .SLEEP      (1'b0),
        .POWEROFF   (1'b1),
     
        .ADDRESS    ( raminst_address ),
        .DATAIN     ( raminst_data_in[31:16] ),
        .MASKWREN   ( raminst_maskwen[7:4] ),
        .WREN       ( (wb_sel_i[3] | wb_sel_i[2]) && wb_we_i && ram_stb_valid ),
        .CHIPSELECT ( 1 ),
        .DATAOUT    ( raminst_data_out[31:16] )
    );



    localparam N_COLS             = 10;
    localparam N_ROWS             = 14;
    localparam SHIFT_CLOCK_FREQ   = 200000;
    localparam SHIFT_CLOCK_PERIOD = (CLK_FREQ / SHIFT_CLOCK_FREQ);
    localparam TOTAL_LOAD_TIME    = 2 * N_COLS / 2;
    localparam TOTAL_LINE_TIME    = 'h400; // don't forget to update for the maximum PWM time

    localparam TOTAL_LOAD_TIME_SIZE = TOTAL_LOAD_TIME > TOTAL_LINE_TIME ? $clog2(TOTAL_LOAD_TIME+1) : $clog2(TOTAL_LINE_TIME+1);

    localparam N_COLS_SIZE = $clog2(N_COLS+1);
    localparam N_ROWS_SIZE = $clog2(N_ROWS+1);
  
    // alias so it's easier to type
    wire       clk;
    wire       rst;
    assign clk = wb_clk_i;
    assign rst = wb_reset_i;

    reg [27:0] led_out_state;




    localparam LOAD_STATE_START_REQUEST     = 5'b00001;
    localparam LOAD_STATE_COMPLETE_REQUEST  = 5'b00010;
    localparam LOAD_STATE_GET_VALUE         = 5'b00100;
    localparam LOAD_STATE_LOAD_WAIT         = 5'b01000;
    localparam LOAD_STATE_DISPLAY           = 5'b10000;
    reg [4:0] load_state = LOAD_STATE_START_REQUEST;
    
    

    //===========================================================================================
    // Pixel Reader
  
    localparam FIELD_RED   = 3'b001;
    localparam FIELD_GREEN = 3'b010;
    localparam FIELD_BLUE  = 3'b100;
    reg [2:0] current_field = FIELD_BLUE;
  
    reg [5:0] pixel_out;

    always @(*) begin
        if (latched_frame_address == 0) pixel_out = 0;
        else begin
            case (current_field)
            FIELD_RED:   pixel_out = { ram_data_out[15:11], 1'b0 };
            FIELD_GREEN: pixel_out = { ram_data_out[10:5] };
            FIELD_BLUE:  pixel_out = { ram_data_out[4:0], 1'b0 };
            default:     pixel_out = { ram_data_out[4:0], 1'b0 };
            endcase
        end
    end
  
    reg [N_ROWS_SIZE:0]   pixel_being_updated = 0;
    reg [N_COLS_SIZE-1:0] current_col = 0;
  

    reg [TOTAL_LOAD_TIME_SIZE-1:0] load_timer = 0;

    //===========================================================================================
    // Nonlinear timer
    reg [4:0] brightness_lut_out;
    reg [7:0] brightness_lut_mem [63:0];

    reg [4:0] pwm_pos_timer;
    reg [5:0] pwm_pos;
  
    initial begin
        $readmemh("./brightness_lut_rom.txt", brightness_lut_mem);
    end
  
    always @(posedge clk) begin
        brightness_lut_out <= brightness_lut_mem[pwm_pos][4:0];
    end
  
    always @(posedge clk) begin
        if (load_state == LOAD_STATE_DISPLAY) begin
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
    

    wire [4:0] xpos;
    wire [3:0] ypos;
    assign xpos = { current_col, pixel_being_updated[0] };
    assign ypos = { pixel_being_updated[4:1] };

    wire [31:0] dsp_output;
    
    SB_MAC16 #(
        .NEG_TRIGGER              ( 0     ),
        .C_REG                    ( 0     ),
        .A_REG                    ( 0     ),
        .B_REG                    ( 0     ),
        .D_REG                    ( 0     ),
        .TOP_8x8_MULT_REG         ( 0     ),
        .BOT_8x8_MULT_REG         ( 0     ),
        .PIPELINE_16x16_MULT_REG1 ( 0     ),
        .PIPELINE_16x16_MULT_REG2 ( 0     ),
        .TOPOUTPUT_SELECT         ( 2'b00 ),
        .TOPADDSUB_LOWERINPUT     ( 2'b00 ),
        .TOPADDSUB_UPPERINPUT     ( 1     ),
        .TOPADDSUB_CARRYSELECT    ( 2'b00 ),
        .BOTOUTPUT_SELECT         ( 2'b00 ),
        .BOTADDSUB_LOWERINPUT     ( 2'b00 ),
        .BOTADDSUB_UPPERINPUT     ( 0     ),
        .BOTADDSUB_CARRYSELECT    ( 2'b00 ),
        .MODE_8x8                 ( 0     ),
        .A_SIGNED                 ( 0     ),
        .B_SIGNED                 ( 0     )
    ) addr_dsp (
        .CLK       ( clk ), // input
        .CE        ( 1 ), // input
        .A         ( latched_frame_address ), // input [15:0]
        .B         ( 0 ), // input [15:0]
        .C         ( { ypos[3:0], xpos[4:1], xpos[0]^ypos[0] } ), // input [15:0]
        .D         ( 0 ), // input [15:0]
        .AHOLD     ( 0 ), // input 
        .BHOLD     ( 0 ), // input 
        .CHOLD     ( 0 ), // input 
        .DHOLD     ( 0 ), // input 
        .IRSTTOP   ( 0 ), // input 
        .IRSTBOT   ( 0 ), // input 
        .ORSTTOP   ( 0 ), // input 
        .ORSTBOT   ( 0 ), // input 
        .OLOADTOP  ( 0 ), // input 
        .OLOADBOT  ( 0 ), // input 
        .ADDSUBTOP ( 0 ), // input 
        .ADDSUBBOT ( 0 ), // input 
        .OHOLDTOP  ( 0 ), // input
        .OHOLDBOT  ( 0 ), // input
        .CI        ( 0 ), // input
        .ACCUMCI   ( 0 ), // input
        .SIGNEXTIN ( 0 ), // input
        .O         ( dsp_output ), // output [31:0]
        .CO        (  ), // output
        .ACCUMCO   (  ), // output
        .SIGNEXTOUT(  )  // output
    );
    assign ram_address    = dsp_output[31:16];
    

    //==============================
    // PWM engine
    reg [5:0]  latched_pixels[0:(N_ROWS<<1)-1];
    wire       col_timer_active = load_state == LOAD_STATE_DISPLAY;
    reg        last_col_timer_active;
    integer    pix_i;
    always @(posedge clk) begin
        last_col_timer_active <= col_timer_active;
        
        if (last_col_timer_active != col_timer_active && col_timer_active) begin
            for (pix_i = 0; pix_i < N_ROWS<<1; pix_i = pix_i+1) begin
                if (latched_pixels[pix_i] != 0) led_out_state[pix_i] <= 1;
            end
        end
        else if (col_timer_active) begin
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
            ram_ready             <= 1;
            load_state            <= LOAD_STATE_START_REQUEST;
            current_field         <= FIELD_BLUE;
            current_col           <= 0;
            pixel_being_updated   <= 0;
            latched_frame_address <= 0;
            for (i = 0; i < N_ROWS<<1; i = i+1) latched_pixels[i] <= 0;

        end
    
        else begin
            if (load_timer) load_timer <= load_timer -1;
        
            case (load_state)
            LOAD_STATE_START_REQUEST: begin
                frame_complete <= 0;
                if (!ram_stb_valid) begin
                    load_state <= LOAD_STATE_COMPLETE_REQUEST;
                    ram_ready  <= 0;
                end
            end
            
            LOAD_STATE_COMPLETE_REQUEST: begin
                frame_complete <= 0;
                ram_ready      <= 0;
                load_state     <= LOAD_STATE_GET_VALUE;
            end
            
            LOAD_STATE_GET_VALUE: begin
                frame_complete <= 0;
                ram_ready      <= 1;
                
                for (i = 0; i < N_ROWS<<1; i = i+1) begin
                    if (i == pixel_being_updated) begin
                        latched_pixels[i] <= pixel_out;
                    end
                    else latched_pixels[i] <= latched_pixels[i];
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
                ram_ready      <= 1;
                frame_complete <= 0;
      
                if (!load_timer) begin
                    load_state          <= LOAD_STATE_DISPLAY;
                    load_timer          <= TOTAL_LINE_TIME;
                
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
      
            LOAD_STATE_DISPLAY: begin
                ram_ready      <= 1;
                frame_complete <= 1;
      
                if (load_timer == 0) begin
                    load_state          <= LOAD_STATE_START_REQUEST;
                    load_timer          <= TOTAL_LOAD_TIME;
                end
            end
            
            endcase
        end
    end

    localparam SHIFT_CLOCK_COUNTER_SIZE = $clog2(SHIFT_CLOCK_PERIOD+1);
    reg [SHIFT_CLOCK_COUNTER_SIZE-1:0] shift_clock_counter;
  
    wire state_is_load = (load_state != LOAD_STATE_LOAD_WAIT); // LOAD_STATE_LOAD_WAIT
    reg  last_state_is_load;
    always @(posedge clk) begin
        last_state_is_load <= state_is_load;
    
        if (state_is_load && !last_state_is_load) shift_clock_counter <= SHIFT_CLOCK_PERIOD;
        else if (shift_clock_counter) shift_clock_counter <= shift_clock_counter-1;
    end

    localparam COL_LATCH_STATE_0  = 4'b0001;
    localparam COL_LATCH_STATE_1  = 4'b0010;
    localparam COL_LATCH_STATE_2  = 4'b0100;
    localparam COL_LATCH_STATE_3  = 4'b1000;
    reg [3:0] col_latch_state;
    assign latch_row_bank = col_latch_state & {4{~clk}};

    always @(*) begin
        row_data       = 8'b000000;
        case (col_latch_state)
        COL_LATCH_STATE_0:  row_data = led_out_state[7:0];  //debug[7:0];//
        COL_LATCH_STATE_1:  row_data = led_out_state[15:8]; //debug[15:8];//
        COL_LATCH_STATE_2:  row_data = led_out_state[23:16];
        COL_LATCH_STATE_3:  row_data = {4'd0, led_out_state[27:24]};
        endcase
    end

    always @(posedge clk) begin
        col_latch_state <= { col_latch_state[2:0], (col_latch_state[2:0] == 0) };
    end

    assign row_oe      = 0;
    assign col_first   = (current_col == 0) && (current_field == FIELD_BLUE);
    assign col_advance = !shift_clock_counter[SHIFT_CLOCK_COUNTER_SIZE-1] && shift_clock_counter > 0;
    assign col_rclk    =  shift_clock_counter[SHIFT_CLOCK_COUNTER_SIZE-1] && shift_clock_counter > 0;
  
  
endmodule
