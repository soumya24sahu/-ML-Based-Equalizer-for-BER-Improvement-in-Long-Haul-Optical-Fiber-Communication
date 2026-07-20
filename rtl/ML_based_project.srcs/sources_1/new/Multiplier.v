`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.07.2026 02:32:40
// Design Name: 
// Module Name: Multiplier
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


module Multiplier  #(
    parameter DATA_WIDTH = 10,
    parameter D = 4
)(
    output signed [2*DATA_WIDTH-1:0] product,
    input signed [DATA_WIDTH-1:0] a,
    input signed [DATA_WIDTH-1:0] b
);
    
    // ========================================================================
    // Local Parameters & Internal Signals
    // ========================================================================
    supply0 gnd;
    localparam N = DATA_WIDTH - 2; // Must be 8
    localparam K = 4 * ((N / 2) + ((N % 2) ? 1 : 0));
    
    wire signed [N-1:0] input1_8bit, input2_8bit;
    wire [K-1:0] wires[1:0];
    wire [K-1:0] result;
    
    // ========================================================================
    // Input Mapping
    // ========================================================================
    assign input1_8bit = a[N-1:0];
    assign input2_8bit = b[N-1:0];
    
    // ========================================================================
    // Zero Padding for Alignment
    // ========================================================================
    generate 
        for (genvar i = 2*N; i < K; i = i + 1) begin
            assign wires[0][i] = gnd;
            assign wires[1][i] = gnd;
        end
    endgenerate
    
    // ========================================================================
    // Wallace Tree Multiplier Instantiation
    // ========================================================================
    nbitwallace1 #(N, D) wallace (
        .product1(wires[0][2*N-1:0]),
        .product2(wires[1][2*N-1:0]),
        .input1(input1_8bit),
        .input2(input2_8bit)
    );
    
    // ========================================================================
    // Fast Adder Instantiation
    // ========================================================================
    fastadder #(K) adder (
        .sum(result),
        .input1(wires[0]),
        .input2(wires[1])
    );
    
    // ========================================================================
    // Output Assignment with Sign Extension
    // ========================================================================
    assign product = {{4{result[2*N-1]}}, result[2*N-1:0]};
    
endmodule

