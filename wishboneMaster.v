`default_nettype none

module wishbone_master #(
    parameter ADDRESS_WIDTH = 16,
    parameter DATA_WIDTH = 8,
    parameter DATA_BYTES = 1,
    parameter MAX_WAIT = 8,
    parameter MAX_PAYLOAD = 8,
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
    input wire                          rst_i,
    input wire                          clk_i,

    output wire [ADDRESS_WIDTH-1:0]     adr_o,
    input wire [DATA_WIDTH-1:0]         dat_i,
    output wire [DATA_WIDTH-1:0]        dat_o,
    output wire                         we_o,
    output wire [DATA_BYTES-1:0]        sel_o,
    output wire                         stb_o,
    input wire                          cyc_i,
    output wire                         cyc_o,
    input wire                          ack_i,
    output wire [2:0]                   cti_o,

    // control interface
    input wire [ADDRESS_WIDTH-1:0]      transfer_address,
    input wire [INTERFACE_WIDTH-1:0]    payload_in,
    output wire [INTERFACE_WIDTH-1:0]   payload_out,
    input wire [INTERFACE_LENGTH_N-1:0] payload_length,
    input wire                          start_read,
    output reg                          read_busy,
    input wire                          start_write,
    output reg                          write_busy,
    output reg                          completed,
    output reg                          timeout
    );


    
    reg [INTERFACE_WIDTH-1:0] latched_payload_in;
    // convert to vector
    reg [DATA_WIDTH-1:0]  data_out [0:MAX_PAYLOAD-1];
    wire [DATA_WIDTH-1:0] data_in  [0:MAX_PAYLOAD-1];

    genvar                i;
    generate
        for(i = 1; i <= MAX_PAYLOAD; i = i+1) begin
            assign payload_out[(i*DATA_WIDTH)-1:((i-1)*DATA_WIDTH)] = data_out[i-1];
            assign data_in[i-1] = latched_payload_in[(i*DATA_WIDTH)-1:((i-1)*DATA_WIDTH)];
        end
    endgenerate

    

    reg [ADDRESS_WIDTH-1:0]      latched_address;
    reg [ADDRESS_WIDTH-1:0]      next_latched_address;
    reg [INTERFACE_LENGTH_N-1:0] length;
    reg [INTERFACE_LENGTH_N-1:0] next_length;
    reg                          next_completed;

    reg                          read_started;
    reg                          read_in_progress;
    reg                          write_started;
    reg                          write_in_progress;

    reg                          next_timeout;
    reg                          flag_timeout;
    
    //============================================================================================
    // Control state machine
    localparam STATE_IDLE        = 5'b00001;
    localparam STATE_START_READ  = 5'b00010;
    localparam STATE_READING     = 5'b00100;
    localparam STATE_START_WRITE = 5'b01000;
    localparam STATE_WRITING     = 5'b10000;
    
    reg [4:0] state;
    reg [4:0] next_state;
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state           <= STATE_IDLE;
            latched_address <= {ADDRESS_WIDTH{1'b0}};
            length          <= {INTERFACE_LENGTH_N{1'b0}};
            completed       <= 1'b0;
            timeout         <= 1'b0;
        end
        else begin
            state           <= next_state;
            latched_address <= next_latched_address;
            length          <= next_length;
            completed       <= next_completed;
            timeout         <= next_timeout;
        end
    end

    // latch the data so it doesn't change while writing
    always @(posedge clk_i) begin
        if (state == STATE_IDLE)
            latched_payload_in <= payload_in;
    end
    
    always @(*) begin
        next_state           = state;
        next_latched_address = latched_address;
        next_length          = length;
        read_busy            = 1'b0;
        write_busy           = 1'b0;
        next_completed       = completed;
        next_timeout         = timeout;
        
        case (state)
        STATE_IDLE: begin
            next_latched_address = transfer_address;
            next_length          = payload_length;
            
            if (start_read) begin
                next_state     = STATE_START_READ;
                next_completed = 1'b0;
                next_timeout   = 1'b0;
            end
            else if (start_write) begin
                next_state     = STATE_START_WRITE;
                next_completed = 1'b0;
                next_timeout   = 1'b0;
            end
        end

        STATE_START_READ: begin
            read_busy = 1'b1;
            if (read_started) next_state = STATE_READING;

            if (flag_timeout) begin
                next_timeout = 1'b1;
                next_state   = STATE_IDLE;
            end
        end

        STATE_READING: begin
            read_busy = 1'b1;
            if (!read_in_progress) begin
                next_state     = STATE_IDLE;
                next_completed = 1;
            end
            if (flag_timeout) begin
                next_timeout = 1'b1;
                next_state   = STATE_IDLE;
            end
        end

        STATE_START_WRITE: begin
            write_busy = 1'b1;
            if (write_started) next_state = STATE_WRITING;

            if (flag_timeout) begin
                next_timeout = 1'b1;
                next_state   = STATE_IDLE;
            end
        end

        STATE_WRITING: begin
            write_busy                         = 1'b1;
            if (!write_in_progress) begin
                next_state     = STATE_IDLE;
                next_completed = 1;
            end
            if (flag_timeout) begin
                next_timeout = 1'b1;
                next_state   = STATE_IDLE;
            end
        end
        
        default: begin
            next_state = STATE_IDLE;
        end
        endcase
    end


    
    


    /*  - Read Cycle -
     *        _   _   _   _   _   _   _   _   _   _   _   _   _   _   _
     * CLK_I / \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/
     *          |   |     | |          |     |        ||
     *           _________________________________  __
     * CTI_O XXX<_______________1_________________><_7>XXXXXXXXXXXXXXXXXXX
     *          |   |     | |          |     |        ||
     *           _____  __      __  __  ______  __  __
     * ADR_O XXX<____1><_2>XXXX<_3><_4><____5_><_6><_7>XXXXXXXXXXXXXXXXXXX
     *          |   |     | |          |     |        ||
     *              ___  __      __  __      __  __  __
     * DAT_I XXXXXX<__1><_2____><_3><_4>XXXX<_5><_6><_7>XXXXXXXXXXXXXXXXXX
     *          |   |     | |          |     |        ||
     * 
     * DAT_O XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
     *          |   |     | |          |     |        ||
     * 
     * WE_O  XXX\________________________________________/XXXXXXXXXXXXXXXX
     *          |   |     | |          |     |        ||
     *           ________________________________________
     * SEL_O XXX<________________________________________>XXXXXXXXXXXXXXXX
     *          |   |     | |          |     |        ||
     *           _________   ___________________________
     * STB_O ___/         \_/                           \_________________
     *          |   |     | |          |     |        ||
     *           ________________________________________
     * CYC_O ___/                                        \________________
     *          |   |     | |          |     |        ||
     *               _____   __________       _________
     * ACK_I _______/     \_/          \_____/         \__________________
     * 
     *          |   |     | |          |     |        ||
     *          A   B     C D          E     F        GH
     * 
     * A - Master initiates read
     * B - Slave has data ready and acknowledges
     * C - Master becomes not-ready and stalls
     * D - Master is ready again and continues
     * E - Slave becomes not-ready and stalls
     * F - Slave is ready again and acknowledges
     * G - Master finishes read
     * H - Slave completes read
     * 
     * Note that all signals are read on the rising edge. The slave showing delay is just that it transitions
     * during the clock cycle and is stable before the rising edge
     */

    reg [ADDRESS_WIDTH-1:0]      current_address_o;
    reg [INTERFACE_LENGTH_N-1:0] address_offset;
    reg [INTERFACE_LENGTH_N-1:0] next_address_offset;
    reg [INTERFACE_LENGTH_N-1:0] last_address_offset;
    wire [DATA_WIDTH-1:0]        current_data_o;
    reg                          current_we_o;
    reg [DATA_BYTES-1:0]         current_sel_o;
    reg                          current_stb_o;
    reg                          current_cycle_o;
    reg [2:0]                    current_cycle_type_out;
    
    localparam MAX_WAIT_N  = ((MAX_WAIT < 2) ? 1 :
                              (MAX_WAIT < 4) ? 2 :
                              (MAX_WAIT < 8) ? 3 :
                              (MAX_WAIT < 16) ? 4 :
                              (MAX_WAIT < 32) ? 5 :
                              (MAX_WAIT < 64) ? 6 :
                              (MAX_WAIT < 128) ? 7 : 8);
    reg [MAX_WAIT_N-1:0]         timeout_count;
    reg [MAX_WAIT_N-1:0]         next_timeout_count;
    

    always @(posedge clk_i or posedge rst_i) begin
        if(rst_i) begin
            last_address_offset <= ({INTERFACE_LENGTH_N{1'b0}});
            address_offset      <= ({INTERFACE_LENGTH_N{1'b0}});
            timeout_count       <= MAX_WAIT;
        end
        else begin
            last_address_offset <= address_offset;
            address_offset      <= next_address_offset;
            timeout_count       <= next_timeout_count;
        end
    end

    generate
        for(i = 1; i <= MAX_PAYLOAD; i = i+1) begin
            always @(posedge clk_i or posedge rst_i) begin
                if (rst_i) data_out[i-1] <= {DATA_WIDTH{1'b0}};
                else begin
                    if (state == STATE_READING && last_address_offset == i-1) begin
                        data_out[i-1] <= dat_i;
                    end
                end
            end

            assign current_data_o = ((state == STATE_WRITING && address_offset == i-1) ? data_in[i-1] : {DATA_WIDTH{1'bZ}});
        end
    endgenerate
    
    assign current_data_o = ((state != STATE_WRITING) ? {DATA_WIDTH{1'b0}} : {DATA_WIDTH{1'bZ}});

    always @(*) begin
        // defaults
        current_address_o      = {ADDRESS_WIDTH{1'b0}};
        current_we_o           = 1'b0;
        current_sel_o          = {DATA_BYTES{1'b0}};
        current_stb_o          = 1'b0;
        current_cycle_o        = 1'b0;
        current_cycle_type_out = 3'b000;

        next_address_offset    = {INTERFACE_LENGTH_N{1'b0}};
        read_started           = 1'b0;
        read_in_progress       = 1'b0;
        write_started          = 1'b0;
        write_in_progress      = 1'b0;

        next_timeout_count     = MAX_WAIT;
        flag_timeout           = 1'b0;


        case (state)
        
        STATE_IDLE: begin
        end
        
        STATE_START_READ: begin
            if (!cyc_i) begin
                read_started       = 1'b1;
                read_in_progress   = 1'b1;
                next_timeout_count = MAX_WAIT;
            end
            else begin
                if (timeout_count > 0) next_timeout_count = timeout_count - 1;
                else                   flag_timeout       = 1'b1;
            end
        end
            
        STATE_READING: begin
            current_cycle_o   = 1'b1;

            current_address_o = latched_address + address_offset;
            if (!timeout && ack_i) begin 
                next_address_offset = address_offset + 1;
                next_timeout_count  = MAX_WAIT;
            end
            else begin
                next_address_offset = address_offset;
                if (timeout_count > 0) next_timeout_count = timeout_count - 1;
                else                   flag_timeout       = 1'b1;
            end

            if (address_offset < length-1) current_cycle_type_out = 3'b010;
            else                           current_cycle_type_out = 3'b111;
            
            if (next_address_offset < length) read_in_progress      = 1'b1;
            else                              read_in_progress      = 1'b0;
        end
            
        STATE_START_WRITE: begin
            if (!cyc_i) begin
                write_started      = 1'b1;
                write_in_progress  = 1'b1;
                next_timeout_count = MAX_WAIT;
            end
            else begin
                if (timeout_count > 0) next_timeout_count = timeout_count - 1;
                else                   flag_timeout       = 1'b1;
            end
        end
            
        STATE_WRITING: begin
            current_we_o      = 1'b1;
            current_cycle_o   = 1'b1;

            current_address_o = latched_address + address_offset;
            if (!timeout && ack_i) begin 
                next_address_offset = address_offset + 1;
                next_timeout_count  = MAX_WAIT;
            end
            else begin
                next_address_offset = address_offset;
                if (timeout_count > 0) next_timeout_count = timeout_count - 1;
                else                   flag_timeout       = 1'b1;
            end

            if (address_offset < length-1) current_cycle_type_out = 3'b010;
            else                           current_cycle_type_out = 3'b111;
            
            if (next_address_offset < length) write_in_progress      = 1'b1;
            else                              write_in_progress      = 1'b0;
            
        end
        
        endcase

    end

    
    
    assign adr_o = current_address_o;
    assign dat_o = current_data_o;
    assign we_o  = current_we_o;
    assign sel_o = current_sel_o;
    assign stb_o = current_stb_o;
    assign cyc_o = current_cycle_o;
    assign cti_o = current_cycle_type_out;

endmodule
