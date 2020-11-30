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

module wb_usb_serial#(
	parameter	AW = 32,
    parameter   DW = 32,
    parameter   SIZE = 1024,
) (
    input wire      wb_clk_i,
    input wire     wb_reset_i,

    // Wishbone interface.
    input wire [AW-1:0] wb_adr_i,
    input wire [DW-1:0] wb_dat_i,
    output reg [DW-1:0] wb_dat_o,
    input wire          wb_we_i,
    input wire [DW/8-1:0] wb_sel_i,
    output reg          wb_ack_o,
    input wire          wb_cyc_i,
    input wire          wb_stb_i,

    // USB Physical interface.
    input wire  usb_clk,
    output wire usb_p_tx,
    output wire usb_n_tx,
    input wire  usb_p_rx,
    input wire  usb_n_rx,
    output wire usb_tx_en,

    // Misc Signals.
    output wire irq,
    output wire dfu_detach,
    output wire [4:0] debug
);

localparam USB_MAX_PACKET_SIZE = 32;
localparam USB_MAX_PACKET_BITS = $clog2(USB_MAX_PACKET_SIZE);

reg [7:0] uart_in_data = 8'h00;
reg uart_in_valid = 0;
wire uart_in_ready;

wire [7:0] uart_out_data;
wire uart_out_valid;
wire uart_out_get;

wire uart_dtr;
wire uart_rts;

// USB Serial Core.
usb_serial_core usb_serial(
    .clk(wb_clk_i),
    .clk_48mhz(usb_clk),
    .reset(wb_reset_i),

    // USB lines.
    .usb_p_tx(usb_p_tx),
    .usb_n_tx(usb_n_tx),
    .usb_p_rx(usb_p_rx),
    .usb_n_rx(usb_n_rx),
    .usb_tx_en(usb_tx_en),

    // uart pipeline in (into the module, out of the device, into the host)
    .uart_in_data(uart_in_data),
    .uart_in_valid(uart_in_valid),
    .uart_in_ready(uart_in_ready),

    // uart pipeline out (out of the host, into the device, out of the module)
    .uart_out_data(uart_out_data),
    .uart_out_valid(uart_out_valid),
    .uart_out_get(uart_out_get),

    // uart control signals
    .uart_dtr(uart_dtr),
    .uart_rts(uart_rts),

    // DFU state and debug
    .dfu_detach(dfu_detach)
);

// Transmit FIFO.
wire wb_txfifo_write_strobe;
always @(posedge wb_clk_i) begin
    if (uart_in_ready) begin
        uart_in_valid <= 1'b0;
    end
    if (wb_txfifo_write_strobe) begin
        uart_in_valid <= 1'b1;
    end
end

localparam REG_USART_RXFIFO = 8'h00;    // Receive FIFO 
localparam REG_USART_TXFIFO = 8'h01;    // Transmit FIFO
localparam REG_USART_IER = 8'h02;       // Interrupt Enable Register
localparam REG_USART_ISR = 8'h03;       // Interrupt Status Register

reg [7:0] r_int_enable = 8'h00;
wire [7:0] r_int_status = {4'b0000, uart_rts, uart_dtr, ~uart_in_valid, uart_out_valid};
assign irq = (r_int_enable & r_int_status) != 0;

// Wishbone Glue
wire stb_valid;
wire [3:0] r_addr;
assign r_addr = wb_adr_i[3:0];
assign stb_valid = wb_cyc_i && wb_stb_i && !wb_ack_o;
assign uart_out_get = (stb_valid && ~wb_we_i) && (r_addr == REG_USART_RXFIFO);
assign wb_txfifo_write_strobe = (stb_valid && wb_we_i) && (r_addr == REG_USART_TXFIFO);

// Read Port
wire [DW-9:0] wb_dat_nop = 0;
always @(posedge wb_clk_i) begin
    wb_ack_o <= stb_valid;

    if (stb_valid && ~wb_we_i) case (r_addr)
        REG_USART_RXFIFO : wb_dat_o <= {wb_dat_nop, uart_out_data};
        REG_USART_TXFIFO : wb_dat_o <= {wb_dat_nop, uart_in_data};
        REG_USART_IER :    wb_dat_o <= {wb_dat_nop, r_int_enable};
        REG_USART_ISR :    wb_dat_o <= {wb_dat_nop, r_int_status};
        default :          wb_dat_o <= 0;
    endcase
end

// Write Port
always @(posedge wb_clk_i) begin
    if (stb_valid && wb_we_i && wb_sel_i[0]) case (r_addr)
        REG_USART_TXFIFO : uart_in_data <= wb_dat_i[7:0];
        REG_USART_IER :    r_int_enable <= wb_dat_i[7:0];
    endcase
end

assign debug[0] = uart_in_ready;
assign debug[1] = uart_in_valid;
assign debug[2] = uart_out_valid;
assign debug[3] = uart_out_get;

endmodule
