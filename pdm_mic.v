/*
 * This file is part of the DEFCON Furs DC28 badge project.
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2020 DEFCON Furs <https://dcfurs.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

`default_nettype none

module pdm_mic #(
      parameter SAMPLE_DEPTH      = 16
) (
      input wire                           clk,
      input wire                           rst,
      
      output wire                          mic_clk,
      input wire                           mic_data,
      
      output wire signed [SAMPLE_DEPTH-1:0] audio
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
    
    //reg signed [SAMPLE_DEPTH-1:0] sample1_out = 0;
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
    
    //reg        last_buf_out = 0;
    //always @(posedge clk) if (output_clk) last_buf_out <= buf_out;

    localparam AUDIO1_DEPTH = SAMPLE_DEPTH+2;
    wire [AUDIO1_DEPTH-1:0] audio1;

    wire        add_sub;
    wire        do_nothing;
    
    reg         dsp2_clk = 0;
    wire [31:0] dsp2_out;
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
        .CE        ( 1 ), // input
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
        .OHOLDTOP  ( !output_clk ), // input
        .OHOLDBOT  ( !output_clk ), // input
        .CI        ( !do_nothing ), // input
        .ACCUMCI   ( 0 ), // input
        .SIGNEXTIN ( 0 ), // input
        .O         ( dsp_out ), // output [31:0]
        .CO        (  ), // output
        .ACCUMCO   (  ), // output
        .SIGNEXTOUT(  )  // output
    );

    reg last_mic_data = 0;
    always @(posedge clk) if (output_clk) last_mic_data <= mic_data;
    
    assign do_nothing = !(last_mic_data ^ buf_out);
    assign add_sub = buf_out;

    assign w_address = dsp_out[16+ADDR_SIZE-1:16];

    generate
        if (AUDIO1_DEPTH < ADDR_SIZE)
            assign audio1 = dsp_out[ADDR_SIZE+2-1:ADDR_SIZE+2-AUDIO1_DEPTH];
        else
            assign audio1 = { dsp_out[ADDR_SIZE-1:0], {(AUDIO1_DEPTH-ADDR_SIZE){1'b0}}};
    endgenerate


    reg last_addr_topbit;
    always @(posedge clk) last_addr_topbit <= w_address[ADDR_SIZE-2];
    always @(posedge clk) dsp2_clk <= (last_addr_topbit ^ w_address[ADDR_SIZE-2]) & w_address[ADDR_SIZE-2];
    
    
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
        .TOPOUTPUT_SELECT         ( 2'b01 ),
        .TOPADDSUB_LOWERINPUT     ( 2'b10 ),
        .TOPADDSUB_UPPERINPUT     ( 1     ),
        .TOPADDSUB_CARRYSELECT    ( 2'b00 ),
        .BOTOUTPUT_SELECT         ( 2'b01 ),
        .BOTADDSUB_LOWERINPUT     ( 2'b00 ),
        .BOTADDSUB_UPPERINPUT     ( 1     ),
        .BOTADDSUB_CARRYSELECT    ( 2'b00 ),
        .MODE_8x8                 ( 0     ),
        .A_SIGNED                 ( 0     ),
        .B_SIGNED                 ( 1     )
    ) mic_dsp2 (
        .CLK       ( clk ),
        .CE        ( dsp2_clk ),
        .A         ( 16'h1200 ),
        .B         ( dsp2_out[15:0] ),
        .C         ( {{(16-AUDIO1_DEPTH){1'b0}}, audio1} ),
        .D         ( dsp2_out[31:16] ),
        .AHOLD     ( 0 ),
        .BHOLD     ( 0 ),
        .CHOLD     ( 0 ),
        .DHOLD     ( 0 ),
        .IRSTTOP   ( 0 ), 
        .IRSTBOT   ( 0 ), 
        .ORSTTOP   ( 0 ), 
        .ORSTBOT   ( 0 ), 
        .OLOADTOP  ( 0 ), 
        .OLOADBOT  ( 0 ), 
        .ADDSUBTOP ( 1 ), 
        .ADDSUBBOT ( 0 ), 
        .OHOLDTOP  ( 0 ),
        .OHOLDBOT  ( 0 ),
        .CI        ( 0 ),
        .ACCUMCI   ( 0 ),
        .SIGNEXTIN ( 0 ),
        .O         ( dsp2_out ), // output [31:0]
        .CO        (  ), // output
        .ACCUMCO   (  ), // output
        .SIGNEXTOUT(  )  // output
    );
    
    wire signed [8:0] full_audio_out = dsp2_out[16+9-1:16];
    wire signed [10:0] amp_audio = { full_audio_out[8:0], 2'd0 };
    assign audio = (amp_audio > 127 ? 127 :
                    amp_audio < -128 ? -128 : amp_audio);
    
    //assign audio = $signed(audio1)-128;
    //assign audio = dsp2_out[15:8];
    //assign audio = dsp2_out[16+SAMPLE_DEPTH+1-1:16+1];
    

  
endmodule
  
