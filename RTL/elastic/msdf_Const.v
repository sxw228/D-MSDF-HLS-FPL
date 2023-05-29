`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/07 11:10:32
// Design Name: 
// Module Name: msdf_Const
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


module msdf_Const
    #(
        parameter CONST_DATA_PLUS	= 64'd0,		//常数值正部分
        parameter CONST_DATA_MINUS	= 64'd0		//常数值负部分
    )
    (
    input wire clk,
    input wire rst,

    input wire [2:0] dataInArray_0,
    input wire pValidArray_0,
    output wire readyArray_0,

    output wire [2:0] dataOutArray_0,
    output wire validArray_0,
    input wire nReadyArray_0
    );

    wire rstn = ~rst;
    assign readyArray_0 = 1'b1;

    //预存的常数
    reg [63:0] digit_vector_plus;
    reg [63:0] digit_vector_minus;

    //用一个读指针记录状态
    reg[7:0] rd_ptr;    
    //读指针就一直在digit_vector的比特63处，每发生一次传输，就循环左移
    always @(posedge clk ) begin
        if(~rstn)begin
            rd_ptr <= 'd63;
        end
        else if (nReadyArray_0 & pValidArray_0 & dataInArray_0[2])begin
            rd_ptr <= 'd63;
        end       
        else if(nReadyArray_0 & pValidArray_0)begin
            if(rd_ptr ==0)begin
                rd_ptr <= rd_ptr;
            end else begin
                rd_ptr <= rd_ptr-1;
            end
        end
    end
    always @(posedge clk ) begin
        if(~rstn)begin
            digit_vector_plus <= CONST_DATA_PLUS;
            digit_vector_minus <= CONST_DATA_MINUS;
        end
        else if (nReadyArray_0 & pValidArray_0 & dataInArray_0[2])begin
            digit_vector_plus <= CONST_DATA_PLUS;
            digit_vector_minus <= CONST_DATA_MINUS;
        end
        else if((nReadyArray_0 & pValidArray_0)&&(rd_ptr[7:0]!=8'd0))begin
            digit_vector_plus[63:0] <= {digit_vector_plus[62:0],digit_vector_plus[63]};
            digit_vector_minus[63:0] <= {digit_vector_minus[62:0],digit_vector_minus[63]};
        end
    end
    
    assign dataOutArray_0[1:0] = {digit_vector_plus[63],digit_vector_minus[63]};
    assign dataOutArray_0[2] = dataInArray_0[2];
    assign validArray_0 = pValidArray_0;

  
endmodule