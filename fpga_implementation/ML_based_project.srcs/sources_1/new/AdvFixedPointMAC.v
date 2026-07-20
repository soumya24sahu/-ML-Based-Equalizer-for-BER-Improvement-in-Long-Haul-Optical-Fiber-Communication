`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.07.2026 02:11:30
// Design Name: 
// Module Name: AdvFixedPointMAC
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



module AdvFixedPointMAC #(
    parameter SIGNAL_WIDTH = 10,
    parameter KERNEL_WIDTH = 6
)(
    input clk,
    input rst,

    input  signed [SIGNAL_WIDTH-1:0] input1,
    input  signed [KERNEL_WIDTH-1:0] input2,

    output reg signed [SIGNAL_WIDTH-1:0] acc
);

    ////////////////////////////////////////////////////////////
    // Derived widths
    ////////////////////////////////////////////////////////////

    localparam PROD_WIDTH = SIGNAL_WIDTH + KERNEL_WIDTH;

    ////////////////////////////////////////////////////////////
    // Internal signals
    ////////////////////////////////////////////////////////////

    wire signed [PROD_WIDTH-1:0] multiplier_output;
    reg  signed [PROD_WIDTH-1:0] product;
    reg  signed [PROD_WIDTH-1:0] flo_acc;

    wire signed [PROD_WIDTH-1:0] fastadder_output;
    wire signed [PROD_WIDTH-1:0] rounded_flo_acc;

    ////////////////////////////////////////////////////////////
    // Multiplier
    ////////////////////////////////////////////////////////////

    nbitmultiplier1 #(
        .N(SIGNAL_WIDTH),
        .D(KERNEL_WIDTH)
    ) multiplier_inst (
        .product(multiplier_output),
        .input1(input1),
        .input2(input2)
    );
//assign multiplier_output = input1 * input2;

    ////////////////////////////////////////////////////////////
    // Accumulator
    ////////////////////////////////////////////////////////////

    fastadder #(PROD_WIDTH) adder_inst (
        .sum(fastadder_output),
        .input1(flo_acc),
        .input2(product)
    );

    ////////////////////////////////////////////////////////////
    // Sequential MAC
    ////////////////////////////////////////////////////////////

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            product <= 0;
            flo_acc <= 0;
        end
        else begin
            product <= multiplier_output;
            //flo_acc <= fastadder_output;
if (^multiplier_output === 1'bX)
        flo_acc <= flo_acc;     // hold if unknown
    else
        flo_acc <= flo_acc + multiplier_output;
        end
    end
//flo_acc <= fastadder_output;
    ////////////////////////////////////////////////////////////
    // Rounding
    ////////////////////////////////////////////////////////////

    fastadder #(PROD_WIDTH) adder_round (
        .sum(rounded_flo_acc),
        .input1(flo_acc),
        .input2({{(PROD_WIDTH-5){1'b0}},5'b10000})   // +16
    );

    ////////////////////////////////////////////////////////////
    // Saturation
    ////////////////////////////////////////////////////////////

    wire signed [SIGNAL_WIDTH-1:0] MAX_POS;
    wire signed [SIGNAL_WIDTH-1:0] MIN_NEG;

    assign MAX_POS = {1'b0,{(SIGNAL_WIDTH-1){1'b1}}};
    assign MIN_NEG = {1'b1,{(SIGNAL_WIDTH-1){1'b0}}};

    ////////////////////////////////////////////////////////////
    // Output Quantization
    // Adjust slice if your Q format changes
    ////////////////////////////////////////////////////////////

//    always @(*) begin

    always @(*) begin

    if (^rounded_flo_acc === 1'bX) begin
        acc = 0;
    end

    else if ((rounded_flo_acc >>> 6) > 511) begin
        acc = 10'sd511;
    end

    else if ((rounded_flo_acc >>> 6) < -512) begin
        acc = -10'sd512;
    end

    else begin
        acc = rounded_flo_acc >>> 6;
    end

end
endmodule


  
