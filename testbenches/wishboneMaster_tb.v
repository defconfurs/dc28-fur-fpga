module wishbone_master_testbench #() ();

    localparam ADDRESS_WIDTH = 16;
    localparam DATA_WIDTH    = 8;
    localparam DATA_BYTES    = 1;
    localparam MAX_WAIT      = 8;
    localparam MAX_PAYLOAD = 8;
    
    localparam INTERFACE_WIDTH = (MAX_PAYLOAD * DATA_WIDTH);
    localparam INTERFACE_LENGTH_N = ((MAX_PAYLOAD <=  2) ? 2 :
                                     (MAX_PAYLOAD <=  4) ? 3 :
                                     (MAX_PAYLOAD <=  8) ? 4 :
                                     (MAX_PAYLOAD <= 16) ? 5 :
                                     (MAX_PAYLOAD <= 32) ? 6 :
                                     /*           <= 64 */ 7);

    reg                          rst_i;
    reg                          clk_i;

                                 
    wire [ADDRESS_WIDTH-1:0]     adr_o;
    reg [DATA_WIDTH-1:0]         dat_i;
    wire [DATA_WIDTH-1:0]        dat_o;
    wire                         we_o;
    wire [DATA_BYTES-1:0]        sel_o;
    wire                         stb_o;
    reg                          cyc_i;
    wire                         cyc_o;
    reg                          ack_i;
    wire [2:0]                   cti_o;

    // packet interface
    reg [ADDRESS_WIDTH-1:0]      transfer_address;
    reg [INTERFACE_WIDTH-1:0]    payload_in;
    wire [INTERFACE_WIDTH-1:0]   payload_out;
    reg [INTERFACE_LENGTH_N-1:0] payload_length;
    reg                          start_read;
    wire                         read_busy;
    reg                          start_write;
    wire                         write_busy;
    wire                         completed;
    wire                         timeout;

    wire                         clk;
    wire                         rst;
    
    wishbone_master #(
        .ADDRESS_WIDTH         (ADDRESS_WIDTH),
        .DATA_WIDTH            (DATA_WIDTH),
        .DATA_BYTES            (DATA_BYTES),
        .MAX_WAIT              (MAX_WAIT),
        .MAX_PAYLOAD (MAX_PAYLOAD)
    ) dut_wb_master (
        // Wishbone interface
        .rst_i (rst_i),
        .clk_i (clk_i),

        .adr_o (adr_o),
        .dat_i (dat_i),
        .dat_o (dat_o),
        .we_o  (we_o),
        .sel_o (sel_o),
        .stb_o (stb_o),
        .cyc_i (cyc_i),
        .cyc_o (cyc_o),
        .ack_i (ack_i),
        .cti_o (cti_o),

        // packet interface
        .transfer_address(transfer_address),
        .payload_in      (payload_in      ),
        .payload_out     (payload_out     ),
        .payload_length  (payload_length  ),
        .start_read      (start_read      ),
        .read_busy       (read_busy       ),
        .start_write     (start_write     ),
        .write_busy      (write_busy      ),
        .completed       (completed       ),
        .timeout         (timeout         )
    );

    localparam  CLOCK_PERIOD            = 100; // Clock period in ps
    localparam  INITIAL_RESET_CYCLES    = 10;  // Number of cycles to reset when simulation starts
    // Clock signal generator
    initial clk_i = 1'b0;
    always begin
        #(CLOCK_PERIOD / 2);
        clk_i = ~clk_i;
    end
    
    // Initial reset
    initial begin
        rst_i = 1'b1;
        repeat(INITIAL_RESET_CYCLES) @(posedge clk_i);
        rst_i = 1'b0;
    end

    assign clk = clk_i;
    assign rst = rst_i;

    // Test cycle
    initial begin
        transfer_address = 16'h0000;
        payload_in       = 64'h0000000000000000;
        payload_length   = 3'h0;
        start_read       = 1'b0;
        start_write      = 1'b0;

        wait(rst);
        wait(!rst);
        repeat(2) @(posedge clk);

        transfer_address = 16'h0012;
        payload_in       = 64'h0000000504030201;
        payload_length   = 3'h4;
        @(posedge clk);
        start_read  = 1'b1;
        start_write = 1'b0;
        @(posedge clk);
        start_read  = 1'b0;
        start_write = 1'b0;

        repeat(20) @(posedge clk);
        @(posedge clk);
        start_read  = 1'b0;
        start_write = 1'b1;
        @(posedge clk);
        start_read  = 1'b0;
        start_write = 1'b0;

        repeat(20) @(posedge clk);
        @(posedge clk);
        start_read  = 1'b0;
        start_write = 1'b1;
        @(posedge clk);
        start_read  = 1'b0;
        start_write = 1'b0;
    end

    initial begin
        dat_i = 8'h00;

        wait(cyc_o);
        while(cyc_o) begin
            @(posedge clk);
            dat_i = adr_o + 8'h10;
        end
    end

    initial begin
        cyc_i = 1'b0;
        ack_i = 0;
        wait(cyc_o);
        @(posedge clk);
        ack_i = 1;
        repeat(3) @(posedge clk);
        ack_i = 0;
        repeat(2) @(posedge clk);
        ack_i = 1;
        wait(!cyc_o);
        ack_i = 0;

        cyc_i = 1;
        repeat(30) @(posedge clk);
        cyc_i = 0;
        
        wait(cyc_o);
        repeat(10) @(posedge clk);
        ack_i = 1;
        repeat(3) @(posedge clk);
        ack_i = 0;
        repeat(2) @(posedge clk);
        ack_i = 1;
        wait(!cyc_o);
        ack_i = 0;

        wait(cyc_o);
        repeat(4) @(posedge clk);
        ack_i = 1;
        repeat(3) @(posedge clk);
        ack_i = 0;
        repeat(2) @(posedge clk);
        ack_i = 1;
        wait(!cyc_o);
        ack_i = 0;
    end
        
    
endmodule
