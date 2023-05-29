`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/08 21:14:46
// Design Name: 
// Module Name: msdf_gradient
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

`include "define.vh"

module msdf_gradient#(
    parameter TARGET_PRECISION      =25,
    parameter LEARNING_RATE         =7
)
(
    input wire clk,
    input wire rst,
    input wire good_transfer,
    input wire [`NUM_GRADIENT*3-1:0]a_buffer,
    output reg [8:0]a_buffer_addrb,

    input wire [2:0] dataInArray_0,     //error
    input wire pValidArray_0,
    output wire readyArray_0,

    output wire [`NUM_GRADIENT*3-1:0] dataOutArray_0,
    output wire validArray_0,
    input wire nReadyArray_0
);

    /* 打一拍 */
    reg good_transfer_delay1;
    always @(posedge clk) begin
        good_transfer_delay1 <= good_transfer;
    end


    always @(posedge clk) begin
        if(rst)begin
            a_buffer_addrb <= 'd1;
        end
        else if(good_transfer) begin
            a_buffer_addrb <= a_buffer_addrb+1;
        end
    end
   

    /* 计算梯度! */
    genvar index_gen; 
    generate 
        for( index_gen = 0; index_gen < `NUM_CHUNKS*`NUM_BITS_PER_BANK; index_gen = index_gen + 1) begin: loop_of_INDEX
            
            wire [2:0]gradient_dataInArray_0;
            wire gradient_pValidArray_0;
            wire gradient_readyArray_0;
            wire [2:0]gradient_dataInArray_1;
            wire gradient_pValidArray_1;
            wire gradient_readyArray_1;
            wire [2:0]gradient_dataOutArray_0;
            wire gradient_validArray_0;
            wire gradient_nReadyArray_0;
            
        
            /* 连线线 */
            assign gradient_dataInArray_0 = dataInArray_0;
            assign gradient_pValidArray_0 = pValidArray_0;
            if(index_gen == 0)begin
                assign readyArray_0 = gradient_readyArray_0;
            end
            
            assign gradient_dataInArray_1 = a_buffer[index_gen*3+2:index_gen*3];
            assign gradient_pValidArray_1 = gradient_pValidArray_0;

            assign dataOutArray_0[index_gen*3+2:index_gen*3] = gradient_dataOutArray_0;
            if(index_gen ==0)begin
                assign validArray_0 = gradient_validArray_0;
            end
            assign gradient_nReadyArray_0 = nReadyArray_0;

            msdf_mult_op 
            #(
                .TARGET_PRECISION(TARGET_PRECISION)
            )
            msdf_mult_op_inst
            (
                .clk(clk),
                .rst(rst),

                .dataInArray_0(gradient_dataInArray_0),
                .dataInArray_1(gradient_dataInArray_1),
                .pValidArray_0(gradient_pValidArray_0),
                .pValidArray_1(gradient_pValidArray_1),
                .readyArray_0(gradient_readyArray_0),
                .readyArray_1(gradient_readyArray_1),


                .dataOutArray_0(gradient_dataOutArray_0),
                .validArray_0(gradient_validArray_0),
                .nReadyArray_0(gradient_nReadyArray_0)
            );
        end 
    endgenerate

endmodule
