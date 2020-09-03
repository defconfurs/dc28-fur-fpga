module wb_misc #(
      parameter AW = 32,
      parameter DW = 32
)    (
      // Wishbone interface.
      input               wb_clk_i,
      input               wb_reset_i,
      input [AW-1:0]      wb_adr_i,
      input [DW-1:0]      wb_dat_i,
      output reg [DW-1:0] wb_dat_o,
      input               wb_we_i,
      input [DW/8-1:0]    wb_sel_i,
      output reg          wb_ack_o,
      input               wb_cyc_i,
      input               wb_stb_i,

      // Controllable LEDs.
      output [2:0]        leds,
      input [1:0]         buttons,
      input signed [15:0] audio
    );

    // Only use the LSB nibble for address decoding.
    wire [3:0]         reg_addr = wb_adr_i[3:0];

    // Locate the STB rising edge.
    reg                stb_prev = 0;
    wire               stb_edge = ~stb_prev && wb_cyc_i && wb_stb_i;
    always @(posedge wb_clk_i) stb_prev <= wb_cyc_i && wb_stb_i;
    always @(posedge wb_clk_i) wb_ack_o <= stb_edge;

    ///////////////////////////////////////
    // LED Intensity Registers.
    ///////////////////////////////////////
    reg [7:0]          reg_intensity[2:0];

    // Register Read
    always @(posedge wb_clk_i) begin
        if (stb_edge && ~wb_we_i) begin
            case (reg_addr)
            0: wb_dat_o       <= { {(DW-8){1'b0}}, reg_intensity[0] };
            1: wb_dat_o       <= { {(DW-8){1'b0}}, reg_intensity[1] };
            2: wb_dat_o       <= { {(DW-8){1'b0}}, reg_intensity[2] };
            3: wb_dat_o       <= { {(DW-2){1'b0}}, buttons };
            4: wb_dat_o       <= { {(DW-16){audio[15]}}, audio };
            default: wb_dat_o <= 0;
            endcase
        end
    end

    // Register Write
    always @(posedge wb_clk_i) begin
        if (wb_reset_i) begin
            reg_intensity[0] <= 8'h00;
            reg_intensity[1] <= 8'h00;
            reg_intensity[2] <= 8'h00;
        end
        else begin
            if (stb_edge && wb_we_i) begin
                case (reg_addr)
                0: if (wb_sel_i[0]) reg_intensity[0] <= wb_dat_i[7:0];
                1: if (wb_sel_i[0]) reg_intensity[1] <= wb_dat_i[7:0];
                2: if (wb_sel_i[0]) reg_intensity[2] <= wb_dat_i[7:0];
                endcase
            end
        end
    end

    ///////////////////////////////////////
    // PWM Generation
    ///////////////////////////////////////
    reg [7:0] pwm_counter = 0;
    always @(posedge wb_clk_i) pwm_counter <= pwm_counter + 1;

    assign leds[0] = (reg_intensity[0] > pwm_counter);
    assign leds[1] = (reg_intensity[1] > pwm_counter);
    assign leds[2] = (reg_intensity[2] > pwm_counter);
    
endmodule
