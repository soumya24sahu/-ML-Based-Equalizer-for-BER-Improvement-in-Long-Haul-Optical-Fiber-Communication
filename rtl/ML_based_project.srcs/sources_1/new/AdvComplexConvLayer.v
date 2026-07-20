`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.07.2026 22:43:30
// Design Name: 
// Module Name: AdvComplexConvLayer
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
//////////////////////////////////////////////////////////////////////////////////
// ==============================================
//  Advanced Complex Convolution Layer Module
// ==============================================
//  Description : Implements a convolution layer 
//                for complex-valued inputs using
//                fixed-point arithmetic.

//  Parameters  :
//  NUM_SAMPLES  - Number of complex input samples
//  SIGNAL_WIDTH - Width of fixed-point signal (1.9 format)
//  KERNEL_WIDTH - Width of kernel coefficients
// ==============================================

module AdvComplexConvLayer #(
    parameter NUM_SAMPLES  = 10,  // Number of complex input samples
    parameter SIGNAL_WIDTH = 10,  // 10-bit fixed-point (1.9 format)
    parameter KERNEL_WIDTH = 8,
    parameter KERNEL_SIZE = 6
)( 
    input clk,    // Clock signal
    input reset,  // Reset signal
    input enable, // Enable processing

    input  [2*SIGNAL_WIDTH*NUM_SAMPLES-1:0] in,  // Flattened inputs: [real0, imag0, ..., real9, imag9]
    input  [KERNEL_SIZE*KERNEL_WIDTH-1:0] kernel,         // Symmetric kernel: [k0_real, k1_real, k0_imag, k1_imag]
    
    output [2*SIGNAL_WIDTH*NUM_SAMPLES-1:0] out, // Flattened outputs
    output done  // Output valid signal
);

// ==============================================
// ? Internal Signal Definitions
// ==============================================
//localparam pad = (KERNEL_SIZE/2)-1;
localparam pad = KERNEL_SIZE/2;
// Zero-padded inputs (NUM_SAMPLES ? NUM_SAMPLES + 2)
reg signed [SIGNAL_WIDTH-1:0] real_padded [0:(NUM_SAMPLES-1)+(pad*2)];
reg signed [SIGNAL_WIDTH-1:0] imag_padded [0:(NUM_SAMPLES-1)+(pad*2)];



// Generate done signals for each neuron
wire [NUM_SAMPLES-1:0] done_signals;

// ==============================================
//  Padding Logic (Zero-Padding for Boundaries)
// ==============================================
integer j;
integer l;
always @(*) begin
    for (j = 0; j < NUM_SAMPLES; j = j + 1) begin
        real_padded[j+pad] = in[2*SIGNAL_WIDTH*j +: SIGNAL_WIDTH];
        imag_padded[j+pad] = in[2*SIGNAL_WIDTH*j + SIGNAL_WIDTH +: SIGNAL_WIDTH];
    end
    // Edge padding to maintain consistency
    for (l=0;l<pad;l=l+1) begin

        real_padded[l]              = real_padded[NUM_SAMPLES+l];
        real_padded[NUM_SAMPLES+pad+l]  = real_padded[pad+l];
        imag_padded[l]              = imag_padded[NUM_SAMPLES+l];
        imag_padded[NUM_SAMPLES+pad+l]  = imag_padded[pad+l];
    end 
end

// ==============================================
//  Neuron Array Generation
// ==============================================

// Define number of inputs each neuron should receive
//localparam NUM_KERNEL_INPUTS = KERNEL_SIZE - 1;
localparam NUM_KERNEL_INPUTS = KERNEL_SIZE;
localparam FLATTENED_WIDTH = NUM_KERNEL_INPUTS * SIGNAL_WIDTH;

genvar i, k;
generate
    for (i = 0; i < NUM_SAMPLES; i = i + 1) begin : NEURON_GEN
        // Flattened 1D vector for real and imaginary padded inputs
        wire [FLATTENED_WIDTH-1:0] real_padded_window;
        wire [FLATTENED_WIDTH-1:0] imag_padded_window;

        // Assign dynamically based on KERNEL_SIZE
        for (k = 0; k < NUM_KERNEL_INPUTS; k = k + 1) begin
            assign real_padded_window[k*SIGNAL_WIDTH +: SIGNAL_WIDTH] = real_padded[i + k];
            assign imag_padded_window[k*SIGNAL_WIDTH +: SIGNAL_WIDTH] = imag_padded[i + k];
        end

        // Instantiating a Complex Neuron 
        AdvComplexNeuron #(
            .SIGNAL_WIDTH(SIGNAL_WIDTH),
            .KERNEL_WIDTH(KERNEL_WIDTH),
            .KERNEL_SIZE(KERNEL_SIZE)
        ) neuron_inst (
            .clk(clk),
            .reset(reset),
            .enable(enable),
            
            .real_padded(real_padded_window),
            .imag_padded(imag_padded_window),

            .kernel(kernel),
            
            .real_out(out[2*SIGNAL_WIDTH*i +: SIGNAL_WIDTH]),
            .imag_out(out[2*SIGNAL_WIDTH*i + SIGNAL_WIDTH +: SIGNAL_WIDTH]),

            .done(done_signals[i])
        );
    end
endgenerate




// ==============================================
//  Global Done Signal
// ==============================================
assign done = &done_signals;

endmodule




