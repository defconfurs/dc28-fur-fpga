module sig_breakout #(
        parameter IH = 31,
        parameter IL = 0,
        parameter OH = 0,
        parameter OL = 0
    ) (
        input  wire [IH:IL] i_bus,
        output wire [OH:OL] o_sig
    );

    genvar i;
    generate
        for (i = OL; i <= OH; i = i + 1) begin
            if (i >= IL and i <= IH) begin
                assign o_sig[i] = i_bus[i];
            else
                assign o_sig[i] = '0';
            end
        end
    endgenerate

endmodule
