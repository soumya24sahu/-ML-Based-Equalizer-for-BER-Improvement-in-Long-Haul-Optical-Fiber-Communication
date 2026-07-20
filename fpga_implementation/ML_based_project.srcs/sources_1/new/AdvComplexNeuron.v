`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.07.2026 02:01:07
// Design Name: 
// Module Name: AdvComplexNeuron
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


module AdvComplexNeuron #(
    parameter SIGNAL_WIDTH = 10,
    parameter KERNEL_WIDTH = 8,
    parameter KERNEL_SIZE = 6
)(
    input clk,
    input reset,
    input enable,
     
    input [(KERNEL_SIZE)*SIGNAL_WIDTH-1:0] real_padded,
    input [(KERNEL_SIZE)*SIGNAL_WIDTH-1:0] imag_padded,
    input  [KERNEL_SIZE*KERNEL_WIDTH-1:0] kernel,
    
    // Real and Imaginary outputs
    output reg [SIGNAL_WIDTH-1:0] real_out, 
    output reg [SIGNAL_WIDTH-1:0] imag_out, 
    output reg done
);

   
   wire signed [SIGNAL_WIDTH-1:0] real_padded_array [0:KERNEL_SIZE-1];
   wire signed [SIGNAL_WIDTH-1:0] imag_padded_array [0:KERNEL_SIZE-1];
    
    genvar i;
    generate
        for (i = 0; i < KERNEL_SIZE; i = i + 1) begin : unpack_inputs
            assign real_padded_array[i] = real_padded[i*SIGNAL_WIDTH +: SIGNAL_WIDTH];
            assign imag_padded_array[i] = imag_padded[i*SIGNAL_WIDTH +: SIGNAL_WIDTH];
        end
    endgenerate

    
    // MAC and Adder instances
    reg signed [SIGNAL_WIDTH-1:0] mac_real_input1, mac_imag_input1;
    reg signed [KERNEL_WIDTH-1:0] mac_real_input2, mac_imag_input2;
    wire signed [SIGNAL_WIDTH-1:0] mac_real_product, mac_imag_product;
    reg mac_reset;

    wire [KERNEL_WIDTH-1:0] k [KERNEL_SIZE-1:0]; // Unpacked array
    
    generate
        for (i = 0; i < KERNEL_SIZE; i = i + 1) begin : unpack_kernel
            assign k[i] = kernel[i*KERNEL_WIDTH +: KERNEL_WIDTH]; 
        end
    endgenerate
    


    // Instantiating Real MAC Unit
    AdvFixedPointMAC #(
        .SIGNAL_WIDTH(SIGNAL_WIDTH),
        .KERNEL_WIDTH(KERNEL_WIDTH)
    ) mac_real (
        .clk(clk),
        .rst(mac_reset | reset),
        .input1(mac_real_input1),
        .input2(mac_real_input2),
        .acc(mac_real_product) // Convert this port into 8-bit
    );

    // Instantiating Imaginary MAC Unit
    AdvFixedPointMAC #(
        .SIGNAL_WIDTH(SIGNAL_WIDTH),
        .KERNEL_WIDTH(KERNEL_WIDTH)
    ) mac_imag (
        .clk(clk),
        .rst(mac_reset | reset),
        .input1(mac_imag_input1),
        .input2(mac_imag_input2),
        .acc(mac_imag_product) // Convert this port into 8-bit
    );
    
    
    wire signed [SIGNAL_WIDTH-1:0] real_padded_sum [0:1];
wire signed [SIGNAL_WIDTH-1:0] imag_padded_sum [0:1];
    generate
        for (i = 0; i < (KERNEL_SIZE-1)/2; i = i + 1) begin : generate_adders
            fastadder #(
                .N(SIGNAL_WIDTH)
            ) real_adder (
                .sum(real_padded_sum[i]),
                .input1(real_padded_array[i]),
                .input2(real_padded_array[KERNEL_SIZE-2-i])
            );
    
            fastadder #(
                .N(SIGNAL_WIDTH)
            ) imag_adder (
                .sum(imag_padded_sum[i]),
                .input1(imag_padded_array[i]),
                .input2(imag_padded_array[KERNEL_SIZE-2-i])
            );
        end
    endgenerate
    
    

    // Parameters
    localparam CYCLE_COUNT_MAX = KERNEL_SIZE + 2 + 1 + 2; // Total FSM clock cycles
    localparam CYCLE_COUNT_WIDTH = $clog2(CYCLE_COUNT_MAX);

    // Accumulators
    reg signed [SIGNAL_WIDTH-1:0] real_accum, imag_accum;

    // Cycle counter
    reg [CYCLE_COUNT_WIDTH-1:0] cycle_count;
    integer index;

// =====================================================
// Clean FSM for AdvComplexNeuron
// Supports KERNEL_SIZE = 6
// Bug-free / Vivado friendly
// =====================================================

always @(posedge clk or posedge reset) begin
    if (reset) begin
        cycle_count <= 0;
        done <= 0;
        mac_reset <= 1;

        mac_real_input1 <= 0;
        mac_real_input2 <= 0;
        mac_imag_input1 <= 0;
        mac_imag_input2 <= 0;

        real_out <= 0;
        imag_out <= 0;
    end

    else if (enable) begin
        done <= 0;
        mac_reset <= 0;

        index = cycle_count >> 1;

        if (cycle_count == 0) begin
            mac_real_input1 <= real_padded_array[2];
            mac_imag_input1 <= real_padded_array[2];
            mac_real_input2 <= k[0];
            mac_imag_input2 <= k[3];
            cycle_count <= 1;
        end

        else if (cycle_count == 1) begin
            mac_real_input1 <= imag_padded_array[2];
            mac_imag_input1 <= imag_padded_array[2];
            mac_real_input2 <= -k[3];
            mac_imag_input2 <= k[0];
            cycle_count <= 2;
        end

        else if (cycle_count == 2) begin
            mac_real_input1 <= real_padded_sum[0];
            mac_imag_input1 <= real_padded_sum[0];
            mac_real_input2 <= k[2];
            mac_imag_input2 <= k[4];
            cycle_count <= 3;
        end

        else if (cycle_count == 3) begin
            mac_real_input1 <= imag_padded_sum[0];
            mac_imag_input1 <= imag_padded_sum[0];
            mac_real_input2 <= -k[4];
            mac_imag_input2 <= k[2];
            cycle_count <= 4;
        end

        else if (cycle_count == 4) begin
            mac_real_input1 <= real_padded_sum[1];
            mac_imag_input1 <= real_padded_sum[1];
            mac_real_input2 <= k[1];
            mac_imag_input2 <= k[5];
            cycle_count <= 5;
        end

        else if (cycle_count == 5) begin
            mac_real_input1 <= imag_padded_sum[1];
            mac_imag_input1 <= imag_padded_sum[1];
            mac_real_input2 <= -k[5];
            mac_imag_input2 <= k[1];
            cycle_count <= 6;
        end

        else if (
    cycle_count == 6 ||
    cycle_count == 7 ||
    cycle_count == 8
) begin
            mac_real_input1 <= 0;
            mac_real_input2 <= 0;
            mac_imag_input1 <= 0;
            mac_imag_input2 <= 0;
            cycle_count <= cycle_count + 1;
        end

        else begin
            real_out <= mac_real_product;
            imag_out <= mac_imag_product;
            done <= 1;
            mac_reset <= 1;
            cycle_count <= 0;
        end
    end
end
endmodule


