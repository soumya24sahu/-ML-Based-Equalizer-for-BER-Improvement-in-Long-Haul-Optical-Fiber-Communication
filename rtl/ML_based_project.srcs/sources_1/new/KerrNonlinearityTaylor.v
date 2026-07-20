`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.07.2026 02:28:45
// Design Name: 
// Module Name: KerrNonlinearityTaylor
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


module KerrNonlinearityTaylor #(
    parameter DATA_WIDTH = 10,   // Bit-width of real and imaginary parts
    parameter L_EFF = 5,         // Effective nonlinear length
    parameter GAMMA = -13        // Gamma scaled by 10 (for fixed-point representation)
)(
    input  signed [DATA_WIDTH-1:0] real_in,   // Input real part
    input  signed [DATA_WIDTH-1:0] imag_in,   // Input imaginary part
    output signed [DATA_WIDTH-1:0] real_out,  // Output real part
    output signed [DATA_WIDTH-1:0] imag_out   // Output imaginary part
);

    // ---------------------------------------------------------------
    // Internal Signal Declarations
    // ---------------------------------------------------------------
    wire signed [2*DATA_WIDTH-1:0] real_sq, imag_sq, intensity;
    wire signed [2*DATA_WIDTH-1:0] _phase_imag;
    wire signed [DATA_WIDTH-1:0] phase_imag;
    wire signed [2*DATA_WIDTH-1:0] shift_4, shift_2, shift_half;
    wire signed [2*DATA_WIDTH-1:0] add1, add2;
    wire signed [2*DATA_WIDTH-1:0] _imag_mult, _real_mult;
    wire signed [DATA_WIDTH-1:0] imag_mult, real_mult;
    wire signed [2*DATA_WIDTH-1:0] temp_real, temp_imag;

    // ---------------------------------------------------------------
    // Compute |real|^2 and |imag|^2
    // ---------------------------------------------------------------
    Multiplier #(DATA_WIDTH) mul_real (
        .a(real_in),
        .b(real_in),
        .product(real_sq)
    );

    Multiplier #(DATA_WIDTH) mul_imag (
        .a(imag_in),
        .b(imag_in),
        .product(imag_sq)
    );

    // ---------------------------------------------------------------
    // Compute Intensity: |x|^2 = real^2 + imag^2
    // ---------------------------------------------------------------
    fastadder #(2*DATA_WIDTH) add_intensity (
        .sum(intensity),
        .input1(real_sq),
        .input2(imag_sq)
    );

    // ---------------------------------------------------------------
    // Compute Phase Imaginary Component: (4 + 2 + 0.5) * Intensity
    // ---------------------------------------------------------------
    assign shift_4   = intensity <<< 2;  // Multiply by 4
    assign shift_2   = intensity <<< 1;  // Multiply by 2
    assign shift_half = intensity >>> 1; // Multiply by 0.5

    fastadder #(2*DATA_WIDTH) add_shift1 (
        .sum(add1),
        .input1(shift_4),
        .input2(shift_2)
    );

    fastadder #(2*DATA_WIDTH) add_shift2 (
        .sum(_phase_imag),
        .input1(add1),
        .input2(shift_half)
    );

    // ---------------------------------------------------------------
    // Convert Q1.18 Format to Q0.9 for Multiplication
    // ---------------------------------------------------------------
    assign phase_imag = {
        _phase_imag[2*DATA_WIDTH-1], 
        _phase_imag[2*DATA_WIDTH-3:DATA_WIDTH-1]
    };

    // ---------------------------------------------------------------
    // Apply Phase Shift Multiplication with Minus Sign
    // ---------------------------------------------------------------
    Multiplier #(DATA_WIDTH) mul_imag_phase (
        .a(imag_in),
        .b(phase_imag),
        .product(_imag_mult)
    );

    Multiplier #(DATA_WIDTH) mul_real_phase (
        .a(real_in),
        .b(phase_imag),
        .product(_real_mult)
    );

    // ---------------------------------------------------------------
    // Convert Q1.18 Format to Q0.9
    // ---------------------------------------------------------------
    assign imag_mult = {
        _imag_mult[2*DATA_WIDTH-1], 
        _imag_mult[2*DATA_WIDTH-3:DATA_WIDTH-1]
    } + (_imag_mult[DATA_WIDTH-2] ? 1'b1 : 1'b0);

    assign real_mult = {
        _real_mult[2*DATA_WIDTH-1], 
        _real_mult[2*DATA_WIDTH-3:DATA_WIDTH-1]
    } + (_real_mult[DATA_WIDTH-2] ? 1'b1 : 1'b0);

    // ---------------------------------------------------------------
    // Compute Final Outputs with Additions/Subtractions
    // ---------------------------------------------------------------
    fastadder #(2*DATA_WIDTH) add_real (
        .sum(temp_real),
//        .input1(real_in),
//        .input2(imag_mult)
   .input1({{10{real_in[9]}},real_in}),
   .input2({{10{imag_mult[9]}},imag_mult})
    );


    fastadder #(2*DATA_WIDTH) sub_imag (
        .sum(temp_imag),
//        .input1(imag_in),
//        .input2(-real_mult)
   .input1({{10{real_in[9]}},real_in}),
.input2({{10{imag_mult[9]}},imag_mult})
    );

    // ---------------------------------------------------------------
    // Output Quantization (Clipping to DATA_WIDTH Range)
    // ---------------------------------------------------------------
    assign real_out = (temp_real > $signed({1'b0, {(DATA_WIDTH-1){1'b1}}})) ? 
                      $signed({1'b0, {(DATA_WIDTH-1){1'b1}}}) :
                      (temp_real < $signed({1'b1, {(DATA_WIDTH-1){1'b0}}})) ? 
                      $signed({1'b1, {(DATA_WIDTH-1){1'b0}}}) :
                      temp_real[DATA_WIDTH-1:0];

    assign imag_out = (temp_imag > $signed({1'b0, {(DATA_WIDTH-1){1'b1}}})) ? 
                      $signed({1'b0, {(DATA_WIDTH-1){1'b1}}}) :
                      (temp_imag < $signed({1'b1, {(DATA_WIDTH-1){1'b0}}})) ? 
                      $signed({1'b1, {(DATA_WIDTH-1){1'b0}}}) :
                      temp_imag[DATA_WIDTH-1:0];

endmodule

