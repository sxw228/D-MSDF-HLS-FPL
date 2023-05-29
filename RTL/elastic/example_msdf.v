`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/07 17:31:03
// Design Name: 
// Module Name: example_msdf
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


module example_msdf(
    input clk,
    input rstn,
    input [1:0]start_in,
    input start_lastIn,
    input start_valid,
    output start_ready,
    output [1:0]end_out,
    output end_lastOut,
    output end_valid,
    input end_ready
    );
    wire rst = ~rstn;



    wire [2:0]buffl_1_dataInArray;
    wire buffl_1_pValidArray;
    wire buffl_1_readyArray;
    wire [2:0]buffl_1_dataOutArray;
    wire buffl_1_validArray;
    wire buffl_1_nReadyArray;

    wire [2:0]fork_0_dataInArray;
    wire fork_0_pValidArray;
    wire fork_0_readyArray;
    wire [2:0]fork_0_dataOutArray_0;
    wire fork_0_validArray_0;
    wire fork_0_nReadyArray_0;
    wire [2:0]fork_0_dataOutArray_1;
    wire fork_0_validArray_1;
    wire fork_0_nReadyArray_1;
    wire [2:0]fork_0_dataOutArray_2;
    wire fork_0_validArray_2;
    wire fork_0_nReadyArray_2;


    wire msdf_cst_2_lastIn;
    wire msdf_cst_2_pValidArray;
    wire [1:0]msdf_cst_2_dataOutArray;
    wire msdf_cst_2_lastOut;
    wire msdf_cst_2_validArray;
    wire msdf_cst_2_nReadyArray;

    wire [1:0]msdf_add_3_dataInArray_0;
    wire msdf_add_3_lastIn_0;
    wire [1:0]msdf_add_3_dataInArray_1;
    wire msdf_add_3_lastIn_1;
    wire [1:0]msdf_add_3_pValidArray;
    wire [1:0]msdf_add_3_readyArray;
    wire [1:0]msdf_add_3_dataOutArray;
    wire msdf_add_3_lastOut;
    wire msdf_add_3_validArray;
    wire msdf_add_3_nReadyArray;

    wire [1:0]msdf_mul_4_dataInArray_0;
    wire msdf_mul_4_lastIn_0;
    wire [1:0]msdf_mul_4_dataInArray_1;
    wire msdf_mul_4_lastIn_1;
    wire [1:0]msdf_mul_4_pValidArray;
    wire [1:0]msdf_mul_4_readyArray;
    wire [1:0]msdf_mul_4_dataOutArray;
    wire msdf_mul_4_lastOut;
    wire msdf_mul_4_validArray;
    wire msdf_mul_4_nReadyArray;

    wire [2:0]transpFifo_mul_4_dataInArray;
    wire transpFifo_mul_4_pValidArray;
    wire transpFifo_mul_4_readyArray;
    wire [2:0]transpFifo_mul_4_dataOutArray;
    wire transpFifo_mul_4_validArray;
    wire transpFifo_mul_4_nReadyArray;

    wire [1:0]msdf_mul_5_dataInArray_0;
    wire msdf_mul_5_lastIn_0;
    wire [1:0]msdf_mul_5_dataInArray_1;
    wire msdf_mul_5_lastIn_1;
    wire [1:0]msdf_mul_5_pValidArray;
    wire [1:0]msdf_mul_5_readyArray;
    wire [1:0]msdf_mul_5_dataOutArray;
    wire msdf_mul_5_lastOut;
    wire msdf_mul_5_validArray;
    wire msdf_mul_5_nReadyArray;

    wire [2:0]transpFifo_mul_5_dataInArray;
    wire transpFifo_mul_5_pValidArray;
    wire transpFifo_mul_5_readyArray;
    wire [2:0]transpFifo_mul_5_dataOutArray;
    wire transpFifo_mul_5_validArray;
    wire transpFifo_mul_5_nReadyArray;

    wire [1:0]msdf_mul_6_dataInArray_0;
    wire msdf_mul_6_lastIn_0;
    wire [1:0]msdf_mul_6_dataInArray_1;
    wire msdf_mul_6_lastIn_1;
    wire [1:0]msdf_mul_6_pValidArray;
    wire [1:0]msdf_mul_6_readyArray;
    wire [1:0]msdf_mul_6_dataOutArray;
    wire msdf_mul_6_lastOut;
    wire msdf_mul_6_validArray;
    wire msdf_mul_6_nReadyArray;

    wire [2:0]transpFifo_mul_6_dataInArray;
    wire transpFifo_mul_6_pValidArray;
    wire transpFifo_mul_6_readyArray;
    wire [2:0]transpFifo_mul_6_dataOutArray;
    wire transpFifo_mul_6_validArray;
    wire transpFifo_mul_6_nReadyArray;

    wire [1:0]msdf_mul_7_dataInArray_0;
    wire msdf_mul_7_lastIn_0;
    wire [1:0]msdf_mul_7_dataInArray_1;
    wire msdf_mul_7_lastIn_1;
    wire [1:0]msdf_mul_7_pValidArray;
    wire [1:0]msdf_mul_7_readyArray;
    wire [1:0]msdf_mul_7_dataOutArray;
    wire msdf_mul_7_lastOut;
    wire msdf_mul_7_validArray;
    wire msdf_mul_7_nReadyArray;

    wire [2:0]transpFifo_mul_7_dataInArray;
    wire transpFifo_mul_7_pValidArray;
    wire transpFifo_mul_7_readyArray;
    wire [2:0]transpFifo_mul_7_dataOutArray;
    wire transpFifo_mul_7_validArray;
    wire transpFifo_mul_7_nReadyArray;

    
    elasticBuffer#(.INPUTS(1),.OUTPUTS(1),.DATA_SIZE_IN(3),.DATA_SIZE_OUT(3))
    buffl_1(
        .clk(clk),
        .rst(rst),

        .dataInArray(buffl_1_dataInArray),
        .pValidArray(buffl_1_pValidArray),
        .readyArray(buffl_1_readyArray),

        .dataOutArray(buffl_1_dataOutArray),
        .validArray(buffl_1_validArray),
        .nReadyArray(buffl_1_nReadyArray)
    );
    Fork
    #(
        .INPUTS(1),
        .SIZE(5),
        .DATA_SIZE_IN(3),
        .DATA_SIZE_OUT(3)
    )fork_0
    (
        .clk(clk),
        .rst(rst),

        .dataInArray(fork_0_dataInArray),
        .pValidArray(fork_0_pValidArray),
        .readyArray(fork_0_readyArray),

        .dataOutArray({fork_0_dataOutArray_4,fork_0_dataOutArray_3,fork_0_dataOutArray_2,fork_0_dataOutArray_1,fork_0_dataOutArray_0}),
        .validArray({fork_0_validArray_4,fork_0_validArray_3,fork_0_validArray_2,fork_0_validArray_1,fork_0_validArray_0}),
        .nReadyArray({fork_0_nReadyArray_4,fork_0_nReadyArray_3,fork_0_nReadyArray_2,fork_0_nReadyArray_1,fork_0_nReadyArray_0})
    );

    msdf_Const
    #(
        .CONST_DATA_PLUS(64'h0000_0000_0000_0000),		//常数值正部分
        .CONST_DATA_MINUS(64'h8000_0000_0000_0000)		//常数值负部分
	)msdf_cst_2
    (
        .clk(clk),
        .rstn(rstn),

        .lastIn(msdf_cst_2_lastIn),
        .pValidArray(msdf_cst_2_pValidArray),

        .dataOutArray(msdf_cst_2_dataOutArray),
        .lastOut(msdf_cst_2_lastOut),
        .validArray(msdf_cst_2_validArray),
        .nReadyArray(msdf_cst_2_nReadyArray)
    );

    msdf_add_op msdf_add_3
    (
        .clk(clk),
        .rstn(rstn),

        .dataInArray_0(msdf_add_3_dataInArray_0),
        .lastIn_0(msdf_add_3_lastIn_0),
        .dataInArray_1(msdf_add_3_dataInArray_1),
        .lastIn_1(msdf_add_3_lastIn_1),
        .pValidArray(msdf_add_3_pValidArray),
        .readyArray(msdf_add_3_readyArray),

        .dataOutArray(msdf_add_3_dataOutArray),
        .lastOut(msdf_add_3_lastOut),
        .validArray(msdf_add_3_validArray),
        .nReadyArray(msdf_add_3_nReadyArray)
    );
    msdf_mult_op msdf_mul_4
    (
        .clk(clk),
        .rstn(rstn),

        .dataInArray_0(msdf_mul_4_dataInArray_0),
        .lastIn_0(msdf_mul_4_lastIn_0),
        .dataInArray_1(msdf_mul_4_dataInArray_1),
        .lastIn_1(msdf_mul_4_lastIn_1),
        .pValidArray(msdf_mul_4_pValidArray),
        .readyArray(msdf_mul_4_readyArray),

        .dataOutArray(msdf_mul_4_dataOutArray),
        .lastOut(msdf_mul_4_lastOut),
        .validArray(msdf_mul_4_validArray),
        .nReadyArray(msdf_mul_4_nReadyArray)
    );

    msdf_mult_op msdf_mul_5
    (
        .clk(clk),
        .rstn(rstn),

        .dataInArray_0(msdf_mul_5_dataInArray_0),
        .lastIn_0(msdf_mul_5_lastIn_0),
        .dataInArray_1(msdf_mul_5_dataInArray_1),
        .lastIn_1(msdf_mul_5_lastIn_1),
        .pValidArray(msdf_mul_5_pValidArray),
        .readyArray(msdf_mul_5_readyArray),

        .dataOutArray(msdf_mul_5_dataOutArray),
        .lastOut(msdf_mul_5_lastOut),
        .validArray(msdf_mul_5_validArray),
        .nReadyArray(msdf_mul_5_nReadyArray)
    );

    msdf_mult_op msdf_mul_6
    (
        .clk(clk),
        .rstn(rstn),

        .dataInArray_0(msdf_mul_6_dataInArray_0),
        .lastIn_0(msdf_mul_6_lastIn_0),
        .dataInArray_1(msdf_mul_6_dataInArray_1),
        .lastIn_1(msdf_mul_6_lastIn_1),
        .pValidArray(msdf_mul_6_pValidArray),
        .readyArray(msdf_mul_6_readyArray),

        .dataOutArray(msdf_mul_6_dataOutArray),
        .lastOut(msdf_mul_6_lastOut),
        .validArray(msdf_mul_6_validArray),
        .nReadyArray(msdf_mul_6_nReadyArray)
    );

    msdf_mult_op msdf_mul_7
    (
        .clk(clk),
        .rstn(rstn),

        .dataInArray_0(msdf_mul_7_dataInArray_0),
        .lastIn_0(msdf_mul_7_lastIn_0),
        .dataInArray_1(msdf_mul_7_dataInArray_1),
        .lastIn_1(msdf_mul_7_lastIn_1),
        .pValidArray(msdf_mul_7_pValidArray),
        .readyArray(msdf_mul_7_readyArray),

        .dataOutArray(msdf_mul_7_dataOutArray),
        .lastOut(msdf_mul_7_lastOut),
        .validArray(msdf_mul_7_validArray),
        .nReadyArray(msdf_mul_7_nReadyArray)
    );

    transpFifo#(.INPUTS(1),.OUTPUTS(1),.DATA_SIZE_IN(3),.DATA_SIZE_OUT(3),.FIFO_DEPTH(10))
    transpFifo_mul_4(
        .clk(clk),
        .rst(rst),

        .dataInArray(transpFifo_mul_4_dataInArray),
        .pValidArray(transpFifo_mul_4_pValidArray),
        .readyArray(transpFifo_mul_4_readyArray),

        .dataOutArray(transpFifo_mul_4_dataOutArray),
        .validArray(transpFifo_mul_4_validArray),
        .nReadyArray(transpFifo_mul_4_nReadyArray)
    );

    transpFifo#(.INPUTS(1),.OUTPUTS(1),.DATA_SIZE_IN(3),.DATA_SIZE_OUT(3),.FIFO_DEPTH(20))
    transpFifo_mul_5(
        .clk(clk),
        .rst(rst),

        .dataInArray(transpFifo_mul_5_dataInArray),
        .pValidArray(transpFifo_mul_5_pValidArray),
        .readyArray(transpFifo_mul_5_readyArray),

        .dataOutArray(transpFifo_mul_5_dataOutArray),
        .validArray(transpFifo_mul_5_validArray),
        .nReadyArray(transpFifo_mul_5_nReadyArray)
    );

    transpFifo#(.INPUTS(1),.OUTPUTS(1),.DATA_SIZE_IN(3),.DATA_SIZE_OUT(3),.FIFO_DEPTH(30))
    transpFifo_mul_6(
        .clk(clk),
        .rst(rst),

        .dataInArray(transpFifo_mul_6_dataInArray),
        .pValidArray(transpFifo_mul_6_pValidArray),
        .readyArray(transpFifo_mul_6_readyArray),

        .dataOutArray(transpFifo_mul_6_dataOutArray),
        .validArray(transpFifo_mul_6_validArray),
        .nReadyArray(transpFifo_mul_6_nReadyArray)
    );
    
    transpFifo#(.INPUTS(1),.OUTPUTS(1),.DATA_SIZE_IN(3),.DATA_SIZE_OUT(3),.FIFO_DEPTH(40))
    transpFifo_mul_7(
        .clk(clk),
        .rst(rst),

        .dataInArray(transpFifo_mul_7_dataInArray),
        .pValidArray(transpFifo_mul_7_pValidArray),
        .readyArray(transpFifo_mul_7_readyArray),

        .dataOutArray(transpFifo_mul_7_dataOutArray),
        .validArray(transpFifo_mul_7_validArray),
        .nReadyArray(transpFifo_mul_7_nReadyArray)
    );

    


    assign buffl_1_dataInArray = {start_lastIn,start_in};
    assign buffl_1_pValidArray = start_valid;
    assign buffl_1_nReadyArray = fork_0_readyArray;

    assign fork_0_dataInArray = buffl_1_dataOutArray;
    assign fork_0_pValidArray = buffl_1_validArray;
    assign fork_0_nReadyArray_0 = msdf_add_3_readyArray[1];
    assign fork_0_nReadyArray_1 = transpFifo_mul_4_readyArray;
    assign fork_0_nReadyArray_2 = transpFifo_mul_5_readyArray;
    assign fork_0_nReadyArray_3 = transpFifo_mul_6_readyArray;
    assign fork_0_nReadyArray_4 = transpFifo_mul_7_readyArray;

    assign msdf_cst_2_lastIn = fork_0_dataOutArray_0[2];
    assign msdf_cst_2_pValidArray = fork_0_validArray_0;
    assign msdf_cst_2_nReadyArray = msdf_add_3_readyArray[0];

    assign msdf_add_3_dataInArray_0 = msdf_cst_2_dataOutArray;
    assign msdf_add_3_lastIn_0 = msdf_cst_2_lastOut;
    assign msdf_add_3_dataInArray_1 = fork_0_dataOutArray_0[1:0];
    assign msdf_add_3_lastIn_1 = fork_0_dataOutArray_0[2];
    assign msdf_add_3_pValidArray = {fork_0_validArray_0,msdf_cst_2_validArray};
    assign msdf_add_3_nReadyArray = msdf_mul_4_readyArray[0];

    assign transpFifo_mul_4_dataInArray[2:0] = fork_0_dataOutArray_1[2:0];
    assign transpFifo_mul_4_pValidArray = fork_0_validArray_1;
    assign transpFifo_mul_4_nReadyArray = msdf_mul_4_readyArray[1];

    assign msdf_mul_4_dataInArray_0 = msdf_add_3_dataOutArray;
    assign msdf_mul_4_lastIn_0 = msdf_add_3_lastOut;
    assign msdf_mul_4_dataInArray_1 = transpFifo_mul_4_dataOutArray[1:0];
    assign msdf_mul_4_lastIn_1 = transpFifo_mul_4_dataOutArray[2];
    assign msdf_mul_4_pValidArray = {transpFifo_mul_4_validArray,msdf_add_3_validArray};
    assign msdf_mul_4_nReadyArray = end_ready;
    assign msdf_mul_4_nReadyArray = msdf_mul_5_readyArray[0];

    assign transpFifo_mul_5_dataInArray[2:0] = fork_0_dataOutArray_2[2:0];
    assign transpFifo_mul_5_pValidArray = fork_0_validArray_2;
    assign transpFifo_mul_5_nReadyArray = msdf_mul_5_readyArray[1];

    assign msdf_mul_5_dataInArray_0 = msdf_mul_4_dataOutArray;
    assign msdf_mul_5_lastIn_0 = msdf_mul_4_lastOut;
    assign msdf_mul_5_dataInArray_1 = transpFifo_mul_5_dataOutArray[1:0];
    assign msdf_mul_5_lastIn_1 = transpFifo_mul_5_dataOutArray[2];
    assign msdf_mul_5_pValidArray = {transpFifo_mul_5_validArray,msdf_mul_4_validArray};
    assign msdf_mul_5_nReadyArray = msdf_mul_6_readyArray[0];

    assign transpFifo_mul_6_dataInArray[2:0] = fork_0_dataOutArray_3[2:0];
    assign transpFifo_mul_6_pValidArray = fork_0_validArray_3;
    assign transpFifo_mul_6_nReadyArray = msdf_mul_6_readyArray[1];

    assign msdf_mul_6_dataInArray_0 = msdf_mul_5_dataOutArray;
    assign msdf_mul_6_lastIn_0 = msdf_mul_5_lastOut;
    assign msdf_mul_6_dataInArray_1 = transpFifo_mul_6_dataOutArray[1:0];
    assign msdf_mul_6_lastIn_1 = transpFifo_mul_6_dataOutArray[2];
    assign msdf_mul_6_pValidArray = {transpFifo_mul_6_validArray,msdf_mul_5_validArray};
    assign msdf_mul_6_nReadyArray = msdf_mul_7_readyArray[0];

    assign transpFifo_mul_7_dataInArray[2:0] = fork_0_dataOutArray_4[2:0];
    assign transpFifo_mul_7_pValidArray = fork_0_validArray_4;
    assign transpFifo_mul_7_nReadyArray = msdf_mul_7_readyArray[1];

    assign msdf_mul_7_dataInArray_0 = msdf_mul_6_dataOutArray;
    assign msdf_mul_7_lastIn_0 = msdf_mul_6_lastOut;
    assign msdf_mul_7_dataInArray_1 = transpFifo_mul_7_dataOutArray[1:0];
    assign msdf_mul_7_lastIn_1 = transpFifo_mul_7_dataOutArray[2];
    assign msdf_mul_7_pValidArray = {transpFifo_mul_7_validArray,msdf_mul_6_validArray};
    assign msdf_mul_7_nReadyArray = end_ready;






    assign end_out = msdf_mul_7_dataOutArray;
    assign end_lastOut = msdf_mul_7_lastOut;
    assign end_valid = msdf_mul_7_validArray;
    assign start_ready = buffl_1_readyArray;


endmodule
