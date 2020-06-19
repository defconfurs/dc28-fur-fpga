module led_matrix_tb #() ();

    localparam ADDRESS_WIDTH = 16;
    localparam DATA_WIDTH    = 8;
    localparam DATA_BYTES    = 1;
    localparam MAX_WAIT      = 8;
    localparam MAX_PAYLOAD = 8;
    
    localparam INTERFACE_WIDTH = (MAX_PAYLOAD * DATA_WIDTH);
    localparam INTERFACE_LENGTH_N = ((MAX_PAYLOAD <=  2) ? 1 :
                                     (MAX_PAYLOAD <=  4) ? 2 :
                                     (MAX_PAYLOAD <=  8) ? 3 :
                                     (MAX_PAYLOAD <= 16) ? 4 :
                                     (MAX_PAYLOAD <= 32) ? 5 :
                                     /*           <= 64 */ 6);

    reg                     rst;
    reg                     clk;
    reg [ADDRESS_WIDTH-1:0] adr;
    reg [DATA_WIDTH-1:0]    data;
    wire [DATA_WIDTH-1:0]   dut_data;
    reg                     we;
    reg                     sel;
    reg                     stb;
    reg                     cycle;
    wire                    dug_ack;
    reg [2:0]               cti;
    
    wire [ADDRESS_WIDTH-1:0] frame_adr_o;
    reg [DATA_WIDTH-1:0]     frame_dat_i;
    wire [DATA_WIDTH-1:0]    frame_dat_o;
    wire                     frame_we_o;
    wire [DATA_BYTES-1:0]    frame_sel_o;
    wire                     frame_stb_o;
    reg                      frame_cyc_i;
    wire                     frame_cyc_o;
    reg                      frame_ack_i;
    wire [2:0]               frame_cti_o;

    wire                      shift_1st_line;
    wire                      shift_clock;
    wire [3:0]                led_out;
    
    led_matrix #(
        .N_COLS          (4),
        .N_ROWS          (4),
        .ADDRESS_WIDTH   (16),
        .DATA_WIDTH      (8),
        .DATA_BYTES      (1),
        .BASE_ADDRESS    (0),
        .MAX_WAIT        (MAX_WAIT),
        .TOTAL_LOAD_TIME (128),
        .TOTAL_LINE_TIME (128)
    ) dut_led_matrix (
        // Wishbone interface
        .rst_i (rst),
        .clk_i (clk),

        .adr_i (adr),
        .dat_i (data),
        .dat_o (dut_data),
        .we_i  (we),
        .sel_i (sel),
        .stb_i (stb),
        .cyc_i (cycle),
        .ack_o (dut_ack),
        .cti_i (cti),

        // Wishbone master
        .frame_adr_o (frame_adr_o),
        .frame_dat_i (frame_dat_i),
        .frame_dat_o (frame_dat_o),
        .frame_we_o  (frame_we_o),
        .frame_sel_o (frame_sel_o),
        .frame_stb_o (frame_stb_o),
        .frame_cyc_i (frame_cyc_i),
        .frame_cyc_o (frame_cyc_o),
        .frame_ack_i (frame_ack_i),
        .frame_cti_o (frame_cti_p),
    
        // LED Drive Out
        .shift_1st_line (shift_1st_line),
        .shift_clock    (shift_clock),
        .led_out        (led_out)
    );

    localparam  CLOCK_PERIOD            = 100; // Clock period in ps
    localparam  INITIAL_RESET_CYCLES    = 10;  // Number of cycles to reset when simulation starts
    // Clock signal generator
    initial clk = 1'b0;
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

    // Test cycle
    initial begin
        adr   = 16'h0000;
        data  = 8'h00;
        we    = 1;
        sel   = 1;
        stb   = 0;
        cycle = 0;
        cti   = 0;

        wait(rst);
        wait(!rst);
        repeat(10) @(posedge clk);

        //adr = 16'h0104; data = 8'h31; we = 1; cycle=1;
        //@(posedge clk); @(posedge clk);
        //we=0; cycle=0;
        //repeat(400000) @(posedge clk);
        //
        //adr = 16'h0104; data = 8'h30; we = 1; cycle=1;
        //@(posedge clk); @(posedge clk);
        //we=0; cycle=0;
        //repeat(400000) @(posedge clk);
        //
        //adr = 16'h0104; data = 8'h31; we = 1; cycle=1;
        //@(posedge clk); @(posedge clk);
        //we=0; cycle=0;
        //repeat(400000) @(posedge clk);
        //
        //adr = 16'h0104; data = 8'h30; we = 1; cycle=1;
        //@(posedge clk); @(posedge clk);
        //we=0; cycle=0;
        //repeat(400000) @(posedge clk);
    end

    initial begin
        frame_dat_i = 0;
        frame_cyc_i = 0;
    end
    always @(posedge clk) begin
        frame_ack_i <= frame_cyc_o;
        if (frame_cyc_o) begin
            frame_dat_i <= frame_adr_o + 8'h10;
        end
    end
    
    
endmodule
