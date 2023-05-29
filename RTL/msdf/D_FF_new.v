`timescale 1ns/1ps

////////////////////////////////////English///////////////////////////////////////
// Company:			Disp301 Experiment in SouthEast University
// Engineer:		Erie
// 
// Create Date: 	2022/03/20 12:31:37
// Design Name: 	D FlipFlop
// Module Name: 	D_FF
// Description: 	None
// 
// Dependencies: 	None
//
// Dependent modules:
// 	 Module Name				    Version
// 		None					 	 None
//
// Version:			V1.4
// Revision Date:	2022/09/05 15:06:40
// History:		
//    Time			   Version	   Revised by			Contents
// 2022/03/20			V1.0		 Erie		Create File and D_FF module.
// 2022/03/21			V1.1		 Erie		Increase the synchronous reset signal i_clr in the D flip-flop.
// 2022/03/31			V1.2		 Erie		Increase the data hold signal i_hold in the D flip-flop.
// 2022/06/15			V1.3		 Erie		Fix the VIVADO error when the shifter (S_FF) data parameter is 1.
// 2022/09/05			V1.4		 Erie		The shifter and D flip-flop are combined, and the D flip-flop is the main one. The shift depth can be adjusted by the parameter SHIFT_WIDTH, and the parameter check function is added.
///////////////////////////////////Chinese////////////////////////////////////////
// 版权归属:		东南大学显示中心301实验室
// 开发人员:		Erie
// 
// 创建日期: 		2022年03月20日
// 设计名称: 		D FlipFlop
// 模块名称: 		D_FF
// 相关名称: 		None
// 
// 依赖资料: 		None
//
// 依赖模块:
// 	  模块名称						 版本
// 		None					 	 None
//
// 当前版本:		V1.4
// 修订日期:		2022年09月05日
// 修订历史:
//		时间			版本		修订人				修订内容	
// 2022年03月20日		V1.0		 Erie		创建文件,编写D触发器模块(D_FF)
// 2022年03月21日		V1.1		 Erie		增加D触发器中的同步复位信号i_clr
// 2022年03月31日		V1.2		 Erie		增加D触发器中的数据保持信号i_hold
// 2022年06月15日		V1.3		 Erie		修复移位器(S_FF)数据参数为1时VIVADO报错问题
// 2022年09月05日		V1.4		 Erie		将移位器和D触发器合并,以D触发器为主,可通过参数SHIFT_WIDTH调整移位深度,增加参数检查功能

//D触发器模块
module D_FF_new
#(
	parameter DATA_WIDTH	= 8'd1,		//数据位宽,默认为1
	parameter SHIFT_WIDTH	= 8'd1,		//移位宽度,默认为1
	parameter DEFAULT_DATA	= 0			//默认/复位数据输出
)
(
	input i_clk,						//D触发器时钟
	input i_rstn,						//异步复位,低电平复位
	input i_clr,						//同步复位信号,高电平复位
	input i_enable,						//数据使能信号,高电平数据输出;否则保持锁存
	input [DATA_WIDTH - 1:0]i_inData,	//输入数据
	output [DATA_WIDTH - 1:0]o_outData	//输出数据
);
	//-----------------寄存器信号---------------//
	reg [DATA_WIDTH - 1:0]shift_ram[SHIFT_WIDTH - 1:0];
	
	//----------------输出信号连线--------------//
	//输出数据
	assign o_outData = shift_ram[SHIFT_WIDTH - 1];
	
	//D触发器
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)shift_ram[0] <= DEFAULT_DATA;
		else if(i_clr == 1'b1)shift_ram[0] <= DEFAULT_DATA;
		else if(i_enable == 1'b1)shift_ram[0] <= i_inData;
		else shift_ram[0] <= shift_ram[0];
	end
	
	//如果移位宽度大于1,则产生移位寄存器
	generate if(SHIFT_WIDTH > 8'd1)begin:gen_shift_flipflop
		genvar i;
		
		//遍历移位宽度,生成移位寄存器
		for(i = 1;i < SHIFT_WIDTH;i = i + 1)begin
			always@(posedge i_clk or negedge i_rstn)begin
				if(i_rstn == 1'b0)shift_ram[i] <= DEFAULT_DATA;
				else if(i_clr == 1'b1)shift_ram[i] <= DEFAULT_DATA;
				else if(i_enable == 1'b1)shift_ram[i] <= shift_ram[i - 1];
				else shift_ram[i] <= shift_ram[i];
			end
		end
		
	end endgenerate
	
	//参数检查
	initial begin
		if(SHIFT_WIDTH == 8'd0)begin
			$display("ParameterCheck:SHIFT_WIDTH was set to zero! Error!\n");
			$finish;
		end
		
		if(DATA_WIDTH == 8'd0)begin
			$display("ParameterCheck:DATA_WIDTH was set to zero! Error!\n");
			$finish;
		end
	end
	
endmodule