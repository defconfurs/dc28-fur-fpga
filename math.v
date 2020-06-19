
module signed_adder #(
    parameter AS = 8,
    parameter BS = 8,
    parameter OUTS = (AS >= BS ? AS + 1 : BS + 1)
)  (
    input wire signed [AS-1:0]    a,
    input wire signed [BS-1:0]    b,
    output wire signed [OUTS-1:0] out
    );

    assign out = a + b;
endmodule

module saturated_signed_adder #(
    parameter AS = 8,
    parameter BS = 8,
    parameter OUTS = (AS >= BS ? AS : BS)
)  (
    input wire signed [AS-1:0]   a,
    input wire signed [BS-1:0]   b,
    output reg signed [OUTS-1:0] out = 0,
    output reg                   sat = 0
    );

    wire signed [OUTS+1-1:0]      temp;
    
    assign temp = a + b;
    always @(*) begin
        case (temp[OUTS:OUTS-1])
        2'b00: begin  sat = 1'b0;  out = temp[OUTS-1:0];               end
        2'b01: begin  sat = 1'b1;  out = {1'b0, {(OUTS-1){1'b1}}};     end
        2'b10: begin  sat = 1'b1;  out = {1'b1, {(OUTS-1){1'b0}}};     end
        2'b11: begin  sat = 1'b0;  out = {temp[OUTS], temp[OUTS-2:0]}; end
        endcase
    end
endmodule

module signed_multiply #(
    parameter AS = 8,
    parameter BS = 8,
    parameter OUTS = (AS + BS)
)  (
    input wire signed [AS-1:0] a,
    input wire signed [BS-1:0] b,
    output wire signed [OUTS-1:0] out
    );

    assign out = a * b;
endmodule

module saturation_signed_multiply #(
    parameter AS = 8,
    parameter BS = 8,
    parameter OFFSET = 0,
    parameter FULL_SIZE = (AS + BS),
    parameter OUTS = (FULL_SIZE - OFFSET)
)  (
    input wire signed [AS-1:0]   a,
    input wire signed [BS-1:0]   b,
    output reg signed [OUTS-1:0] out = 0,
    output reg                   sat = 0
    );

    localparam TRUNKED_SIZE = FULL_SIZE - OFFSET;
    localparam LEFTOVER = TRUNKED_SIZE - OUTS;
    
    wire signed [FULL_SIZE-1:0] temp;
    wire signed [TRUNKED_SIZE-1:0] trunked_temp;

    assign temp = a * b;
    assign trunked_temp = temp[FULL_SIZE-1:OFFSET];

    wire sat_pos = trunked_temp >= $signed(1<<(OUTS-1));
    wire sat_neg = trunked_temp <= 0-$signed(1<<(OUTS-1));
    
    always @(*) begin
        if      (sat_pos) begin sat = 1'b1;  out = {1'b0,{(OUTS-1){1'b1}}}; end
        else if (sat_neg) begin sat = 1'b1;  out = {1'b1,{(OUTS-1){1'b0}}}; end
        else              begin sat = 1'b0;  out = trunked_temp;            end
    end
endmodule

module saturate #(
    parameter AS = 8,
    parameter OUTS = (AS)
)  (
    input wire signed [AS-1:0]   a,
    output reg signed [OUTS-1:0] out = 0,
    output wire                  sat
    );

    wire sat_pos = a >= $signed(1<<(OUTS-1));
    wire sat_neg = a <= 0-$signed(1<<(OUTS-1));
    
    always @(*) begin
        if      (sat_pos) out = {1'b0,{(OUTS-1){1'b1}}};
        else if (sat_neg) out = {1'b1,{(OUTS-1){1'b0}}};
        else              out = a;
    end

    assign sat = sat_pos | sat_neg;
endmodule
