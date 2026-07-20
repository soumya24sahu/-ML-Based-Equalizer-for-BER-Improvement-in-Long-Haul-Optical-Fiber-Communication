`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.07.2026 02:19:45
// Design Name: 
// Module Name: fblookahead
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fblookahead(output carry_out,
    output [3:0] sum,
    input  [3:0] A, B,
    input  Cin
);
    wire [3:0] Ci; // Carry intermediate for intermediate computation
    wire w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14;

    assign Ci[0] = Cin;

    // First bit calculations
    and and1(w1, A[0], B[0]);
    xor xor1(w2, A[0], B[0]);
    and and2(w3, w2, Ci[0]);
    or  or1(Ci[1], w1, w3);

    // Second bit calculations
    and and3(w4, A[1], B[1]);
    xor xor2(w5, A[1], B[1]);
    and and4(w6, w2, Ci[0]);
    or  or2(w7, w1, w6);
    and and5(w8, w7, w5);
    or  or3(Ci[2], w8, w4);

    // Third bit calculations
    and and6(w9, A[2], B[2]);
    xor xor3(w10, A[2], B[2]);
    and and7(w11, w10, Ci[2]);
    or  or4(Ci[3], w9, w11);

    // Fourth bit calculations
    and and8(w12, A[3], B[3]);
    xor xor4(w13, A[3], B[3]);
    and and9(w14, w13, Ci[3]);
    or  or5(carry_out, w12, w14);

    // Sum calculations
    xor xor5(sum[0], A[0], B[0], Ci[0]);
    xor xor6(sum[1], A[1], B[1], Ci[1]);
    xor xor7(sum[2], A[2], B[2], Ci[2]);
    xor xor8(sum[3], A[3], B[3], Ci[3]);

endmodule



