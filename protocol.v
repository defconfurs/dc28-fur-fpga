module protocol #(
    parameter integer ADDRESS_WIDTH = 16,
    parameter integer DATA_WIDTH    = 8,
    parameter integer DATA_BYTES    = 1,
    parameter integer MAX_WAIT      = 8,
    parameter integer MAX_PAYLOAD   = 4,
    // non-user-editable
    parameter INTERFACE_WIDTH = (MAX_PAYLOAD * DATA_WIDTH),
    parameter INTERFACE_LENGTH_N = ((MAX_PAYLOAD <=  2) ? 2 :
                                    (MAX_PAYLOAD <=  4) ? 3 :
                                    (MAX_PAYLOAD <=  8) ? 4 :
                                    (MAX_PAYLOAD <= 16) ? 5 :
                                    (MAX_PAYLOAD <= 32) ? 6 :
                                    /*           <= 64 */ 7)
)  (
    // Wishbone interface
    input wire                      rst_i,
    input wire                      clk_i,
    input wire                      clk_48mhz,

    output wire [ADDRESS_WIDTH-1:0] adr_o,
    input wire [DATA_WIDTH-1:0]     dat_i,
    output wire [DATA_WIDTH-1:0]    dat_o,
    output wire                     we_o,
    output wire [DATA_BYTES-1:0]    sel_o,
    output wire                     stb_o,
    input wire                      cyc_i,
    output wire                     cyc_o,
    input wire                      ack_i,
    output wire [2:0]               cti_o,

    // Aux interfaces
    input wire [7:0]                rx_byte,
    input wire                      rx_byte_valid,
    output reg                      rx_ready,
    
    output reg [7:0]                tx_byte,
    output reg                      tx_byte_valid,
    input wire                      tx_ready
    );


    // control interface
    reg [ADDRESS_WIDTH-1:0]      transfer_address;
    wire [INTERFACE_WIDTH-1:0]   payload_in;
    wire [INTERFACE_WIDTH-1:0]   payload_out;
    reg [INTERFACE_LENGTH_N-1:0] payload_length;
    reg                          start_read;
    wire                         read_busy;
    reg                          start_write;
    wire                         write_busy;
    wire                         completed;
    wire                         timeout;

    // housekeeping to make arrays
    reg [DATA_WIDTH-1:0] data_out [0:MAX_PAYLOAD-1];
    wire [DATA_WIDTH-1:0] data_in  [0:MAX_PAYLOAD-1];
    genvar                i;
    generate
        for(i = 1; i <= MAX_PAYLOAD; i = i+1) begin
            assign payload_in[(i*DATA_WIDTH)-1:((i-1)*DATA_WIDTH)] = data_out[i-1];
            assign data_in[i-1] = payload_out[(i*DATA_WIDTH)-1:((i-1)*DATA_WIDTH)];
        end
    endgenerate

    wishbone_master #(
        .ADDRESS_WIDTH (ADDRESS_WIDTH),
        .DATA_WIDTH    (DATA_WIDTH),
        .DATA_BYTES    (DATA_BYTES),
        .MAX_WAIT      (MAX_WAIT),
        .MAX_PAYLOAD   (MAX_PAYLOAD)
    ) wb_master (
        // Wishbone interface
        .rst_i           ( rst_i            ),
        .clk_i           ( clk_i            ),
        .adr_o           ( adr_o            ),
        .dat_i           ( dat_i            ),
        .dat_o           ( dat_o            ),
        .we_o            ( we_o             ),
        .sel_o           ( sel_o            ),
        .stb_o           ( stb_o            ),
        .cyc_i           ( cyc_i            ),
        .cyc_o           ( cyc_o            ),
        .ack_i           ( ack_i            ),
        .cti_o           ( cti_o            ),

        // packet interface
        .transfer_address( transfer_address ),
        .payload_in      ( payload_in       ),
        .payload_out     ( payload_out      ),
        .payload_length  ( payload_length   ),
        .start_read      ( start_read       ),
        .read_busy       ( read_busy        ),
        .start_write     ( start_write      ),
        .write_busy      ( write_busy       ),
        .completed       ( completed        ),
        .timeout         ( timeout          )
    );

    

    reg [3:0]          local_state;
    reg [3:0]          next_local_state;
    
    localparam STATE_RX_MARK         = 11'b00000000001;
    localparam STATE_RX_COMMAND      = 11'b00000000010;
    localparam STATE_RX_ASCII_ADDR   = 11'b00000000100;
    localparam STATE_RX_ASCII_DATA   = 11'b00000001000;
    localparam STATE_READ_OPERATION  = 11'b00000010000;
    localparam STATE_WRITE_OPERATION = 11'b00000100000;
    localparam STATE_TX_ASCII_DATA   = 11'b00001000000;
    localparam STATE_TX_BINARY_DATA  = 11'b00010000000;
    localparam STATE_TX_ASCII_ERROR  = 11'b00100000000;
    localparam STATE_TX_BINARY_ERROR = 11'b01000000000;
    localparam STATE_END_NEWLINE     = 11'b10000000000;

    localparam ERROR_COMMAND_FAILURE = 8'h01;
    localparam ERROR_NON_NUMBER      = 8'h02;
    localparam ERROR_NO_RESPONSE     = 8'h03;
    localparam ERROR_TIMEOUT         = 8'h04;
    
    
    reg [10:0]         state;
    reg [10:0]         next_state;
    reg                ascii_mode;
    reg                next_ascii_mode;
    reg                write_mode;
    reg                next_write_mode;
    reg [7:0]          error_code;
    reg [7:0]          next_error_code;

    reg [ADDRESS_WIDTH-1:0]      next_transfer_address;
    reg [DATA_WIDTH-1:0]         next_data_out [0:MAX_PAYLOAD-1];
    reg [INTERFACE_LENGTH_N-1:0] next_payload_length;
    
    always @(posedge clk_48mhz or posedge rst_i) begin
        if (rst_i) begin
            state            <= STATE_RX_MARK;
            ascii_mode       <= 1'b0;
            write_mode       <= 1'b0;
            error_code       <= 8'd0;
            transfer_address <= 16'd0;
            local_state      <= 3'd0;
            payload_length   <= 1;
        end
        else begin
            state            <= next_state;
            ascii_mode       <= next_ascii_mode;
            write_mode       <= next_write_mode;
            error_code       <= next_error_code;
            transfer_address <= next_transfer_address;
            local_state      <= next_local_state;
            payload_length   <= next_payload_length;
        end
    end
    generate
        for (i = 0; i < MAX_PAYLOAD; i = i+1) begin
            always @(posedge clk_48mhz or posedge rst_i) begin
                if (rst_i) data_out[i] <= 8'd0;
                else       data_out[i] <= next_data_out[i];
            end
        end
    endgenerate

    // helper to get the value of the incoming byte
    wire [3:0] rx_digit;
    assign rx_digit = (rx_byte <  "0" ? 4'd0 :
                       rx_byte <= "9" ? rx_byte - "0" :
                       rx_byte <  "A" ? 4'd0 :
                       rx_byte <= "F" ? rx_byte - "A" + 4'hA :
                       rx_byte <  "a" ? 4'd0 :
                       rx_byte <= "f" ? rx_byte - "a" + 4'hA : 4'd0);
    wire       rx_digit_error;
    assign rx_digit_error = (rx_byte <  "0" ? 1'b1 :
                             rx_byte <= "9" ? 1'b0 :
                             rx_byte <  "A" ? 1'b1 :
                             rx_byte <= "F" ? 1'b0 :
                             rx_byte <  "a" ? 1'b1 :
                             rx_byte <= "f" ? 1'b0 : 1'b1);
    

    reg [3:0]  tx_digit;
    wire [7:0] tx_ascii;
    assign tx_ascii  = (tx_digit <= 4'd9 ? tx_digit + "0" : tx_digit - 4'hA + "A");
    
    
    always @(*) begin
        next_state            = state;
        next_local_state      = local_state;
        
        next_ascii_mode       = ascii_mode;
        next_write_mode       = write_mode;
        next_error_code       = error_code;
        next_transfer_address = transfer_address;
        start_read            = 1'b0;
        start_write           = 1'b0;
        tx_byte               = 8'd0;
        tx_byte_valid         = 1'b0;
        tx_digit              = 4'd0;

        next_data_out[0]      = data_out[0];
        next_data_out[1]      = data_out[1];
        next_data_out[2]      = data_out[2];
        next_data_out[3]      = data_out[3];

        next_payload_length   = payload_length;
        rx_ready              = 0;
        
        case (state)
        STATE_RX_MARK: begin
            rx_ready = 1;
            
            if (rx_byte_valid && (rx_byte == "?")) begin
                  next_state = STATE_RX_COMMAND;
            end
        end

        STATE_RX_COMMAND: begin
            next_local_state = 0;
            rx_ready         = 1;
            
            if (rx_byte_valid) begin
                next_local_state = 0;
                if (rx_byte == "r") begin
                    next_ascii_mode  = 1'b1;
                    next_write_mode  = 1'b0;
                    next_state       = STATE_RX_ASCII_ADDR;
                end
                else if (rx_byte == "w") begin
                    next_ascii_mode  = 1'b1;
                    next_write_mode  = 1'b1;
                    next_state       = STATE_RX_ASCII_ADDR;
                end
                else begin
                    next_ascii_mode  = 1'b1;
                    next_write_mode  = 1'b0;
                    next_error_code  = ERROR_COMMAND_FAILURE;
                    next_state       = STATE_TX_ASCII_ERROR;
                end
            end
        end
        
        STATE_RX_ASCII_ADDR : begin
            rx_ready  = 1;
            
            if (rx_byte_valid) begin
                if (rx_digit_error) begin
                    next_error_code  = ERROR_NON_NUMBER;
                    next_local_state = 0;
                    next_state       = STATE_TX_ASCII_ERROR;
                end
                else if (local_state == 0) begin next_transfer_address[15:12] = rx_digit;  next_local_state = 1; end
                else if (local_state == 1) begin next_transfer_address[11: 8] = rx_digit;  next_local_state = 2; end
                else if (local_state == 2) begin next_transfer_address[ 7: 4] = rx_digit;  next_local_state = 3; end
                else                       begin next_transfer_address[ 3: 0] = rx_digit;  next_local_state = 0;
                    if (write_mode)
                        next_state  = STATE_RX_ASCII_DATA;
                    else next_state = STATE_READ_OPERATION;
                end
            end
        end
        
        STATE_RX_ASCII_DATA : begin
            rx_ready  = 1;
            
            if (rx_byte_valid) begin
                if (rx_digit_error) begin
                    next_error_code  = ERROR_NON_NUMBER;
                    next_local_state = 0;
                    next_state       = STATE_TX_ASCII_ERROR;
                end
                else if (local_state == 0) begin next_data_out[0][7:4] = rx_digit;  next_local_state = 1; end
                else                       begin next_data_out[0][3:0] = rx_digit;  next_local_state = 0; next_state = STATE_WRITE_OPERATION; end
            end
        end
        
        STATE_READ_OPERATION  : begin
            if (local_state == 0) begin
                start_read       = 1;
                next_local_state = 1;
            end
            else if (local_state == 1) begin
                if (!read_busy) begin
                    start_read = 1;
                end
                else begin
                    next_local_state = 2;
                    start_read       = 0;
                end
            end
            else if (local_state == 2) begin
                if (!read_busy) begin
                    next_local_state = 0;
                    
                    if (cyc_i && timeout) begin
                        next_error_code = ERROR_TIMEOUT;
                        
                        if (ascii_mode) next_state = STATE_TX_ASCII_ERROR;
                        else            next_state = STATE_TX_BINARY_ERROR;
                        
                    end
                    else if (timeout) begin
                        next_error_code = ERROR_NO_RESPONSE;
                        
                        if (ascii_mode) next_state = STATE_TX_ASCII_ERROR;
                        else            next_state = STATE_TX_BINARY_ERROR;
                    end
                    else begin
                        if (ascii_mode) next_state = STATE_TX_ASCII_DATA;
                        else            next_state = STATE_TX_BINARY_DATA;
                    end
                end
            end
            else next_local_state = 0; // error
        end
        
        STATE_WRITE_OPERATION : begin
            if (local_state == 0) begin
                start_write      = 1;
                next_local_state = 1;
            end
            else if (local_state == 1) begin
                start_write = 1;
                if (write_busy) next_local_state = 2;
            end
            else if (local_state == 2) begin
                if (!write_busy) begin
                    if (cyc_i && timeout) begin
                        next_local_state = 0;
                        next_error_code = ERROR_TIMEOUT;
                        
                        if (ascii_mode) next_state = STATE_TX_ASCII_ERROR;
                        else            next_state = STATE_TX_BINARY_ERROR;
                        
                    end
                    else if (timeout) begin
                        next_local_state = 0;
                        next_error_code = ERROR_NO_RESPONSE;
                        
                        if (ascii_mode) next_state = STATE_TX_ASCII_ERROR;
                        else            next_state = STATE_TX_BINARY_ERROR;
                    end
                    else begin
                        next_local_state = 3;
                    end
                end
            end
            else if (local_state == 3) begin
                tx_byte       = "O";
                tx_byte_valid = 1'b1;

                if (tx_ready) begin
                    next_local_state = 4;
                end
            end
            else if (local_state == 4) begin
                tx_byte       = "K";
                tx_byte_valid = 1'b1;

                if (tx_ready) begin
                    next_local_state = 0;
                    next_state       = STATE_END_NEWLINE;
                end
            end
            else next_local_state = 0; // error
        end
        
        STATE_TX_ASCII_DATA : begin
            if (local_state == 0) tx_digit = data_in[0][7:4];
            else                     tx_digit = data_in[0][3:0];

            tx_byte_valid = 1'b1;
            if (tx_ready) begin
                if      (local_state == 0) begin next_local_state = 1; end
                else                       begin next_local_state = 0;
                    next_state = STATE_END_NEWLINE;
                end
            end
            
            tx_byte = tx_ascii;
        end

        STATE_TX_BINARY_DATA : begin
            // TODO: add binary mode
            next_local_state = 0;
            next_state       = STATE_END_NEWLINE;
        end
        
        STATE_TX_ASCII_ERROR : begin
            // select which letter is current
            if (error_code == ERROR_COMMAND_FAILURE) begin
                if      (local_state == 0) tx_byte = "c"; // cmd err
                else if (local_state == 1) tx_byte = "m";
                else if (local_state == 2) tx_byte = "d";
                else if (local_state == 3) tx_byte = "e";
                else if (local_state == 4) tx_byte = "r";
                else if (local_state == 5) tx_byte = "r";
                else if (local_state == 6) tx_byte = "!";
                else tx_byte = 8'd0;
            end

            else if (error_code == ERROR_NON_NUMBER) begin
                if      (local_state == 0) tx_byte = "h"; // hex only
                else if (local_state == 1) tx_byte = "e";
                else if (local_state == 2) tx_byte = "x";
                else if (local_state == 3) tx_byte = " ";
                else if (local_state == 4) tx_byte = "o";
                else if (local_state == 5) tx_byte = "n";
                else if (local_state == 6) tx_byte = "l";
                else if (local_state == 7) tx_byte = "y";
                else if (local_state == 8) tx_byte = "!";
                else tx_byte = 8'd0;
            end

            else if (error_code == ERROR_NO_RESPONSE) begin
                if      (local_state == 0) tx_byte = "n"; // no resp
                else if (local_state == 1) tx_byte = "o";
                else if (local_state == 2) tx_byte = " ";
                else if (local_state == 3) tx_byte = "r";
                else if (local_state == 4) tx_byte = "e";
                else if (local_state == 5) tx_byte = "s";
                else if (local_state == 6) tx_byte = "p";
                else if (local_state == 7) tx_byte = "!";
                else tx_byte = 8'd0;
            end

            else if (error_code == ERROR_NON_NUMBER) begin
                if      (local_state == 0) tx_byte = "a"; // arb fail
                else if (local_state == 1) tx_byte = "r";
                else if (local_state == 2) tx_byte = "b";
                else if (local_state == 3) tx_byte = "f";
                else if (local_state == 4) tx_byte = "a";
                else if (local_state == 5) tx_byte = "i";
                else if (local_state == 6) tx_byte = "k";
                else if (local_state == 7) tx_byte = "!";
                else tx_byte = 8'd0;
            end
            // default to skip
            else tx_byte = 8'd0;

            if (tx_byte != 8'd0) begin
                tx_byte_valid    = 1'b1;
                if (tx_ready) begin
                    next_local_state = local_state + 1;
                end
            end
            else begin
                next_local_state = 0;
                next_state       = STATE_END_NEWLINE;
            end
        end
        
        STATE_TX_BINARY_ERROR : begin
            // TODO: add binary mode
            next_local_state = 0;
            next_state       = STATE_END_NEWLINE;
        end

        STATE_END_NEWLINE : begin
            tx_byte          = "\n";
            tx_byte_valid    = 1'b1;
            
            if (tx_ready) begin
                next_local_state = 0;
                next_state       = STATE_RX_MARK;
            end
        end
        
        endcase
    end
endmodule
