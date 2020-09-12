module pdm_mic #(
      parameter SAMPLE_DEPTH      = 16
) (
      input wire                           clk,
      input wire                           rst,
      
      output wire                          mic_clk,
      input wire                           mic_data,
      
      output wire signed [SAMPLE_DEPTH-1:0] audio1
    );
  

    reg clk_2 = 0;
    always @(posedge clk  ) clk_2 <= !clk_2;

    reg clk_4 = 0;
    always @(posedge clk_2) clk_4 <= !clk_4;

    reg last_clk_4;
    always @(posedge clk) last_clk_4 <= clk_4;
    
    wire                      output_clk;
    wire                      output_clk_180;
    assign output_clk_180 = last_clk_4 != clk_4 &&  clk_4;
    assign output_clk     = last_clk_4 != clk_4 && !clk_4;
    assign mic_clk        = clk_4;
    
    //reg mic1_in = 0;
    //always @(posedge clk) begin
    //  if (output_clk) mic1_in <= mic_data;
    //end

    //localparam AVERAGE_LEN = 12;
    
    reg signed [SAMPLE_DEPTH-1:0] sample1_out;
    //reg signed [AVERAGE_LEN-1:0] sample1_average;

    localparam FILTER_LENGTH = 256;
    localparam ADDR_SIZE = $clog2(FILTER_LENGTH-1);
    wire [ADDR_SIZE-1:0] w_address; // length == 2048
    wire       buf_out;

    simple_ram #(//512x8
        .addr_width ( ADDR_SIZE ),
        .data_width ( 1  )
    ) fir_buffer_inst  (
        .clk     ( clk        ),
        .address ( w_address  ), 
        .din     ( mic_data   ),
        .dout    ( buf_out    ),
        .we      ( output_clk )
    );

    
    reg         add_sub;
    reg         do_nothing;
    wire [31:0] dsp_out;
    SB_MAC16 #(
        .NEG_TRIGGER              ( 0     ),
        .C_REG                    ( 0     ),
        .A_REG                    ( 0     ),
        .B_REG                    ( 0     ),
        .D_REG                    ( 0     ),
        .TOP_8x8_MULT_REG         ( 0     ),
        .BOT_8x8_MULT_REG         ( 0     ),
        .PIPELINE_16x16_MULT_REG1 ( 0     ),
        .PIPELINE_16x16_MULT_REG2 ( 0     ),
        .TOPOUTPUT_SELECT         ( 2'b00 ),
        .TOPADDSUB_LOWERINPUT     ( 2'b00 ),
        .TOPADDSUB_UPPERINPUT     ( 0     ),
        .TOPADDSUB_CARRYSELECT    ( 2'b01 ),
        .BOTOUTPUT_SELECT         ( 2'b01 ),
        .BOTADDSUB_LOWERINPUT     ( 2'b00 ),
        .BOTADDSUB_UPPERINPUT     ( 0     ),
        .BOTADDSUB_CARRYSELECT    ( 2'b11 ),
        .MODE_8x8                 ( 0     ),
        .A_SIGNED                 ( 0     ),
        .B_SIGNED                 ( 0     )
    ) mic_dsp (
        .CLK       ( clk ), // input
        .CE        ( output_clk ), // input
        .A         ( 0 ), // input [15:0]
        .B         ( 0 ), // input [15:0]
        .C         ( 0 ), // input [15:0]
        .D         ( 0 ), // input [15:0]
        .AHOLD     ( 0 ), // input 
        .BHOLD     ( 0 ), // input 
        .CHOLD     ( 0 ), // input 
        .DHOLD     ( 0 ), // input 
        .IRSTTOP   ( 0 ), // input 
        .IRSTBOT   ( 0 ), // input 
        .ORSTTOP   ( 0 ), // input 
        .ORSTBOT   ( 0 ), // input 
        .OLOADTOP  ( 0 ), // input 
        .OLOADBOT  ( 0 ), // input 
        .ADDSUBTOP ( 0 ), // input 
        .ADDSUBBOT ( add_sub ), // input 
        .OHOLDTOP  ( 0 ), // input
        .OHOLDBOT  ( 0 ), // input
        .CI        ( !do_nothing ), // input
        .ACCUMCI   ( 0 ), // input
        .SIGNEXTIN ( 0 ), // input
        .O         ( dsp_out ), // output [31:0]
        .CO        (  ), // output
        .ACCUMCO   (  ), // output
        .SIGNEXTOUT(  )  // output
    );

    
    assign do_nothing = (mic_data ^ buf_out);
    assign add_sub = buf_out;

    generate
        if (SAMPLE_DEPTH < ADDR_SIZE)
            assign audio1 = dsp_out[ADDR_SIZE+1-1:ADDR_SIZE+1-SAMPLE_DEPTH];
        else
            assign audio1 = { dsp_out[ADDR_SIZE+1-1:0], {(SAMPLE_DEPTH-ADDR_SIZE){1'b0}}};
    endgenerate

    assign w_address = dsp_out[26:16];    
  
endmodule
  
