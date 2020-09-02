
`default_nettype none

module wb_qspi_flash #(
    parameter AW   = 24,
    parameter DW   = 32
) (
    input wire          wb_reset_i,
    input wire          wb_clk_i,

    // Wishbone interface
    input wire [AW-1:0] wb_adr_i,
    input wire [DW-1:0] wb_dat_i,
    output wire [DW-1:0] wb_dat_o,
    input wire          wb_we_i,
    input wire [(DW/8)-1:0] wb_sel_i,
    input wire          wb_stb_i,
    input wire          wb_cyc_i,
    output reg          wb_ack_o,

    // (Q)SPI interface
    output wire         spi_clk,
    output wire         spi_sel,
    output reg [3:0]    spi_d_out,
    input wire [3:0]    spi_d_in,
    output reg [3:0]    spi_d_dir
    );
    
    localparam XFER_STATE_IDLE    = 4'h0;
    localparam XFER_STATE_COMMAND = 4'h1;
    localparam XFER_STATE_ADDRESS = 4'h2;
    localparam XFER_STATE_DUMMY   = 4'h3;
    localparam XFER_STATE_READ    = 4'h4;
    localparam XFER_STATE_DONE    = 4'h5;
    
    localparam SPI_ADDR_BITS = 24;
    localparam WB_ADDR_BITS = SPI_ADDR_BITS-$clog2(DW/8);
    wire [SPI_ADDR_BITS-1:0] wb_addr_local;
    assign wb_addr_local = wb_adr_i[WB_ADDR_BITS-1:0] * (DW/8);
    
    reg [3:0]  xfer_state = XFER_STATE_IDLE;
    reg [3:0]  xfer_count = 0;
    reg [3:0]  xfer_dir = 0;
    reg [SPI_ADDR_BITS-1:0] xfer_addr = 0;
    reg [31:0] xfer_data = 0;
    assign spi_sel = (xfer_state == XFER_STATE_IDLE);
    assign spi_clk = (xfer_count == 0) || wb_clk_i;
    
    // Swap endianness when outputting data to wishbone.
    genvar i;
    generate
        for (i = 0; i < DW; i = i + 8) begin
            assign wb_dat_o[i+7 : i] = xfer_data[DW-i-1 : DW-i-8];
        end
    endgenerate
    
    // Output data on SPI clock falling edge.
    always @(negedge wb_clk_i) begin
        if (xfer_count != 0) begin
            spi_d_dir <= xfer_dir;
            spi_d_out <= xfer_data[DW-1:DW-4];
        end
    end
    
    // Update the state machine on rising edge.
    always @(posedge wb_clk_i) begin
        // Hold ACK until the read completes.
        wb_ack_o     <= 1'b0;
        
        // Transfer bits on rising edge.
        if (xfer_count != 0) begin
            xfer_count <= xfer_count - 1;
            xfer_data  <= {xfer_data[27:0], spi_d_in[3:0]};
        end
        // Change state when we run out of bits to transfer.
        else case (xfer_state)
            XFER_STATE_IDLE : begin
                // Start a new read command.
                if (wb_cyc_i && wb_stb_i) begin
                    xfer_state <= XFER_STATE_COMMAND;
                    xfer_addr  <= wb_addr_local;
                    xfer_dir   <= 4'b0001;
                    xfer_data  <= 32'h10111011; // 8'hEB with bit stuffing.
                    xfer_count <= 8;
                end
            end
            XFER_STATE_COMMAND : begin
                xfer_data[31:0] <= { xfer_addr, 8'd0 }; // include "mode" bits
                xfer_count <= 8;
                xfer_dir   <= 4'b1111;
                xfer_state <= XFER_STATE_ADDRESS;
            end
            XFER_STATE_ADDRESS : begin
                xfer_data  <= 0;
                xfer_count <= 8; // latency defaults to 8
                xfer_dir   <= 4'b0000;
                xfer_state <= XFER_STATE_DUMMY;
            end
            XFER_STATE_DUMMY : begin
                xfer_data  <= 0;
                xfer_count <= DW/4;
                xfer_dir   <= 4'b0000;
                xfer_state <= XFER_STATE_READ;
            end
            XFER_STATE_READ : begin
                wb_ack_o   <= 1'b1;
                xfer_addr  <= xfer_addr + (DW/8);
                xfer_count <= 0;
                xfer_dir   <= 4'b0000;
                xfer_state <= XFER_STATE_DONE;
            end
            XFER_STATE_DONE : begin
                if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                    // Continue the read command on sequential address.
                    if (xfer_addr == wb_addr_local) begin
                        xfer_data  <= 0;
                        xfer_dir   <= 4'b0000;
                        xfer_count <= DW/4;
                        xfer_state <= XFER_STATE_READ;
                    end
                    // Otherwise, start a new command on discontinuous addressing.
                    else begin
                        xfer_state <= XFER_STATE_IDLE;
                    end
                end
            end
            default : begin
                xfer_count <= 0;
                xfer_dir   <= 4'b0000;
                xfer_state <= XFER_STATE_IDLE;
            end
        endcase
    end

endmodule
