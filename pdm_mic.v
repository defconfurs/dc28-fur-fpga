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

    wire [10:0] w_address; // length == 2048
    wire       buf_out;

    simple_ram #(//512x8
        .addr_width ( 11 ),
        .data_width ( 1  )
    ) fir_buffer_inst  (
        .clk     ( clk        ),
        .address ( w_address  ), 
        .din     ( mic_data   ),
        .dout    ( buf_out    ),
        .we      ( output_clk )
    );

    
    //// MODE 0:  256 x 16
    //// MODE 1:  512 x 8
    //// MODE 2: 1024 x 4
    //// MODE 3: 2048 x 2
    //SB_RAM40_4K #(
    //    .WRITE_MODE (3),
    //    .READ_MODE  (3)
    //) fir_buffer_inst (
    //    .RCLK  ( clk       ),
    //    .RCLKE ( 1         ),
    //    .RE    ( 1         ),
    //    .RADDR ( w_address ),
    //    .RDATA ( buf_out   ),
    //    .WCLK  ( clk       ),
    //    .WCLKE ( 1         ),
    //    .WE    ( output_clk ),
    //    .WADDR ( w_address ),
    //    .MASK  ( 2'b11     ),
    //    .WDATA ( {15'd0, mic_data} )
    //);


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


    //wire [31:0] dsp2_out;
    //SB_MAC16 #(
    //    .NEG_TRIGGER              ( 0     ),
    //    .C_REG                    ( 0     ),
    //    .A_REG                    ( 0     ),
    //    .B_REG                    ( 0     ),
    //    .D_REG                    ( 0     ),
    //    .TOP_8x8_MULT_REG         ( 0     ),
    //    .BOT_8x8_MULT_REG         ( 0     ),
    //    .PIPELINE_16x16_MULT_REG1 ( 0     ),
    //    .PIPELINE_16x16_MULT_REG2 ( 0     ),
    //    .TOPOUTPUT_SELECT         ( 2'b00 ),
    //    .TOPADDSUB_LOWERINPUT     ( 2'b00 ),
    //    .TOPADDSUB_UPPERINPUT     ( 1     ),
    //    .TOPADDSUB_CARRYSELECT    ( 2'b00 ),
    //    .BOTOUTPUT_SELECT         ( 2'b00 ),
    //    .BOTADDSUB_LOWERINPUT     ( 2'b00 ),
    //    .BOTADDSUB_UPPERINPUT     ( 0     ),
    //    .BOTADDSUB_CARRYSELECT    ( 2'b00 ),
    //    .MODE_8x8                 ( 0     ),
    //    .A_SIGNED                 ( 0     ),
    //    .B_SIGNED                 ( 0     )
    //) mic_dsp2 (
    //    .CLK       ( clk ), // input
    //    .CE        ( output_clk ), // input
    //    .A         ( 16'hFFF0 ), // input [15:0]
    //    .B         ( dsp2_out[15:0] ), // input [15:0]
    //    .C         ( dsp2_out[15:0] ), // input [15:0]
    //    .D         ( dsp_out[15:0] ), // input [15:0]
    //    .AHOLD     ( 0 ), // input 
    //    .BHOLD     ( 0 ), // input 
    //    .CHOLD     ( 0 ), // input 
    //    .DHOLD     ( 0 ), // input 
    //    .IRSTTOP   ( 0 ), // input 
    //    .IRSTBOT   ( 0 ), // input 
    //    .ORSTTOP   ( 0 ), // input 
    //    .ORSTBOT   ( 0 ), // input 
    //    .OLOADTOP  ( 0 ), // input 
    //    .OLOADBOT  ( 0 ), // input 
    //    .ADDSUBTOP ( 0 ), // input 
    //    .ADDSUBBOT ( 0 ), // input 
    //    .OHOLDTOP  ( 0 ), // input
    //    .OHOLDBOT  ( 0 ), // input
    //    .CI        ( 0 ), // input
    //    .ACCUMCI   ( 0 ), // input
    //    .SIGNEXTIN ( 0 ), // input
    //    .O         ( dsp2_out ), // output [31:0]
    //    .CO        (  ), // output
    //    .ACCUMCO   (  ), // output
    //    .SIGNEXTOUT(  )  // output
    //);
    //assign audio1 = dsp2_out[31:32-SAMPLE_DEPTH];
    
    assign do_nothing = (mic_data ^ buf_out);
    assign add_sub = buf_out;

    assign audio1 = dsp_out[15:16-SAMPLE_DEPTH];

    assign w_address = dsp_out[26:16];
    
    //reg         last_buf_out;
    //always @(posedge clk or posedge rst) begin
    //    if (rst) begin
    //        //w_address   <= 0;
    //        //sample1_average <= 0;
    //        //sample1_out          <= 0;
    //    end
    //    else begin
    //        if (output_clk) begin
    //            //sample1_average <= (sample1_average 
    //            //                    - {{(10){sample1_average[AVERAGE_LEN-1]}}, sample1_average[AVERAGE_LEN-1:10]}
    //            //                    + (mic1_in ? {{(AVERAGE_LEN-1){1'b0}},1} : {AVERAGE_LEN{1'b1}}));
    //            //audio1          <= sample1_average[11:4];
    //            
    //            w_address    <= w_address+1;
    //            //last_buf_out <= buf_out;
    //            //audio1       <= audio1 + (mic1_in ? 12'h001 : 12'hFFF) + (last_buf_out ? 12'hFFF : 12'h001);
    //        end
    //    end
    //end
    
  
endmodule
  
