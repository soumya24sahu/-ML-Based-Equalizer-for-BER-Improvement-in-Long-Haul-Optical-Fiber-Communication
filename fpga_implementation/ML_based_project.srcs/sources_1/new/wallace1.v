`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.07.2026 02:40:41
// Design Name: 
// Module Name: wallace1
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


module wallace1 #(parameter N=8, D=4)
(
    output reg [2*N-1:0] product1,
    output reg [2*N-1:0] product2,
    input  [N-1:0] input1,
    input  [N-1:0] input2
);

// --------------------------------------------------
// Internal Variables
// --------------------------------------------------

integer countprev[2*N:0];
integer countnext[2*N:0];

integer flag, stepcount;
integer i, j, k;

supply1 vdd;

// --------------------------------------------------
// Elementary Functions
// --------------------------------------------------

function hsum(input a, b);
begin
    hsum = a ^ b;
end
endfunction

function hcarry(input a, b);
begin
    hcarry = a & b;
end
endfunction

function fsum(input a, b, c);
begin
    fsum = a ^ b ^ c;
end
endfunction

function fcarry(input a, b, c);
begin
    fcarry = (a & b) | (b & c) | (c & a);
end
endfunction

// --------------------------------------------------
// Intermediate Sum Storage
// --------------------------------------------------

reg isum [D:0][N:0][2*N:0];

// --------------------------------------------------
// Main Wallace Tree Logic
// --------------------------------------------------

always @(*) begin

    // ----------------------------------------------
    // Initialize outputs
    // ----------------------------------------------

    for (i = 0; i < 2*N; i = i + 1) begin
        product1[i] = 0;
        product2[i] = 0;
    end

    // ----------------------------------------------
    // Initialize countprev
    // ----------------------------------------------

    for (i = 0; i < 2*N; i = i + 1) begin
        countprev[i] = i + 1 - 2*(i-N+1)*(i/N);
    end

    countprev[2*N] = 0;

    // ----------------------------------------------
    // Generate Partial Products
    // ----------------------------------------------

    for(i = 0; i < N; i = i + 1) begin

        for(j = 0; j < N; j = j + 1) begin

            if ((j == N-1) && (i == N-1))

                isum[0][j - ((i+j-N+1)*((i+j)/N))][i+j]
                    = input1[i] & input2[j];

            else if ((j == N-1) || (i == N-1))

                isum[0][j - ((i+j-N+1)*((i+j)/N))][i+j]
                    = ~(input1[i] & input2[j]);

            else

                isum[0][j - ((i+j-N+1)*((i+j)/N))][i+j]
                    = input1[i] & input2[j];
        end
    end

    // ----------------------------------------------
    // 2's Complement Correction
    // ----------------------------------------------

    isum[0][countprev[N]][N] = vdd;
    countprev[N] = countprev[N] + 1;

    isum[0][countprev[2*N-1]][2*N-1] = vdd;
    countprev[2*N-1] = countprev[2*N-1] + 1;

    // ----------------------------------------------
    // Compression Algorithm
    // ----------------------------------------------

    stepcount = -1;

    for(k = N; k > 2; k = 2*(k/3) + (k%3)) begin

        flag = 0;
        stepcount = stepcount + 1;

        // Reset countnext

        for (i = 0; i <= 2*N; i = i + 1)
            countnext[i] = 0;

        // ------------------------------------------
        // Compression per column
        // ------------------------------------------

        for (i = 0; i < 2*N; i = i + 1) begin

            // Pass-through case

            if (((countprev[i] == 2) && (flag == 0)) ||
                ((stepcount == 0) && (i == 2*N-3))) begin

                isum[stepcount+1][countnext[i]][i]
                    = isum[stepcount][countprev[i]-2][i];

                isum[stepcount+1][countnext[i]+1][i]
                    = isum[stepcount][countprev[i]-1][i];

                countnext[i] = countnext[i] + 2;
            end

            // Half adder special case

            else if ((countprev[i] == 3) && (flag == 0)) begin

                isum[stepcount+1][countnext[i+1]][i+1]
                    = hcarry(isum[stepcount][0][i],
                             isum[stepcount][1][i]);

                isum[stepcount+1][countnext[i]][i]
                    = hsum(isum[stepcount][0][i],
                           isum[stepcount][1][i]);

                countnext[i+1] = countnext[i+1] + 1;
                countnext[i]   = countnext[i] + 1;

                isum[stepcount+1][countnext[i]][i]
                    = isum[stepcount][2][i];

                countnext[i] = countnext[i] + 1;
            end

            // Modulo 0 case

            else if ((countprev[i] % 3 == 0) &&
                     (countprev[i] != 0)) begin

                for(j = 0; j < countprev[i]/3; j = j + 1) begin

                    isum[stepcount+1][countnext[i]][i]
                        = fsum(isum[stepcount][3*j][i],
                               isum[stepcount][3*j+1][i],
                               isum[stepcount][3*j+2][i]);

                    isum[stepcount+1][countnext[i+1]][i+1]
                        = fcarry(isum[stepcount][3*j][i],
                                 isum[stepcount][3*j+1][i],
                                 isum[stepcount][3*j+2][i]);

                    countnext[i+1] = countnext[i+1] + 1;
                    countnext[i]   = countnext[i] + 1;
                end
            end

            // Modulo 1 case

            else if (countprev[i] % 3 == 1) begin

                for(j = 0; j < countprev[i]/3; j = j + 1) begin

                    isum[stepcount+1][countnext[i]][i]
                        = fsum(isum[stepcount][3*j][i],
                               isum[stepcount][3*j+1][i],
                               isum[stepcount][3*j+2][i]);

                    isum[stepcount+1][countnext[i+1]][i+1]
                        = fcarry(isum[stepcount][3*j][i],
                                 isum[stepcount][3*j+1][i],
                                 isum[stepcount][3*j+2][i]);

                    countnext[i+1] = countnext[i+1] + 1;
                    countnext[i]   = countnext[i] + 1;
                end

                isum[stepcount+1][countnext[i]][i]
                    = isum[stepcount][countprev[i]-1][i];

                countnext[i] = countnext[i] + 1;
            end

            // Modulo 2 case

            else if (countprev[i] % 3 == 2) begin

                for(j = 0; j < countprev[i]/3; j = j + 1) begin

                    isum[stepcount+1][countnext[i]][i]
                        = fsum(isum[stepcount][3*j][i],
                               isum[stepcount][3*j+1][i],
                               isum[stepcount][3*j+2][i]);

                    isum[stepcount+1][countnext[i+1]][i+1]
                        = fcarry(isum[stepcount][3*j][i],
                                 isum[stepcount][3*j+1][i],
                                 isum[stepcount][3*j+2][i]);

                    countnext[i+1] = countnext[i+1] + 1;
                    countnext[i]   = countnext[i] + 1;
                end

                // Half adder

                isum[stepcount+1][countnext[i+1]][i+1]
                    = hcarry(isum[stepcount][countprev[i]-2][i],
                             isum[stepcount][countprev[i]-1][i]);

                isum[stepcount+1][countnext[i]][i]
                    = hsum(isum[stepcount][countprev[i]-2][i],
                           isum[stepcount][countprev[i]-1][i]);

                countnext[i+1] = countnext[i+1] + 1;
                countnext[i]   = countnext[i] + 1;
            end

            // Flag update

            if ((flag == 0) && (countprev[i] > 2))
                flag = 1;

        end

        // Update countprev

        for (i = 0; i <= 2*N; i = i + 1)
            countprev[i] = countnext[i];

    end

    // ----------------------------------------------
    // Final Adjustments
    // ----------------------------------------------

    isum[stepcount+1][1][0] = 0;

    if (countprev[2*N-1] == 0) begin

        isum[stepcount+1][0][2*N-1] = 0;
        isum[stepcount+1][1][2*N-1] = 0;

    end

    else if (countprev[2*N-1] == 1)

        isum[stepcount+1][1][2*N-1] = 0;

    // ----------------------------------------------
    // Final Outputs
    // ----------------------------------------------

    for (i = 0; i < 2*N; i = i + 1) begin

        product1[i] = isum[stepcount+1][0][i];
        product2[i] = isum[stepcount+1][1][i];

    end

end

endmodule
