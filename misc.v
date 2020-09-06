`default_nettype none

module wb_misc #(
      parameter AW = 32,
      parameter DW = 32
)    (
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

      // Controllable LEDs.
      output wire [2:0]     leds,
      input wire [1:0]      buttons,
      input signed [15:0]   audio,
      output wire           irq
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

    // Interrupt bits
    localparam REG_INTBIT_BT0_RISING = 0;
    localparam REG_INTBIT_BT0_FALLING = 1;
    localparam REG_INTBIT_BT1_RISING = 2;
    localparam REG_INTBIT_BT1_FALLING = 3;

    reg [3:0] btn_int_status = 0;

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
        // Register Read
        else if (stb_valid && ~wb_we_i) begin
            case (reg_addr)
            REG_LED_RED:    wb_dat_o <= { {(DW-8){1'b0}}, reg_intensity[0] };
            REG_LED_GREEN:  wb_dat_o <= { {(DW-8){1'b0}}, reg_intensity[1] };
            REG_LED_BLUE:   wb_dat_o <= { {(DW-8){1'b0}}, reg_intensity[2] };
            REG_BUTTONS:    wb_dat_o <= { {(DW-2){1'b0}}, buttons };
            REG_MIC_DATA:   wb_dat_o <= { {(DW-16){audio[15]}}, audio };
            REG_INT_ENABLE: wb_dat_o <= { {(DW-4){1'b0}}, reg_int_enable };
            REG_INT_STATUS: wb_dat_o <= { {(DW-4){1'b0}}, reg_int_status };
            default:        wb_dat_o <= 0;
            endcase
        end
        // Register Write
        else if (stb_valid && wb_we_i && wb_sel_i[0]) begin
            case (reg_addr)
            REG_LED_RED:    reg_intensity[0] <= wb_dat_i[7:0];
            REG_LED_GREEN:  reg_intensity[1] <= wb_dat_i[7:0];
            REG_LED_BLUE:   reg_intensity[2] <= wb_dat_i[7:0];
            REG_INT_ENABLE: reg_int_enable   <= wb_dat_i[3:0];
            REG_INT_STATUS: reg_int_status   <= (reg_int_status & ~wb_dat_i[3:0]);
            endcase
        end
        // Update interrupt status
        else begin
            reg_int_status <= reg_int_status | btn_int_status;
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
        btn_int_status[REG_INTBIT_BT0_RISING]  <= ~buttons_prev[0] && buttons[0];
        btn_int_status[REG_INTBIT_BT0_FALLING] <= buttons_prev[0] && ~buttons[0];
        btn_int_status[REG_INTBIT_BT1_RISING]  <= ~buttons_prev[1] && buttons[1];
        btn_int_status[REG_INTBIT_BT1_FALLING] <= buttons_prev[1] && ~buttons[1];
    end
endmodule
