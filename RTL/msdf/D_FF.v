`timescale 1ns/1ps

////////////////////////////////////English///////////////////////////////////////
// Company:			Disp301 Experiment in SouthEast University
// Engineer:		Erie,sxw228
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
// Version:			V1.3
// Revision Date:	2022/06/15 19:27:56
// History:		
//    Time			   Version	   Revised by			Contents
// 2022/03/20			V1.0		 Erie		Create File and D_FF module.
// 2022/03/21			V1.1		 Erie		Increase the synchronous reset signal i_clr in the D flip-flop.
// 2022/03/31			V1.2		 Erie		Increase the data hold signal i_hold in the D flip-flop.
// 2022/06/15			V1.3		 Erie		Fix the VIVADO error when the shifter (S_FF) data parameter is 1.
///////////////////////////////////Chinese////////////////////////////////////////
// 版权归属:		东南大学显示中心301实验室
// 开发人员:		Erie,sxw228
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
// 当前版本:		V1.3
// 修订日期:		2022年06月15日
// 修订历史:
//		时间			版本		修订人				修订内容	
// 2022年03月20日		V1.0		 Erie		创建文件,编写D触发器模块(D_FF)
// 2022年03月21日		V1.1		 Erie		增加D触发器中的同步复位信号i_clr
// 2022年03月31日		V1.2		 Erie		增加D触发器中的数据保持信号i_hold
// 2022年06月15日		V1.3		 Erie		修复移位器(S_FF)数据参数为1时VIVADO报错问题

//D触发器模块
module D_FF
#(
	parameter DATA_WIDTH	= 8'd1,		//数据位宽
	parameter DEFAULT_DATA	= 0			//默认/复位数据输出
)
(
	input i_clk,						//D触发器时钟
	input i_rstn,						//异步复位,低电平复位
	input i_clr,						//同步复位信号,高电平复位
	input i_hold,						//数据保持信号,高电平保持输出
	input i_enable,						//数据使能信号,高电平数据输出;否则锁存
	input [DATA_WIDTH - 1:0]i_inData,	//输入数据
	output [DATA_WIDTH - 1:0]o_outData	//输出数据
);
	//------------------输出信号----------------//
	//输出数据
	reg [DATA_WIDTH - 1:0]outData_o = 0;
	
	//----------------输出信号连线--------------//
	//输出数据
	assign o_outData = outData_o;
	
	//----------------主要任务处理--------------//
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)outData_o <= DEFAULT_DATA;
		else if(i_clr == 1'b1)outData_o <= DEFAULT_DATA;
		else if(i_hold == 1'b1)outData_o <= outData_o;
		else if(i_enable == 1'b1)outData_o <= i_inData;
		else outData_o <= outData_o;
	end
	
endmodule

//移位器模块
module S_FF
#(
	parameter DATA_WIDTH	= 8'd1,		//数据位宽
	parameter DEFAULT_DATA	= 0			//默认/复位数据输出
)
(
	input i_clk,						//移位器时钟
	input i_rstn,						//异步复位,低电平复位
	input i_enable,						//数据使能信号,高电平数据输出;否则锁存
	input i_inData,						//输入数据
	output [DATA_WIDTH - 1:0]o_outData	//输出数据
);
	//------------------输出信号----------------//
	//输出数据
	reg [DATA_WIDTH - 1:0]outData_o = 0;
	
	//----------------输出信号连线--------------//
	//输出数据
	assign o_outData = outData_o;
	
	//----------------主要任务处理--------------//
	//数据宽度为1时,生成D触发器
	generate if(DATA_WIDTH == 8'd1)begin:gen_d_flipflop
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)outData_o <= DEFAULT_DATA;
			else if(i_enable == 1'b1)outData_o <= i_inData;
			else outData_o <= outData_o;
		end
	end
	//否则生成移位器
	else begin:gen_shift_flipflop
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)outData_o <= DEFAULT_DATA;
			else if(i_enable == 1'b1)outData_o <= {outData_o[DATA_WIDTH - 2:0],i_inData};
			else outData_o <= outData_o;
		end
	end endgenerate

endmodule

//移位器模块
module S_FF
#(
	parameter DATA_WIDTH	= 8'd1,		//数据位宽
	parameter DEFAULT_DATA	= 0			//默认/复位数据输出
)
(
	input i_clk,						//移位器时钟
	input i_rstn,						//异步复位,低电平复位
	input i_enable,						//数据使能信号,高电平数据输出;否则锁存
	input i_inData,						//输入数据
	output [DATA_WIDTH - 1:0]o_outData	//输出数据
);
	//------------------输出信号----------------//
	//输出数据
	reg [DATA_WIDTH - 1:0]outData_o = 0;
	
	//----------------输出信号连线--------------//
	//输出数据
	assign o_outData = outData_o;
	
	//----------------主要任务处理--------------//
	//数据宽度为1时,生成D触发器
	generate if(DATA_WIDTH == 8'd1)begin:gen_d_flipflop
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)outData_o <= DEFAULT_DATA;
			else if(i_enable == 1'b1)outData_o <= i_inData;
			else outData_o <= outData_o;
		end
	end
	//否则生成移位器
	else begin:gen_shift_flipflop
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)outData_o <= DEFAULT_DATA;
			else if(i_enable == 1'b1)outData_o <= {outData_o[DATA_WIDTH - 2:0],i_inData};
			else outData_o <= outData_o;
		end
	end endgenerate

endmodule


 module delayUnit #(
	parameter DELAY = 8,
	parameter SIZE = 8
 ) (
	input clk,
	input rstn,
	input [SIZE-1:0] din,
	input en,
	output [SIZE-1:0]dout,
	output reg [SIZE*DELAY-1:0]dout_reg
 );

	always@(posedge clk)begin
		if(rstn == 1'b0)
			dout_reg <='d0;
		else if(en)
			dout_reg <= {dout_reg[SIZE*(DELAY-1)-1:0],din};
		else 
			dout_reg <= dout_reg;
	end

	assign dout = dout_reg[SIZE*DELAY-1:SIZE*(DELAY-1)];
 endmodule
