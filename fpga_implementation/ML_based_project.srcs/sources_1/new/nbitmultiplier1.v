`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.07.2026 02:23:24
// Design Name: 
// Module Name: nbitmultiplier1
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


module nbitmultiplier1 #(parameter N = 8, D = 4)(
    output signed [N+D-1:0] product,
    input signed [N-1:0] input1,
    input signed [D-1:0] input2
);
    supply0 gnd;
    wire [N-1:0] input_1,input_2;
    localparam K= 4*((N/2) + ((N%2)?1:0));
    wire [K-1:0] wires[1:0];
    wire [K-1:0] result;
    generate for (genvar i=2*N;i<K;i=i+1)begin
        assign wires[0][i] = gnd;
        assign wires[1][i] = gnd;
    end
    endgenerate

    assign input_1 = input1;
     assign input_2 = input2;

    // Instantiate Wallace Tree and fast adder (purely combinational)
    nbitwallace1 #(N, D) wallace(wires[0][2*N-1:0],wires[1][2*N-1:0], input_1, input_2);

    fastadder #(K) adder (
        .sum(result),
        .input1(wires[0]),
        .input2(wires[1])
    );
    


    assign product = result[N+D-1:0];
endmodule


