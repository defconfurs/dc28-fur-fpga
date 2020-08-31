module pdm_mic #(
      parameter SAMPLE_DEPTH      = 16,
      parameter FIR_SAMPLE_LENGTH = 512,
      parameter INPUT_FREQUENCY   = 12000000,
      parameter FREQUENCY         = 400000
) (
      input wire                           clk,
      input wire                           rst,
      
      output wire                          mic_clk,
      input wire                           mic_data,
      
      output reg signed [SAMPLE_DEPTH-1:0] audio1
    );
  
    
    localparam DIV_COUNT = (INPUT_FREQUENCY / (FREQUENCY*2))-1;
    localparam DIV_COUNT_SIZE = $clog2(DIV_COUNT+1);
  
    reg [DIV_COUNT_SIZE-1:0]  div_counter;
    wire                      output_clk;
    wire                      output_clk_180;
    always @(posedge clk) begin
      if (div_counter) begin
        div_counter <= div_counter - 1;
      end
      else begin
        div_counter    <= DIV_COUNT;
      end
    end
    assign output_clk_180 = div_counter == 0;
    assign output_clk     = div_counter == (DIV_COUNT/2);
    assign mic_clk        = div_counter > (DIV_COUNT/2);

    
    reg mic1_in = 0;
    always @(posedge clk) begin
      if (output_clk) mic1_in <= mic_data;
    end

    
    reg signed [SAMPLE_DEPTH-1:0] sample1_out;

    reg [10:0] w_address;
    reg [10:0] r_address;
    
    SB_RAM40_4K #(
        .WRITE_MODE ( 3 ), // 2048x2
        .READ_MODE  ( 3 )  // 2048x2
    ) fir_buffer_inst (
        .RCLK ( clk       ),
        .RCLKE( 1         ),
        .RE   ( 1         ),
        .RADDR( r_address ),
        .RDATA( buf_out   ),
        .WCLK ( clk       ),
        .WCLKE( 1         ),
        .WE   ( 1         ),
        .WADDR( w_address ),
        .MASK ( 2'b11     ),
        .WDATA( {1'b1, mic1_in} )
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_address   <= 0;
            r_address   <= FIR_SAMPLE_LENGTH;
            sample1_out <= 0;
        end
        else begin
            if (output_clk) begin
                r_address   <= r_address+1;
                w_address   <= w_address+1;
                sample1_out <= sample1_out + (mic1_in ? 1 : -1) - (buf_out ? 1 : -1);
            end
        end
    end
    
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        audio1 <= 0;
      end
      else begin
        audio_valid <= div_sample;
        if (div_sample) begin
          audio1 <= sample1_out;
        end
      end
    end
  
endmodule
  
