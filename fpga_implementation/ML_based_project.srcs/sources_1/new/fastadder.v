`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.07.2026 02:18:15
// Design Name: 
// Module Name: fastadder
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


module fastadder  #(parameter N = 8) (
    output [N-1:0] sum,
    input  [N-1:0] input1, input2
);
    // Compute the nearest multiple of 4 greater than or equal to N
    localparam ADJ_N = (N % 4 == 0) ? N : ((N / 4) + 1) * 4;

    // Extend the input width to ADJ_N
    wire [ADJ_N-1:0] extended_input1, extended_input2, extended_sum;
    wire [ADJ_N/4:0] vectorcarry;
    
    supply0 gnd;
    assign vectorcarry[0] = gnd;

    // Assign input values to extended versions, padding MSB with 0s
    assign extended_input1 = {{(ADJ_N - N){1'b0}}, input1};
    assign extended_input2 = {{(ADJ_N - N){1'b0}}, input2};

    genvar i;
    generate
        for (i = 0; i < ADJ_N/4; i = i + 1) begin : gen_loop
            fblookahead fba (
                .carry_out(vectorcarry[i+1]),
                .sum(extended_sum[4*i+3:4*i]),
                .A(extended_input1[4*i+3:4*i]),
                .B(extended_input2[4*i+3:4*i]),
                .Cin(vectorcarry[i])
            );
        end
    endgenerate

    // Truncate the result to get the final N-bit sum
    assign sum = extended_sum[N-1:0];

endmodule
