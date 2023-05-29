`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/10 11:56:01
// Design Name: 
// Module Name: msdf_update_local_x
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

module msdf_update_local_x#(
    parameter TARGET_PRECISION    = 25
)
(
    input clk,
    input rst,

    input wire [`NUM_GRADIENT*3-1:0]dataInArray_0,
    input wire pValidArray_0,
    output wire readyArray_0,

    /* ram接口 */
    output wire local_x_wea,            //写使能,否则默认是读
    output wire [8:0]local_x_addra,          //a口读写地址
    output wire [`NUM_GRADIENT*3-1:0]local_x_dina,           //要写到mem的数据

    output reg [8:0]local_x_addrb,          //b口读地址
    input wire [`NUM_GRADIENT*3-1:0]local_x_doutb            //b口读出的数据
    );

    /* 控制写使能,写地址,读地址 */
    wire good_input_transfer;
    assign good_input_transfer = pValidArray_0 & readyArray_0;

    reg [`NUM_GRADIENT*3-1:0]dataInArray_0_delay1;
    always @(posedge clk) begin
        dataInArray_0_delay1 <= dataInArray_0;
    end

    /* 读地址 */
    always @(posedge clk) begin
        if(rst)begin
            local_x_addrb <= 'd0;
        end
        else if(good_input_transfer)begin
            if(dataInArray_0[2])begin
                local_x_addrb <= 'd0;
            end
            else begin
                local_x_addrb <= local_x_addrb+1;
            end
        end
    end

    /* 写地址 */
    reg [9*3-1:0]local_x_addrb_delays;
    always @(posedge clk) begin
        if(rst)begin
            local_x_addrb_delays <= 'd0;
        end
        else begin
            local_x_addrb_delays <= {local_x_addrb_delays[9*2-1:0],local_x_addrb};
        end
    end
    assign local_x_addra = local_x_addrb_delays[9*3-1:9*2];

    reg [1*3-1:0]good_input_transfer_delays;
    always @(posedge clk) begin
        if(rst)begin
            good_input_transfer_delays <= 'd0;
        end
        else begin
            good_input_transfer_delays <= {good_input_transfer_delays[1*2-1:0],good_input_transfer};
        end
    end
    assign local_x_wea = good_input_transfer_delays[2];

    
    genvar index_gen; 
    generate 
        for( index_gen = 0; index_gen < `NUM_GRADIENT; index_gen = index_gen + 1) begin: loop_of_INDEX
            
             /* 声明变量 */
            wire [2:0]msdf_add_0_dataInArray_0;
            wire [2:0]msdf_add_0_dataInArray_1;
            wire msdf_add_0_pValidArray_0;
            wire msdf_add_0_pValidArray_1;
            wire msdf_add_0_readyArray_0;
            wire msdf_add_0_readyArray_1;
            wire [2:0]msdf_add_0_dataOutArray_0;
            wire msdf_add_0_validArray_0;
            wire msdf_add_0_nReadyArray_0;

             /* 模块输入->减法器的输入0 */
            assign msdf_add_0_dataInArray_0 = {dataInArray_0[index_gen*3+2],dataInArray_0[index_gen*3+0],dataInArray_0[index_gen*3+1]};
            assign msdf_add_0_pValidArray_0 = pValidArray_0;
            if(index_gen==0)begin
                assign readyArray_0 = msdf_add_0_readyArray_0;
            end

            /* local_x的读数据->减法器的输入1 */
            assign msdf_add_0_dataInArray_1 = {local_x_doutb[index_gen*3+2],local_x_doutb[index_gen*3+1],local_x_doutb[index_gen*3+0]};
            assign msdf_add_0_pValidArray_1 = pValidArray_0;

            /* 减法器的输出 */
            assign local_x_dina[index_gen*3+2:index_gen*3] = msdf_add_0_dataOutArray_0;
            assign msdf_add_0_nReadyArray_0 = 1'b1;

            /* msdf加法组件 */
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
    endgenerate
   
endmodule
