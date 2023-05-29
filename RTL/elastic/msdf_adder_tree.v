`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/19 10:41:16
// Design Name: 
// Module Name: msdf_adder_tree
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 加法树
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module msdf_adder_tree#(
    parameter TARGET_PRECISION    = 25,
    parameter TREE_DEPTH          = 3,
    parameter TREE_WIDTH          = 2**TREE_DEPTH 
)(
    input wire clk,
    input wire rst,

    input wire [3*TREE_WIDTH-1:0] dataInArray_0,
    input wire [TREE_WIDTH-1:0]pValidArray_0,
    output wire [TREE_WIDTH-1:0]readyArray_0,


    output wire [2:0] dataOutArray_0,
    output wire validArray_0,
    input wire nReadyArray_0
    );

    wire add_readyArray[TREE_DEPTH-1:0][TREE_WIDTH-1:0];
    wire [2:0]add_dataArray[TREE_DEPTH-1:0][TREE_WIDTH-1:0];
    wire add_validArray[TREE_DEPTH-1:0][TREE_WIDTH-1:0];

    assign dataOutArray_0 = add_dataArray[TREE_DEPTH-1][0]; 
    assign validArray_0 = add_validArray[TREE_DEPTH-1][0];
    assign add_readyArray[TREE_DEPTH-1][0] = nReadyArray_0;

    wire join_valid;
    wire join_ready;

    Join#(.SIZE(TREE_WIDTH)) 
	Join_int(
        .pValidArray(pValidArray_0),
        .valid(join_valid),
        .readyArray(readyArray_0),
        .nReady(join_ready)
    );

    genvar d, w; 
    generate 
        for( d = 0; d < TREE_DEPTH; d = d + 1) begin: inst_adder_tree_depth 
            for( w = 0; w < ( TREE_WIDTH/(2**(d+1)) ); w = w + 1) begin: inst_adder_tree_width
                
                if(d == 0) begin
                    wire [2:0]msdf_add_0_dataInArray_0 = dataInArray_0[3*((2*w)+1)-1:3*(2*w)];
                    wire [2:0]msdf_add_0_dataInArray_1 = dataInArray_0[3*((2*w+1)+1)-1:3*(2*w+1)];
                    wire msdf_add_0_pValidArray_0 = join_valid;
                    wire msdf_add_0_pValidArray_1 = join_valid;
                    wire msdf_add_0_readyArray_0;
                    wire msdf_add_0_readyArray_1;

                    wire [2:0]msdf_add_0_dataOutArray_0;
                    assign add_dataArray[d][w] = msdf_add_0_dataOutArray_0;
                    wire msdf_add_0_validArray_0;
                    assign add_validArray[d][w] = msdf_add_0_validArray_0;
                    wire msdf_add_0_nReadyArray_0 = add_readyArray[d][w];

                    if(w==0)begin
                    assign join_ready = msdf_add_0_readyArray_0;
                    end
                    msdf_add_op 
                    #(
                        .TARGET_PRECISION(TARGET_PRECISION)
                    )
                    msdf_add_0
                    (
                        .clk(clk),
                        .rst(rst),

                        .dataInArray_0(msdf_add_0_dataInArray_0),
                        .dataInArray_1(msdf_add_0_dataInArray_1),
                        .pValidArray_0(msdf_add_0_pValidArray_0),
                        .pValidArray_1(msdf_add_0_pValidArray_1),
                        .readyArray_0(msdf_add_0_readyArray_0),
                        .readyArray_1(msdf_add_0_readyArray_1),

                        .dataOutArray_0(msdf_add_0_dataOutArray_0),
                        .validArray_0(msdf_add_0_validArray_0),
                        .nReadyArray_0(msdf_add_0_nReadyArray_0)
                    );
                end 
                else begin
                    wire [2:0]msdf_add_0_dataInArray_0 = add_dataArray[d-1][2*w];
                    wire [2:0]msdf_add_0_dataInArray_1 = add_dataArray[d-1][2*w+1];
                    wire msdf_add_0_pValidArray_0 = add_validArray[d-1][2*w];
                    wire msdf_add_0_pValidArray_1 = add_validArray[d-1][2*w+1];

                    wire msdf_add_0_readyArray_0;
                    assign add_readyArray[d-1][2*w] = msdf_add_0_readyArray_0;
                    wire msdf_add_0_readyArray_1;
                    assign add_readyArray[d-1][2*w+1] = msdf_add_0_readyArray_1;

                    wire [2:0]msdf_add_0_dataOutArray_0;
                    assign add_dataArray[d][w] = msdf_add_0_dataOutArray_0;
                    wire msdf_add_0_validArray_0;
                    assign add_validArray[d][w] = msdf_add_0_validArray_0;
                    wire msdf_add_0_nReadyArray_0 = add_readyArray[d][w];
                    msdf_add_op 
                    #(
                        .TARGET_PRECISION(TARGET_PRECISION)
                    )
                    msdf_add_0
                    (
                        .clk(clk),
                        .rst(rst),

                        .dataInArray_0(msdf_add_0_dataInArray_0),
                        .dataInArray_1(msdf_add_0_dataInArray_1),
                        .pValidArray_0(msdf_add_0_pValidArray_0),
                        .pValidArray_1(msdf_add_0_pValidArray_1),
                        .readyArray_0(msdf_add_0_readyArray_0),
                        .readyArray_1(msdf_add_0_readyArray_1),

                        .dataOutArray_0(msdf_add_0_dataOutArray_0),
                        .validArray_0(msdf_add_0_validArray_0),
                        .nReadyArray_0(msdf_add_0_nReadyArray_0)
                    );
                end
            end
        end 
    endgenerate

endmodule
