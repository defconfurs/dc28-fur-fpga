module parallel_to_bus32 (
    input wire i00,
    input wire i01,
    input wire i02,
    input wire i03,
    input wire i04,
    input wire i05,
    input wire i06,
    input wire i07,
    input wire i08,
    input wire i09,
    input wire i10,
    input wire i11,
    input wire i12,
    input wire i13,
    input wire i14,
    input wire i15,
    input wire i16,
    input wire i17,
    input wire i18,
    input wire i19,
    input wire i20,
    input wire i21,
    input wire i22,
    input wire i23,
    input wire i24,
    input wire i25,
    input wire i26,
    input wire i27,
    input wire i28,
    input wire i29,
    input wire i30,
    input wire i31,
    output wire [31:0] bus
    );

    assign bus[ 0] = i00;
    assign bus[ 1] = i01;
    assign bus[ 2] = i02;
    assign bus[ 3] = i03;
    assign bus[ 4] = i04;
    assign bus[ 5] = i05;
    assign bus[ 6] = i06;
    assign bus[ 7] = i07;
    assign bus[ 8] = i08;
    assign bus[ 9] = i09;
    assign bus[10] = i10;
    assign bus[11] = i11;
    assign bus[12] = i12;
    assign bus[13] = i13;
    assign bus[14] = i14;
    assign bus[15] = i15;
    assign bus[16] = i16;
    assign bus[17] = i17;
    assign bus[18] = i18;
    assign bus[19] = i19;
    assign bus[20] = i20;
    assign bus[21] = i21;
    assign bus[22] = i22;
    assign bus[23] = i23;
    assign bus[24] = i24;
    assign bus[25] = i25;
    assign bus[26] = i26;
    assign bus[27] = i27;
    assign bus[28] = i28;
    assign bus[29] = i29;
    assign bus[30] = i30;
    assign bus[31] = i31;
    

endmodule
