module pdm_mic #(
  parameter SAMPLE_DEPTH      = 16,
  parameter FIR_SAMPLE_LENGTH = 512,
  parameter INPUT_FREQUENCY   = 12000000,
  parameter FREQUENCY         = 400000,
  parameter SAMPLE_FREQUENCY  = 8000
)(
  input wire                           clk,
  input wire                           rst,

  output wire                          mic_clk,
  input wire                           mic_data,
  
  output reg signed [SAMPLE_DEPTH-1:0] audio1,
  output reg                           audio_valid
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
  assign output_clk     = div_counter == 0;
  assign output_clk_180 = div_counter == (DIV_COUNT/2);
  assign mic_clk        = div_counter > (DIV_COUNT/2);

  localparam DIV_SAMPLE_COUNT = (INPUT_FREQUENCY / SAMPLE_FREQUENCY);
  localparam DIV_SAMPLE_COUNT_SIZE = $clog2(DIV_SAMPLE_COUNT+1);
  reg [DIV_SAMPLE_COUNT_SIZE-1:0] div_sample_counter;
  wire                            div_sample;
  always @(posedge clk) begin
    if (div_sample_counter) div_sample_counter <= div_sample_counter - 1;
    else                    div_sample_counter <= DIV_SAMPLE_COUNT;
  end
  assign div_sample = div_sample_counter == 0;

  
  reg mic1_in = 0;
  always @(posedge clk) begin
    if (output_clk_180) mic1_in <= mic_data;
  end

  
  localparam PERIOD_WIDTH = $clog2(FIR_SAMPLE_LENGTH-1);

  reg                    sample_mem [0:FIR_SAMPLE_LENGTH-1];
  reg [PERIOD_WIDTH-1:0] sample_mem_addr;

  reg signed [PERIOD_WIDTH-1:0] sample1_out;
  reg signed [PERIOD_WIDTH-1:0] next_sample1_out;

  always @(*) begin
    if (rst) begin 
      next_sample1_out = 0;
    end
    else begin
      next_sample1_out = sample1_out + (mic1_in ? 1 : -1) - (sample_mem[sample_mem_addr] ? 1 : -1);
    end
  end
  

  always @(posedge clk) begin
    sample_mem[sample_mem_addr] <= mic1_in;
    sample_mem_addr             <= sample_mem_addr + 1;
    sample1_out                 <= next_sample1_out;
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
  
