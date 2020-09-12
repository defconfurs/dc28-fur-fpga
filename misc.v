`default_nettype none

module wb_misc #(
      parameter AW = 32,
      parameter DW = 32,
      parameter SAMPLE_DEPTH = 8
)    (
      // Wishbone interface.
      input wire                           wb_clk_i,
      input wire                           wb_reset_i,
      input wire [AW-1:0]                  wb_adr_i,
      input wire [DW-1:0]                  wb_dat_i,
      output reg [DW-1:0]                  wb_dat_o,
      input wire                           wb_we_i,
      input wire [DW/8-1:0]                wb_sel_i,
      output reg                           wb_ack_o,
      input wire                           wb_cyc_i,
      input wire                           wb_stb_i,

      // Controllable LEDs.
      output wire [2:0]                    leds,
      input wire [1:0]                     buttons,
      input wire signed [SAMPLE_DEPTH-1:0] audio,
      output wire                          irq
    );

    // Only use the LSB nibble for address decoding.
    wire [3:0]         reg_addr = wb_adr_i[3:0];

    // Locate the STB rising edge.
    wire stb_valid;
    assign stb_valid = wb_cyc_i && wb_stb_i && !wb_ack_o;
    always @(posedge wb_clk_i) wb_ack_o <= stb_valid;

    // Wishbone Register Addresses
    localparam REG_LED_RED      = 4'h0;
    localparam REG_LED_GREEN    = 4'h1;
    localparam REG_LED_BLUE     = 4'h2;
    localparam REG_BUTTONS      = 4'h3;
    localparam REG_MIC_DATA     = 4'h4;
    localparam REG_INT_ENABLE   = 4'h5;
    localparam REG_INT_STATUS   = 4'h6;
    // Connect up to the hardware DSP blocks.
    // Computes RESULT = (A * B) + ACCUM
    localparam REG_MUL_CTRL     = 4'h8;
    localparam REG_MUL_OP_A     = 4'hA;
    localparam REG_MUL_OP_B     = 4'hB;
    localparam REG_MUL_ACCUM    = 4'hC;
    localparam REG_MUL_XACCUM   = 4'hD; /* Extended accumulator - reserved for 64-bit support. */
    localparam REG_MUL_RESULT   = 4'hE;
    localparam REG_MUL_XRESULT  = 4'hF; /* Extended result - reserved for 64-bit support. */

    // Interrupt bits
    localparam REG_INTBIT_BT0_RISING = 0;
    localparam REG_INTBIT_BT0_FALLING = 1;
    localparam REG_INTBIT_BT1_RISING = 2;
    localparam REG_INTBIT_BT1_FALLING = 3;

    reg [3:0] btn_int_status = 0;

    wire [DW-1:0] dsp_mul_result;
    reg [3:0]  dsp_flags = 0;
    wire [3:0] dsp_status;

    ///////////////////////////////////////
    // Wishbone Registers.
    ///////////////////////////////////////
    reg [7:0]          reg_intensity[2:0];
    reg [3:0]          reg_int_enable = 0;
    reg [3:0]          reg_int_status = 0;
    assign irq = (reg_int_enable & reg_int_status) != 0;

    always @(posedge wb_clk_i) begin
        // Reset
        if (wb_reset_i) begin
            reg_intensity[0] <= 8'h00;
            reg_intensity[1] <= 8'h00;
            reg_intensity[2] <= 8'h00;
            reg_int_enable   <= 8'h00;
            reg_int_status   <= 8'h00;
        end
        // Register Write
        else if (stb_valid && wb_we_i && wb_sel_i[0]) begin
            case (reg_addr)
            REG_LED_RED:    reg_intensity[0] <= wb_dat_i[7:0];
            REG_LED_GREEN:  reg_intensity[1] <= wb_dat_i[7:0];
            REG_LED_BLUE:   reg_intensity[2] <= wb_dat_i[7:0];
            REG_INT_ENABLE: reg_int_enable   <= wb_dat_i[3:0];
            REG_INT_STATUS: reg_int_status   <= (reg_int_status & ~wb_dat_i[3:0]);
            REG_MUL_CTRL:   dsp_flags        <= wb_dat_i[7:4];
            endcase
        end
        // Update interrupt status
        else begin
            reg_int_status <= reg_int_status | btn_int_status;
        end

        // Register Read
        if (stb_valid && ~wb_we_i) begin
            wb_dat_o <= 0;
            case (reg_addr)
            REG_LED_RED:    wb_dat_o[   7:0] <= reg_intensity[0];
            REG_LED_GREEN:  wb_dat_o[   7:0] <= reg_intensity[1];
            REG_LED_BLUE:   wb_dat_o[   7:0] <= reg_intensity[2];
            REG_BUTTONS:    wb_dat_o[   1:0] <= buttons;
            REG_MIC_DATA:   wb_dat_o[DW-1:0] <= { {(DW-SAMPLE_DEPTH){audio[SAMPLE_DEPTH-1]}}, audio };
            REG_INT_ENABLE: wb_dat_o[   3:0] <= reg_int_enable;
            REG_INT_STATUS: wb_dat_o[   3:0] <= reg_int_status;
            REG_MUL_CTRL:   wb_dat_o[   7:0] <= { {(DW-8){1'b0}}, dsp_flags, dsp_status };
            REG_MUL_RESULT: wb_dat_o[DW-1:0] <= dsp_mul_result;
            default:        wb_dat_o <= 0;
            endcase
        end
    end

    ///////////////////////////////////////
    // PWM Generation
    ///////////////////////////////////////
    reg [15:0] pwm_counter = 0;
    always @(posedge wb_clk_i) pwm_counter <= pwm_counter + 1;

    assign leds[0] = (reg_intensity[0] > pwm_counter[7:0]);
    assign leds[1] = (reg_intensity[1] > pwm_counter[7:0]);
    assign leds[2] = (reg_intensity[2] > pwm_counter[7:0]);
    
    ///////////////////////////////////////
    // Button Edge Detector
    ///////////////////////////////////////
    // Lazy debouncing by using a really slow clock.
    reg [1:0] buttons_prev = 0;
    always @(posedge pwm_counter[15]) begin
        buttons_prev <= buttons;
        btn_int_status[REG_INTBIT_BT0_RISING]  <= ~buttons_prev[0] &&  buttons[0];
        btn_int_status[REG_INTBIT_BT0_FALLING] <=  buttons_prev[0] && ~buttons[0];
        btn_int_status[REG_INTBIT_BT1_RISING]  <= ~buttons_prev[1] &&  buttons[1];
        btn_int_status[REG_INTBIT_BT1_FALLING] <=  buttons_prev[1] && ~buttons[1];
    end

    ///////////////////////////////////////
    // Hardware Multiply Helper
    ///////////////////////////////////////
    wire mul_latch_a;
    wire mul_latch_b;
    wire mul_latch_cd;
    assign mul_latch_a = stb_valid && wb_we_i && (reg_addr == REG_MUL_OP_A);
    assign mul_latch_b = stb_valid && wb_we_i && (reg_addr == REG_MUL_OP_B);
    assign mul_latch_cd = stb_valid && wb_we_i && (reg_addr == REG_MUL_ACCUM);

    // Flags output by the DSP
    wire dsp_status_carry;
    assign dsp_status = {3'b0, dsp_status_carry};

    SB_MAC16 #(
        .NEG_TRIGGER              ( 0     ), // Trigger on rising edge.
        .C_REG                    ( 1     ),
        .A_REG                    ( 1     ),
        .B_REG                    ( 1     ),
        .D_REG                    ( 1     ),
        .TOP_8x8_MULT_REG         ( 0     ), // Half multiplies not registered.
        .BOT_8x8_MULT_REG         ( 0     ), // Half multiplies not registered.
        .PIPELINE_16x16_MULT_REG1 ( 0     ), // Multiply not registered.
        .PIPELINE_16x16_MULT_REG2 ( 0     ), // Multiply not registered.
        .TOPOUTPUT_SELECT         ( 2'b00 ), // Select adder output, unregistered
        .TOPADDSUB_LOWERINPUT     ( 2'b10 ), // Select 16x16 input to adder.
        .TOPADDSUB_UPPERINPUT     ( 1     ), // Select input C into top adder.
        .TOPADDSUB_CARRYSELECT    ( 2'b10 ), // Cascade carry from bottom adder.
        .BOTOUTPUT_SELECT         ( 2'b00 ), // Select adder output, unregistered.
        .BOTADDSUB_LOWERINPUT     ( 2'b10 ), // Select 16x16 input to bottom adder.
        .BOTADDSUB_UPPERINPUT     ( 1     ), // Select input D into to bottom adder.
        .BOTADDSUB_CARRYSELECT    ( 2'b11 ), // CI input to bottom adder.
        .MODE_8x8                 ( 0     ),
        .A_SIGNED                 ( 0     ),
        .B_SIGNED                 ( 0     )
    ) dsp_mul_low (
        .CLK       ( wb_clk_i ),        // input
        .CE        ( wb_cyc_i ),        // input
        .A         ( wb_dat_i[15:0] ),  // Operand A low bits
        .B         ( wb_dat_i[15:0] ),  // Operand B low bits
        .C         ( wb_dat_i[DW-1:16] ), // Accumulator high bits
        .D         ( wb_dat_i[15:0] ),  // Accumulator low bits.
        .AHOLD     ( ~mul_latch_a ),    // latch operand A
        .BHOLD     ( ~mul_latch_b ),    // latch operand B
        .CHOLD     ( ~mul_latch_cd ),   // latch accumulator 
        .DHOLD     ( ~mul_latch_cd ),   // latch accumulator
        .IRSTTOP   ( 0 ), // input 
        .IRSTBOT   ( 0 ), // input 
        .ORSTTOP   ( 0 ), // input 
        .ORSTBOT   ( 0 ), // input 
        .OLOADTOP  ( 0 ), // input 
        .OLOADBOT  ( 0 ), // input 
        .ADDSUBTOP ( dsp_flags[2] ),        // Multiply-Add/Subtract
        .ADDSUBBOT ( dsp_flags[2] ),        // Multiply-Add/Subtract
        .OHOLDTOP  ( 0 ), // input
        .OHOLDBOT  ( 0 ), // input
        .CI        ( dsp_flags[0] ),        // carry input
        .ACCUMCI   ( 0 ), // input
        .SIGNEXTIN ( 0 ), // input
        .O         ( dsp_mul_result ),      // multiply output [31:0]
        .CO        ( dsp_status_carry ),    // carry output
        .ACCUMCO   (  ), // output
        .SIGNEXTOUT(  )  // output
    );
endmodule
