module reset_sync #(
        parameter RST_PERIOD = 16
    ) (
        input  wire i_clk,
        input  wire i_rst,
        input  wire pll_locked,
        output reg  o_rst
    );

    localparam COUNTER_SIZE  = $clog2(RST_PERIOD-1);

    initial clk_out = 0;

    reg [COUNTER_SIZE-1:0] rst_counter = 0;
    always @(posedge i_clk, posedge i_rst) begin
        if (i_rst || pll_lock='0') begin
            rst_counter <= RST_PERIOD-1;
            o_rst <= '1';
        else
            if (rst_counter) begin
                rst_counter <= rst_counter - 1;
                o_rst <= '1';
            end
            else begin
                o_rst <= '0';
            end
        end
    end

endmodule
