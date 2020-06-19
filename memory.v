`default_nettype none

module wishbone_memory #(
    parameter ADDRESS_WIDTH = 16,
    parameter DATA_WIDTH = 8,
    parameter DATA_BYTES = 1,
    parameter BASE_ADDRESS = 0,
    parameter MEMORY_SIZE = 512
)  (
    // Wishbone interface
    input wire                     rst_i,
    input wire                     clk_i,

    input wire [ADDRESS_WIDTH-1:0] adr_i,
    input wire [DATA_WIDTH-1:0]    dat_i,
    output wire [DATA_WIDTH-1:0]   dat_o,
    input wire                     we_i,
    input wire [DATA_BYTES-1:0]    sel_i,
    input wire                     stb_i,
    input wire                     cyc_i,
    output reg                     ack_o,
    input wire [2:0]               cti_i
    );

    localparam MEMORY_SIZE_I  = (MEMORY_SIZE <=  512 ? 9 :
                                 MEMORY_SIZE <= 1024 ? 10 :
                                 MEMORY_SIZE <= 2048 ? 11 : 
                                 MEMORY_SIZE <= 4096 ? 12 :
                                 MEMORY_SIZE <= 8192 ? 13 :
                                 MEMORY_SIZE <= 16384 ? 14 :
                                 MEMORY_SIZE <= 32768 ? 15 : 16);
    
    wire [ADDRESS_WIDTH-1:0] local_address;
    wire                     valid_address;
    assign local_address = adr_i - BASE_ADDRESS;
    assign valid_address = local_address < MEMORY_SIZE;

    always @(posedge clk_i) begin
        ack_o <= cyc_i & valid_address;
    end

    generate
        if (MEMORY_SIZE == 32768) begin
            simple_spram_8 memory_inst (
                .clk     ( clk_i ),
                .address ( local_address[14:0] ),
                .din     ( dat_i ),
                .dout    ( dat_o ),
                .we      ( cyc_i & valid_address & we_i ),
                .sleep   ( ~(cyc_i & valid_address) )
            );
        end
        else begin
            simple_ram #(
                .addr_width( MEMORY_SIZE_I ),
                .data_width( DATA_WIDTH )
            ) memory_inst (
                .clk     ( clk_i ),
                .address ( local_address[MEMORY_SIZE_I-1:0] ),
                .din     ( dat_i ),
                .dout    ( dat_o ),
                .we      ( cyc_i & valid_address & we_i )
            );
        end
    endgenerate
    
endmodule

module simple_spram_8 #(
)  (
    input wire        clk,
    input wire [14:0] address,
    input wire [7:0]  din,
    output wire [7:0] dout,
    input wire        we,
    input wire        sleep
    );

    wire [15:0]       read_port;
    wire [15:0]       write_port;
    wire [3:0]        maskwren;

    assign write_port = { din, din };

    wire              upper_byte;
    wire              lower_byte;
    assign upper_byte = we & address[0];
    assign lower_byte = we & ~address[0];
    assign maskwren = { upper_byte, upper_byte, lower_byte, lower_byte };
    
    SB_SPRAM256KA ramfn_inst1(
        .CLOCK      ( clk ),
        .STANDBY    ( 0 ),
        .SLEEP      ( sleep ),
        .POWEROFF   ( 0 ),

        .ADDRESS    ( address[14:1] ),
        .DATAIN     ( write_port ),
        .MASKWREN   ( maskwren ),
        .WREN       ( we ),
        .CHIPSELECT ( 1 ),
        .DATAOUT    ( read_port )
    );

    assign dout = (address[0] ? read_port[15:8] : read_port[7:0]);
    
    //reg [15:0]      mem [13:0];
    //
    //always @(posedge clk) begin
    //    if      (we && !address[0]) mem[address[14:1]] <= {mem[address[14:1]][15:8], din};
    //    else if (we &&  address[0]) mem[address[14:1]] <= {din, mem[address[14:1]][7:0]};
    //    
    //    if (address[0]) dout <= mem[address[14:1]][15:8];
    //    else            dout <= mem[address[14:1]][7:0];
    //end
endmodule

    
module simple_ram #(//512x8
    parameter addr_width = 9,
    parameter data_width = 8
)  (
    input wire                  clk,
    input wire [addr_width-1:0] address, 
    input wire [data_width-1:0] din,
    output reg [data_width-1:0] dout,
    input wire                  we
    );
    
    reg [data_width-1:0] mem [(1<<addr_width)-1:0];
    
    always @(posedge clk) // Write memory.
    begin
        if (we)
            mem[address] <= din; // Using write address bus.
        dout <= mem[address]; // Using read address bus.
    end
endmodule    
