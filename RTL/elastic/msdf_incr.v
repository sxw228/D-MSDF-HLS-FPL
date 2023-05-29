`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/20 08:04:27
// Design Name: 
// Module Name: msdf_incr
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
module msdf_incr#(
    parameter TARGET_PRECISION    = 25,
    parameter NUM_CHUNKS    = 2
)
(
    input wire clk,
    input wire rst,

    //input wire [7:0]total_num,

    input wire [2:0] dataInArray_0,
    input wire pValidArray_0,
    output wire readyArray_0,

    output wire [2:0] dataOutArray_0,
    output wire validArray_0,
    input wire nReadyArray_0
);

    wire [2:0]msdf_add_0_dataInArray_0;
    wire [2:0]msdf_add_0_dataInArray_1;
    wire msdf_add_0_pValidArray_0;
    wire msdf_add_0_pValidArray_1;
    wire msdf_add_0_readyArray_0;
    wire msdf_add_0_readyArray_1;

    wire [2:0]msdf_add_0_dataOutArray_0;
    wire msdf_add_0_validArray_0;
    wire msdf_add_0_nReadyArray_0;

    wire [2:0]oehb_dataInArray;
    wire oehb_pValidArray;
    wire oehb_readyArray;

    wire [2:0]oehb_dataOutArray;
    wire oehb_validArray;
    wire oehb_nReadyArray;
    
    
    reg [32*3-1:0]intermediate_vector_0;
    reg [7:0]last_cnt;
    
    /*中间值用一个移位寄存器存储，32bit
    一开始复位成32'd0
    在msdf_add_0_validArray_0与oehb_dataInArray为1时，移位一次
    */

    always @(posedge clk)begin
        if(rst)begin
            intermediate_vector_0 <= 'd0;
        end
        else if(msdf_add_0_validArray_0)begin
            intermediate_vector_0 <= {intermediate_vector_0[31*3-1:0],msdf_add_0_dataOutArray_0};
        end
    end   
    
    assign msdf_add_0_dataInArray_1 = intermediate_vector_0[29*3-1:28*3];
    
    always @(posedge clk) begin
        if(rst)begin
            last_cnt <= 'd0;
        end
        else if(msdf_add_0_validArray_0 & msdf_add_0_dataOutArray_0[2])begin  //加法器输出一个last
            if(last_cnt == `NUM_CHUNKS-1)begin
                last_cnt <= 'd0;
            end
            else begin
                last_cnt <= last_cnt+1;
            end
        end
    end

    /* 连线线 */
    assign msdf_add_0_dataInArray_0 = dataInArray_0;
    assign msdf_add_0_dataInArray_1 = intermediate_vector_0[29*3-1:28*3];
    assign msdf_add_0_pValidArray_0 = pValidArray_0;
    assign msdf_add_0_pValidArray_1 = pValidArray_0;
    assign readyArray_0 = msdf_add_0_readyArray_0;

    /* 我去掉了输出控制,累加器现在是一直输出 */
    // assign oehb_dataInArray = msdf_add_0_dataOutArray_0;
    // assign oehb_pValidArray = (last_cnt == `NUM_CHUNKS-1) ? msdf_add_0_validArray_0 : 1'b0;
    // assign msdf_add_0_nReadyArray_0 = oehb_readyArray;
    assign oehb_dataInArray = msdf_add_0_dataOutArray_0;
    assign oehb_pValidArray = msdf_add_0_validArray_0;
    assign msdf_add_0_nReadyArray_0 = oehb_readyArray;

    assign dataOutArray_0 = oehb_dataOutArray;
    assign validArray_0 = oehb_validArray;
    assign oehb_nReadyArray = nReadyArray_0;
    
    OEHB#(.DATA_WIDTH(3))
	OEHB_inst(
        .clk(clk),
        .rstn(~rst),
        .dataInArray(oehb_dataInArray),
        .pValidArray(oehb_pValidArray),
        .readyArray(oehb_readyArray),
        .dataOutArray(oehb_dataOutArray),
        .validArray(oehb_validArray),
        .nReadyArray(oehb_nReadyArray)
    );

    msdf_add_op#(.TARGET_PRECISION(TARGET_PRECISION)) msdf_add_0
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

    
endmodule
