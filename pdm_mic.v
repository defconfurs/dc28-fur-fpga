module pdm_mic #(
      parameter SAMPLE_DEPTH      = 16
) (
      input wire                           clk,
      input wire                           rst,
      
      output wire                          mic_clk,
      input wire                           mic_data,
      
      output reg signed [SAMPLE_DEPTH-1:0] audio1
    );
  

    reg clk_2 = 0;
    always @(posedge clk  ) clk_2 <= !clk_2;

    reg last_clk_2;
    always @(posedge clk) last_clk_2 <= clk_2;
    
    wire                      output_clk;
    wire                      output_clk_180;
    assign output_clk_180 = last_clk_2 != clk_2 && !clk_2;
    assign output_clk     = last_clk_2 != clk_2 &&  clk_2;
    assign mic_clk        = clk_2;
    
    reg mic1_in = 0;
    always @(posedge clk) begin
      if (output_clk) mic1_in <= mic_data;
    end

    reg signed [SAMPLE_DEPTH-1:0] sample1_out;
    reg signed [17:0]             sample1_average;

    //reg [10:0] w_address; // length == 2048
    wire       buf_out;
    
    //SB_RAM40_4K #(
    //    .WRITE_MODE ( 3 ), // 2048x2
    //    .READ_MODE  ( 3 )  // 2048x2
    //) fir_buffer_inst (
    //    .RCLK  ( clk       ),
    //    .RCLKE ( 1         ),
    //    .RE    ( 1         ),
    //    .RADDR ( w_address ),
    //    .RDATA ( buf_out   ),
    //    .WCLK  ( clk       ),
    //    .WCLKE ( 1         ),
    //    .WE    ( 1         ),
    //    .WADDR ( w_address ),
    //    .MASK  ( 2'b11     ),
    //    .WDATA ( {15'd0, mic1_in} )
    //);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            //w_address   <= 0;
            sample1_average <= 0;
            sample1_out          <= 0;
        end
        else begin
            if (output_clk) begin
                sample1_average <= sample1_average - (sample1_average >> 12) + (mic1_in ? $signed('d1) : $signed('d-1));
                sample1_out     <= (sample1_average > 32767 ? 32767 : (sample1_average < -32768 ? -32768 : sample1_average));
                //w_address   <= w_address+1;
                //sample1_out <= sample1_out + (mic1_in ? $signed(12'd1) : $signed(12'd-1)) - (buf_out ? $signed(12'd1) : $signed(12'd-1));
            end
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            audio1 <= 0;
        end
        else begin
            if (output_clk) begin
                audio1 <= sample1_out;
            end
        end
    end
  
endmodule
  
