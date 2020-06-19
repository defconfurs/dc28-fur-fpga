    
module math_testbench #() ();
    reg rst;
    reg clk;
    
    localparam  CLOCK_PERIOD            = 100; // Clock period in ps
    localparam  INITIAL_RESET_CYCLES    = 10;  // Number of cycles to reset when simulation starts
    initial clk = 1'b1;
    always begin
        #(CLOCK_PERIOD / 2);
        clk = ~clk;
    end

    // Initial reset
    initial begin
        rst = 1'b1;
        repeat(INITIAL_RESET_CYCLES) @(posedge clk);
        rst = 1'b0;
    end

    reg signed [3:0] a;
    reg signed [3:0] b;
    
    wire signed [3:0] adder_out;
    wire signed [7:0] multiply_out;
    wire signed [3:0] sat_mul_out;

    saturated_signed_adder #( .A_SIZE(4), .B_SIZE(4)) add_test (
        .a   ( a ),
        .b   ( b ),
        .out ( adder_out )
    );

    signed_multiply #( .A_SIZE(4), .B_SIZE(4)) multiply_test (
        .a   ( a ),
        .b   ( b ),
        .out ( multiply_out )
    );
    
    saturation_signed_multiply #(
        .A_SIZE(4), 
        .B_SIZE(4),
        .OFFSET(0),
        .OUT_SIZE(4)
    ) sat_mul_test (
        .a   ( a ),
        .b   ( b ),
        .out ( sat_mul_out )
    );
    

    integer  i;
    
    initial begin
        b = 0;
        for (i = 0; i < 256; i=i+1) begin
            a = i - 8;
            b = (i >> 4) - 8;
            @(posedge clk);
        end
    end
    
endmodule

