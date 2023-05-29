`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/01 19:40:22
// Design Name: 
// Module Name: wrappers
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
module EagerFork_RegisterBlock(
    input wire clk,
    input wire rstn,
    input wire p_valid,
    input wire n_stop,
    input wire p_valid_and_fork_stop,
    output wire valid,
    output wire block_stop
);
    reg reg_value;
    wire reg_in,block_stop_internal;

    assign block_stop_internal = n_stop & reg_value;
    assign block_stop = block_stop_internal;
    assign reg_in = block_stop_internal | (~ p_valid_and_fork_stop);
    assign valid = reg_value & p_valid;

    always @(posedge clk) begin
        if(~rstn)
            reg_value <= 1'b1;
        else
            reg_value <= reg_in;        
    end
endmodule
//(1,4,1,1)
module Fork_top#(
    parameter INPUTS	= 8'd1,		//Êý¾ÝÎ»¿í
    parameter SIZE = 8'd1,
    parameter DATA_SIZE_IN = 32'd8,
    parameter DATA_SIZE_OUT = 32'd8
)(
    input wire  clk,
    input wire rstn,
    input wire[DATA_SIZE_IN-1:0] dataInArray,
    input wire pValidArray,
    output wire readyArray,

    output wire [SIZE*DATA_SIZE_OUT-1:0]dataOutArray,
    output wire [SIZE-1:0]validArray,
    input wire [SIZE-1:0]nReadyArray
    );


    wire forkStop;
    wire [SIZE-1:0]nStopArray;
    wire [SIZE-1:0]blockStopArray;
    wire anyBlockStop;
    wire pValidAndForkStop;

    assign readyArray = ~forkStop;
    assign nStopArray[SIZE-1:0] = ~nReadyArray[SIZE-1:0];

    orN#(.N(SIZE)) orN_inst(
        .x(blockStopArray),
        .res(anyBlockStop)
    );       
    //internal combinatorial signals
    assign forkStop = anyBlockStop;
    assign pValidAndForkStop = pValidArray & forkStop;
    //generate blocks
    genvar i;
    generate
    for (i = 0; i < SIZE ; i = i + 1) begin
        EagerFork_RegisterBlock eagerFork_RegisterBlock_inst(
            .clk(clk),
            .rstn(rstn),
            .p_valid(pValidArray),
            .n_stop(nStopArray[i]),
            .p_valid_and_fork_stop(pValidAndForkStop),
            .valid(validArray[i]),
            .block_stop(blockStopArray[i])
        );
        assign dataOutArray[(i+1)*DATA_SIZE_OUT-1:i*DATA_SIZE_OUT] = dataInArray[DATA_SIZE_IN-1:0];
    end
    endgenerate

endmodule

