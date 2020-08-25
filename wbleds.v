module wbledpwm#(
	parameter	AW = 32,
    parameter   DW = 32,
    parameter   NLEDS = 4
) (
    // Wishbone interface.
    input           wb_clk_i,
    input           wb_reset_i,
    input  [AW-1:0] wb_adr_i,
    input  [DW-1:0] wb_dat_i,
    output reg [DW-1:0] wb_dat_o,
    input           wb_we_i,
    input  [DW/8-1:0] wb_sel_i,
    output reg      wb_ack_o,
    input           wb_cyc_i,
    input           wb_stb_i,

    // Controllable LEDs.
    output [NLEDS-1:0] leds
);

// Only use the LSB nibble for address decoding.
wire [3:0] reg_addr = wb_adr_i[3:0];

// Locate the STB rising edge.
reg          stb_prev = 0;
wire         stb_edge = ~stb_prev && wb_cyc_i && wb_stb_i;
always @(posedge wb_clk_i) stb_prev <= wb_cyc_i && wb_stb_i;
always @(posedge wb_clk_i) wb_ack_o <= stb_edge;

///////////////////////////////////////
// LED Intensity Registers.
///////////////////////////////////////
reg [7:0] reg_intensity[NLEDS-1:0];

// Register Read
always @(posedge wb_clk_i) begin
    if (wb_reset_i) wb_dat_o <= {(DW){1'b0}};
    else if (stb_edge && ~wb_we_i) begin
        wb_dat_o <= { {(DW-8){1'b0}}, reg_intensity[reg_addr] };
    end
end

// Register Write
genvar i;
generate
    for (i = 0; i < NLEDS; i = i + 1) begin
        always @(posedge wb_clk_i) begin
            if (wb_reset_i) reg_intensity[i] <= 8'h00;
            else if (stb_edge && wb_we_i && wb_sel_i[0]) begin
                reg_intensity[reg_addr] <= wb_dat_i[7:0];
            end
        end
    end
endgenerate

///////////////////////////////////////
// PWM Generation
///////////////////////////////////////
reg [7:0] pwm_counter = 0;
always @(posedge wb_clk_i) pwm_counter <= pwm_counter + 1;

genvar zz;
generate
    for (zz = 0; zz < NLEDS; zz = zz + 1) begin
        assign leds[zz] = (reg_intensity[zz] > pwm_counter);
    end
endgenerate

endmodule
