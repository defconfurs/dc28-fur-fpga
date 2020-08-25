module wb_usb_serial#(
	parameter	AW = 32,
    parameter   DW = 32,
    parameter   SIZE = 1024,
) (
    input           wb_clk_i,
    input           wb_reset_i,

    // Wishbone interface.
    input  [AW-1:0]     wb_adr_i,
    input  [DW-1:0]     wb_dat_i,
    output reg [DW-1:0] wb_dat_o,
    input               wb_we_i,
    input  [DW/8-1:0]   wb_sel_i,
    output reg          wb_ack_o,
    input               wb_cyc_i,
    input               wb_stb_i,

    // USB Physical interface.
    input  usb_clk,
    output usb_p_tx,
    output usb_n_tx,
    input  usb_p_rx,
    input  usb_n_rx,
    output usb_tx_en,

    // DFU Detach signal.
    output dfu_detach,
    output [4:0] debug
);

localparam USB_MAX_PACKET_SIZE = 32;
localparam USB_MAX_PACKET_BITS = $clog2(USB_MAX_PACKET_SIZE);

reg [7:0] uart_in_data = 8'h00;
reg uart_in_valid = 0;
wire uart_in_ready;

wire [7:0] uart_out_data;
wire uart_out_valid;
wire uart_out_get;

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

// Local register addresses - stolen from the ubiquitous NS16650
localparam REG_USART_RHR = 8'h00;   // Receive Holding Register
localparam REG_USART_THR = 8'h00;   // Transmit Holding Register
localparam REG_USART_IER = 8'h01;   // Interrupt Enable Register
localparam REG_USART_ISR = 8'h02;   // Interrupt Status Register
localparam REG_USART_FCR = 8'h02;   // FIFO Control Register
localparam REG_USART_LCR = 8'h03;   // Line Control Register
localparam REG_USART_MCR = 8'h04;   // Modem Control Register
localparam REG_USART_LSR = 8'h05;   // Line Status Register
localparam REG_USART_MSR = 8'h06;   // Modem Status Register
localparam REG_USART_SCRATCH = 8'h07;
// Extra registers, accessible when DLAB=1
localparam REG_USART_DLL = 8'h10;
localparam REG_USART_DLM = 8'h11;
localparam REG_USART_PLD = 8'h15;

reg [7:0] r_int_enable = 8'h00;
wire [7:0] r_int_status = {6'b000000, ~uart_in_valid, uart_out_valid};
reg [7:0] r_fifo_ctrl = 8'h00;
reg [7:0] r_line_ctrl = 8'h00;
reg [7:0] r_modem_ctrl = 8'h00;
reg [7:0] r_line_status = 8'h00;
reg [7:0] r_modem_status = 8'h00;
reg [7:0] r_scratch = 8'h00;
reg [15:0] r_divisor = 16'h00;
reg [7:0] r_prescaler = 8'h00;
wire r_lcr_dlab;
assign r_lcr_dlab = r_line_ctrl[7];

// Wishbone Glue
wire stb_valid;
wire [4:0] r_addr;
assign stb_valid = wb_cyc_i && wb_stb_i && !wb_ack_o;
assign r_addr = {r_lcr_dlab, wb_adr_i[3:0]};
assign uart_out_get = (stb_valid && ~wb_we_i) && (r_addr == REG_USART_RHR);
assign wb_txfifo_write_strobe = (stb_valid && wb_we_i) && (r_addr == REG_USART_THR);

// Read Port
wire [DW-9:0] wb_dat_nop = 0;
always @(posedge wb_clk_i) begin
    wb_ack_o <= stb_valid;

    if (stb_valid && ~wb_we_i) case (r_addr)
        REG_USART_RHR : wb_dat_o <= {wb_dat_nop, uart_out_data};
        REG_USART_IER : wb_dat_o <= {wb_dat_nop, r_int_enable};
        REG_USART_ISR : wb_dat_o <= {wb_dat_nop, r_int_status};
        REG_USART_LCR : wb_dat_o <= {wb_dat_nop, r_line_ctrl};
        REG_USART_MCR : wb_dat_o <= {wb_dat_nop, r_modem_ctrl};
        REG_USART_LSR : wb_dat_o <= {wb_dat_nop, r_line_status};
        REG_USART_MSR : wb_dat_o <= {wb_dat_nop, r_modem_status};
        REG_USART_SCRATCH : wb_dat_o <= {wb_dat_nop, r_scratch};
        REG_USART_DLL : wb_dat_o <= {wb_dat_nop, r_divisor[7:0]};
        REG_USART_DLM : wb_dat_o <= {wb_dat_nop, r_divisor[15:8]};
        REG_USART_PLD : wb_dat_o <= {wb_dat_nop, r_prescaler};
        default :       wb_dat_o <= 0;
    endcase
end

// Write Port
always @(posedge wb_clk_i) begin
    if (stb_valid && wb_we_i && wb_sel_i[0]) case (r_addr)
        REG_USART_THR : uart_in_data <= wb_dat_i[7:0];
        REG_USART_IER : r_int_enable <= wb_dat_i[7:0];
        REG_USART_FCR : r_fifo_ctrl  <= wb_dat_i[7:0];
        REG_USART_LCR : r_line_ctrl  <= wb_dat_i[7:0];
        REG_USART_MCR : r_modem_ctrl <= wb_dat_i[7:0];
        REG_USART_SCRATCH : r_scratch   <= wb_dat_i[7:0];
        REG_USART_DLL : r_divisor[7:0]  <= wb_dat_i[7:0];
        REG_USART_DLM : r_divisor[15:8] <= wb_dat_i[7:0];
        REG_USART_PLD : r_prescaler     <= wb_dat_i[7:0];
    endcase
end

assign debug[0] = uart_in_ready;
assign debug[1] = uart_in_valid;
assign debug[2] = uart_out_valid;
assign debug[3] = uart_out_get;

endmodule
