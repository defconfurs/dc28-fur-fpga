module clock_div #(
        parameter IFREQ = 96000000,
        parameter OFREQ = 16000000
    ) (
        input  wire i_clk,
        output reg  o_clk
    );

    localparam DIV_VALUE = (IFREQ / (OFREQ*2))-1;
    localparam DIV_SIZE  = $clog2(DIV_VALUE);

    initial clk_out = 0;

    generate
        if (DIV_VALUE == 0) begin
            always @(posedge i_clk) begin
                o_clk <= ~o_clk;
            end
        else
            reg [DIV_SIZE-1:0] clk_divide = 0;
            always @(posedge i_clk) begin
                if (clk_divide) clk_divide <= clk_divide - 1;
                else begin
                    clk_divide <= DIV_VALUE;
                    o_clk      <= ~o_clk;
                end
            end
        end
    endgenerate

endmodule
