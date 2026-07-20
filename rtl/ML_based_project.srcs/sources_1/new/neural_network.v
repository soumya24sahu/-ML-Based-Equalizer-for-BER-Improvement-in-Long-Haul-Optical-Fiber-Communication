`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.07.2026 02:34:19
// Design Name: 
// Module Name: neural_network
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


module neural_network #(
    parameter NUM_SAMPLES  = 1,
    parameter SIGNAL_WIDTH = 10,
    parameter KERNEL_WIDTH = 8,
    parameter DATA_WIDTH   = 10,
    parameter L_EFF        = 5,
    parameter GAMMA        = -13,
    parameter M            = 7,
    parameter KERNEL_SIZE  = 6
)(
    input clk,
    input reset,
    input enable,
    input  [2*SIGNAL_WIDTH*NUM_SAMPLES-1:0] in,
    output [2*SIGNAL_WIDTH*NUM_SAMPLES-1:0] out,
    output done
);

//=====================================================
// INTERNAL FIXED KERNEL STORAGE
//=====================================================

wire [KERNEL_SIZE*KERNEL_WIDTH*M-1:0] kernels;

assign kernels =
336'b000000000001111100000000000010010011111100011111000000000000101000000000000111110000000000001011000000000001111100000000000010110011111100011111000000000000110000000000000111110000000000001101000000000001111100111111000011010000000000011111000000000000111000000001000111110011111100001110000000000001111100111111000011100000000100011111;

//=====================================================
// INTERNAL SIGNALS
//=====================================================

wire [2*SIGNAL_WIDTH*NUM_SAMPLES-1:0] layer_input [0:M];
wire [2*SIGNAL_WIDTH*NUM_SAMPLES-1:0] layer_output [0:M];
wire layer_done [0:M];

assign layer_input[0] = in;

//=====================================================
// GENERATE NETWORK LAYERS
//=====================================================

genvar i;

generate
for(i=0; i<M; i=i+1)
begin : LAYER_GEN

wire [KERNEL_SIZE*KERNEL_WIDTH-1:0] layer_kernel;

assign layer_kernel =
kernels[KERNEL_SIZE*KERNEL_WIDTH*i +: KERNEL_SIZE*KERNEL_WIDTH];

if(i < M-1)
begin : SINGLE_LAYER_BLOCK

single_layer #(
.NUM_SAMPLES(NUM_SAMPLES),
.SIGNAL_WIDTH(SIGNAL_WIDTH),
.KERNEL_WIDTH(KERNEL_WIDTH),
.DATA_WIDTH(DATA_WIDTH),
.L_EFF(L_EFF),
.GAMMA(GAMMA),
.KERNEL_SIZE(KERNEL_SIZE)
)
layer_inst
(
.clk(clk),
.reset(reset),
.enable(enable),
.in(layer_input[i]),
.kernel(layer_kernel),
.prev_done(i==0 ? 1'b1 : layer_done[i-1]),
.out(layer_output[i]),
.done(layer_done[i])
);

end
else
begin : LAST_LAYER_BLOCK

AdvComplexConvLayer #(
.NUM_SAMPLES(NUM_SAMPLES),
.SIGNAL_WIDTH(SIGNAL_WIDTH),
.KERNEL_WIDTH(KERNEL_WIDTH),
.KERNEL_SIZE(KERNEL_SIZE)
)
conv_layer
(
.clk(clk),
.reset(reset),
.enable(enable),
.in(layer_input[i]),
.kernel(layer_kernel),
.out(layer_output[i]),
.done(layer_done[i])
);

end

assign layer_input[i+1] = layer_output[i];

end
endgenerate

//=====================================================
 //OUTPUTS
//=====================================================

assign out  = layer_output[M-1];
assign done = layer_done[M-1];
endmodule

