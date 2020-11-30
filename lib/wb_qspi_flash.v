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

module wb_qspi_flash #(
    parameter AW   = 24,
    parameter DW   = 32
)  (
    input wire              wb_reset_i,
    input wire              wb_clk_i,

    // Wishbone interface
    input wire [AW-1:0]     wb_adr_i,
    input wire [DW-1:0]     wb_dat_i,
    output wire [DW-1:0]    wb_dat_o,
    input wire              wb_we_i,
    input wire [(DW/8)-1:0] wb_sel_i,
    input wire              wb_stb_i,
    input wire              wb_cyc_i,
    output reg              wb_ack_o,

    // (Q)SPI interface
    output wire             spi_clk,
    output wire             spi_sel,
    output reg [3:0]        spi_d_out,
    input wire [3:0]        spi_d_in,
    output reg [3:0]        spi_d_dir,
    
    output wire [3:0]       debug
    );
    
    localparam XFER_STATE_INIT      = 4'h0; /* Reset state */
    localparam XFER_STATE_WR_CSEL   = 4'h1; /* Release CSEL after write-enable. */
    localparam XFER_STATE_IDLE      = 4'h3; /* Flash is idle and ready for access. */
    localparam XFER_STATE_WR_ENABLE = 4'h4; /* Sending a Write-Enable command. */
    localparam XFER_STATE_WR_STATUS = 4'h5; /* Writing to the status registers. */
    localparam XFER_STATE_COMMAND   = 4'h6; /* Issuing a read command. */
    localparam XFER_STATE_ADDRESS   = 4'h7; /* Issuing the read address and XIP mode bits. */
    localparam XFER_STATE_DUMMY     = 4'h8; /* Dummy clocks for the flash read latency. */
    localparam XFER_STATE_READ      = 4'h9; /* Transferring data from the flash. */
    localparam XFER_STATE_DONE      = 4'hA; /* Waiting with CSEL active for a sequential access. */
    
    localparam SPI_XIP_MODE_BITS  = 8'h00;
    localparam SPI_WRENV_COMMAND  = 8'h50;  /* Write-Enable to Volatile Registers command. */
    localparam SPI_WR_REG_COMMAND = 8'h01;  /* Write Status Registers command. */
    localparam SPI_READ_COMMAND   = 8'hEB;  /* Quad I/O Read command (1-4-4) */
    localparam SPI_READ_DUMMY_CLOCKS = 8;   /* Cypress S25064L Series - 8 dummy clocks. */

    assign debug = {1'b0,
                    xfer_state == XFER_STATE_IDLE,
                    xfer_state == XFER_STATE_WR_ENABLE,
                    xfer_state == XFER_STATE_INIT};
                    
    
    localparam SPI_ADDR_BITS = 24;
    localparam WB_ADDR_BITS = SPI_ADDR_BITS-$clog2(DW/8);
    wire [SPI_ADDR_BITS-1:0] wb_addr_local;
    assign wb_addr_local = wb_adr_i[WB_ADDR_BITS-1:0] * (DW/8);
    
    reg [3:0]  xfer_state = XFER_STATE_INIT;
    reg [5:0]  xfer_bits = 0;
    reg [3:0]  xfer_dir = 0;
    reg [SPI_ADDR_BITS-1:0] xfer_addr = 0;
    reg [31:0] xfer_data = 0;
    assign spi_sel = (xfer_state <= XFER_STATE_IDLE);
    assign spi_clk = (xfer_bits == 0) || wb_clk_i;
    
    // Swap endianness when outputting data to wishbone.
    genvar i;
    generate
        for (i = 0; i < DW; i = i + 8) begin
            assign wb_dat_o[i+7 : i] = xfer_data[DW-i-1 : DW-i-8];
        end
    endgenerate
    
    // Output data on SPI clock falling edge.
    always @(negedge wb_clk_i) begin
        if (xfer_bits != 0) begin
            spi_d_dir <= xfer_dir;
            if (xfer_dir == 4'b0001) begin
                // SPI mode
                spi_d_out <= {3'b000, xfer_data[DW-1]};
            end else begin
                // Quad mode
                spi_d_out <= xfer_data[DW-1:DW-4];
            end
        end
    end
    
    // Update the state machine on rising edge.
    always @(posedge wb_clk_i) begin
        // Hold ACK until the read completes.
        wb_ack_o     <= 1'b0;

        // Reset back into the init state.
        if (wb_reset_i) begin
            xfer_bits  <= 0;
            xfer_dir   <= 4'b0000;
            xfer_state <= XFER_STATE_INIT;
        end
        // Transfer bits on rising edge.
        else if (xfer_bits != 0) begin
            if (xfer_dir == 4'b0001) begin
                // SPI mode
                xfer_bits <= xfer_bits - 1;
                xfer_data <= {xfer_data[30:0], spi_d_in[1]};
            end else begin
                // Quad mode
                xfer_bits <= xfer_bits - 4;
                xfer_data <= {xfer_data[27:0], spi_d_in[3:0]};
            end
        end
        // Change state when we run out of bits to transfer.
        else case (xfer_state)
            XFER_STATE_INIT : begin
                // Start by enabling writes to the volatile status registers.
                xfer_state <= XFER_STATE_WR_ENABLE;
                xfer_data  <= {SPI_WRENV_COMMAND, 24'b0};
                xfer_dir   <= 4'b0001;
                xfer_bits  <= 8;
            end
            XFER_STATE_WR_ENABLE : begin
                // Hold CSEL low for a few clocks.
                xfer_state <= XFER_STATE_WR_CSEL;
                xfer_data  <= 32'b0;
                xfer_dir   <= 4'b0001;
                xfer_bits  <= 8;
            end
            XFER_STATE_WR_CSEL : begin
                // Write the volatile status and config registers.
                xfer_state <= XFER_STATE_WR_STATUS;
                xfer_dir   <= 4'b0001;
                xfer_bits <= 24;
                xfer_data <= {
                    SPI_WR_REG_COMMAND,
                    8'h00, // Status Register 1 Volatile (No Register protection)
                    8'h02, // Config Register 1 Volatile (Quad I/O enabled)
                    8'h00  // Padding - not sent.
                };
            end
            XFER_STATE_WR_STATUS : begin
                // The flash is idle after writing the status registers.
                xfer_bits  <= 0;
                xfer_dir   <= 4'b0000;
                xfer_state <= XFER_STATE_IDLE;
            end
            XFER_STATE_IDLE : begin
                // Start a new read command.
                if (wb_cyc_i && wb_stb_i) begin
                    xfer_state <= XFER_STATE_COMMAND;
                    xfer_addr  <= wb_addr_local;
                    xfer_dir   <= 4'b0001;
                    xfer_data  <= {SPI_READ_COMMAND, 24'b0};
                    xfer_bits  <= 8;
                end
            end
            XFER_STATE_COMMAND : begin
                // Send the address and XIP mode bits after the command.
                xfer_data[31:0] <= { xfer_addr, SPI_XIP_MODE_BITS };
                xfer_bits  <= 32;
                xfer_dir   <= 4'b1111;
                xfer_state <= XFER_STATE_ADDRESS;
            end
            XFER_STATE_ADDRESS : begin
                // Send dummy clocks after the address and mode bits.
                xfer_data  <= 0;
                xfer_bits  <= (SPI_READ_DUMMY_CLOCKS * 4);
                xfer_dir   <= 4'b0000;
                xfer_state <= XFER_STATE_DUMMY;
            end
            XFER_STATE_DUMMY : begin
                // Receive data after the dummy clocks.
                xfer_data  <= 0;
                xfer_bits  <= DW;
                xfer_dir   <= 4'b0000;
                xfer_state <= XFER_STATE_READ;
            end
            XFER_STATE_READ : begin
                // Send the wishbone ACK when read completes, and
                // switch to the DONE state to leave CSEL active
                // in case we get a sequential access.
                wb_ack_o   <= 1'b1;
                xfer_addr  <= xfer_addr + (DW/8);
                xfer_bits  <= 0;
                xfer_dir   <= 4'b0000;
                xfer_state <= XFER_STATE_DONE;
            end
            XFER_STATE_DONE : begin
                if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                    // Continue the read command on sequential addressing.
                    if (xfer_addr == wb_addr_local) begin
                        xfer_data  <= 0;
                        xfer_dir   <= 4'b0000;
                        xfer_bits  <= DW;
                        xfer_state <= XFER_STATE_READ;
                    end
                    // Otherwise, start a new command on discontinuous addressing.
                    else begin
                        xfer_state <= XFER_STATE_IDLE;
                    end
                end
            end
            default : begin
                xfer_bits  <= 0;
                xfer_dir   <= 4'b0000;
                xfer_state <= XFER_STATE_IDLE;
            end
        endcase
    end

endmodule
