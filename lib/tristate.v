module tristate (
        // Control side
        input wire  i_dir,
        input wire  i_out,
        output wire o_in,

        inout wire  io
    );

    assign io = i_dir ? i_out : 1'bZ;
    assign in = io;

endmodule

module tristate_bus #(
    parameter WIDTH   = 1
    )  (
        // Control side
        input wire [WIDTH-1:0]     i_dir,
        input wire [WIDTH-1:0]     i_out,
        output wire [WIDTH-1:0]    o_in,

        inout wire [WIDTH-1:0]     io
    );

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i+1) begin
            assign io[i] = i_dir[i] ? i_out[i] : 1'bZ;
            assign in[i] = io[i];
        end
    endgenerate

endmodule