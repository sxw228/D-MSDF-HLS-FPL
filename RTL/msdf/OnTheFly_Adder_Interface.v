`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/21 15:24:19
// Design Name: 
// Module Name: OnTheFly_Adder_Interface
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

//Online计算加法接口
module OnTheFly_Adder_Interface
#(
	parameter RADIX_MODE		= 8'd1,				//进制模式,默认2**RADIX_MODE进制
	parameter PARALLEL_ENABLE	= 1'd0,				//并行使能
	parameter ENCODING_MODE		= "signed-digit",	//编码模式,signed-digit/borrow-save
	parameter DATA_WIDTH		= 8'd2				//数据位宽
)
(
	input i_clk,
	input i_rstn,
	
	//----------------外部控制信号--------------//
	//写通道
	input i_mbus_wen,							//写使能信号,高电平有效
	input [DATA_WIDTH - 1:0]i_mbus_wdata_x,		//写数据,加数X
	input [DATA_WIDTH - 1:0]i_mbus_wdata_y,		//写数据,加数Y
	input i_mbus_wvalid,						//写数据有效信号
	input i_mbus_wlast,							//写数据结束信号
	
	//读通道
	output [DATA_WIDTH - 1:0]o_mbus_rdata,		//读数据
	output o_mbus_rvalid,						//读数据有效信号
	output o_mbus_rlast							//读数据结束信号
);
	
	//如果编码模式是signed-digit
	generate if(ENCODING_MODE == "signed-digit")begin:gen_signed_digit_adder
		
		//根据进制模式判断
		//如果是2进制
		if(RADIX_MODE == 8'd1)begin:gen_radix2_adder
			//2进制Online计算加法接口实例化
			OnTheFly_Adder_Radix2_Interface #(
				.PARALLEL_ENABLE(PARALLEL_ENABLE)			//并行使能
			)OnTheFly_Adder_Radix2_Interface_Inst(
				.i_clk(i_clk),
				.i_rstn(i_rstn),
				
				//----------------外部控制信号--------------//
				//写通道
				.i_mbus_wen(i_mbus_wen),					//写使能信号,高电平有效
				.i_mbus_wdata_x(i_mbus_wdata_x),			//写数据,加数X
				.i_mbus_wdata_y(i_mbus_wdata_y),			//写数据,加数Y
				.i_mbus_wvalid(i_mbus_wvalid),				//写数据有效信号
				.i_mbus_wlast(i_mbus_wlast),				//写数据结束信号
				
				//读通道
				.o_mbus_rdata(o_mbus_rdata),				//读数据
				.o_mbus_rvalid(o_mbus_rvalid),				//读数据有效信号
				.o_mbus_rlast(o_mbus_rlast)					//读数据结束信号
			);
		end
		
		//未完待续...
		else begin
			//----------------输出信号连线--------------//
			//读通道
			assign o_mbus_rdata = 0;
			assign o_mbus_rvalid = 0;
			assign o_mbus_rlast = 0;
		end
	end
	
	//如果编码模式是borrow-save
	else if(ENCODING_MODE == "borrow-save")begin:gen_borrow_save_adder
		//----------------输出信号连线--------------//
		//读通道
		assign o_mbus_rdata = 0;
		assign o_mbus_rvalid = 0;
		assign o_mbus_rlast = 0;
	end
	
	//其他自定义编码
	else begin:gen_self_define
		//----------------输出信号连线--------------//
		//读通道
		assign o_mbus_rdata = 0;
		assign o_mbus_rvalid = 0;
		assign o_mbus_rlast = 0;
	end endgenerate
	
endmodule


//2进制Online计算加法接口:输入数据范围(-1,1)
module OnTheFly_Adder_Radix2_Interface
#(
	parameter PARALLEL_ENABLE	= 1'd0			//并行使能
)
(
	input i_clk,
	input i_rstn,
	
	//----------------外部控制信号--------------//
	//写通道
	input i_mbus_wen,							//写使能信号,高电平有效
	input [1:0]i_mbus_wdata_x,					//写数据,加数X
	input [1:0]i_mbus_wdata_y,					//写数据,加数Y
	input i_mbus_wvalid,						//写数据有效信号
	input i_mbus_wlast,							//写数据结束信号
	
	//读通道
	output [1:0]o_mbus_rdata,					//读数据
	output o_mbus_rvalid,						//读数据有效信号
	output o_mbus_rlast							//读数据结束信号
);
	//------------------参数数据----------------//
	localparam INITIAL_DELAY = 4'd3;
	
	//------------------计算数据----------------//
	//第一级输入
	wire [1:0]input_xj3;
	wire [1:0]input_yj3;
	wire [1:0]input_serialx[2:0];
	wire [1:0]input_serialy[2:0];
	
	//第一级输出
	wire cal_hj2;
	wire [1:0]cal_gj3;
	reg [1:0]cal_gj2 = 0;
	wire [1:0]cal_serialg[2:0];
	wire [3:0]cal_serialh;
	
	//第二级输出
	wire cal_tj1;
	wire cal_wj2;
	wire cal_wj1;
	wire [2:0]cal_serialt;
	wire [2:0]cal_serialw;
	
	//第三级输出
	wire [1:0]cal_zj1;
	
	//----------------输入缓存信号--------------//
	//写通道
	wire mbus_wen_i;
	wire [1:0]mbus_wdata_x_i;
	wire [1:0]mbus_wdata_y_i;
	wire [INITIAL_DELAY:0]mbus_wvalid_i;
	wire [INITIAL_DELAY:0]mbus_wlast_i;
	
	//读通道
	reg [1:0]mbus_rdata_o = 0;
	reg mbus_rvalid_o = 0;
	reg mbus_rlast_o = 0;
	
	//----------------输出信号连线--------------//
	//读通道
	assign o_mbus_rdata = mbus_rdata_o;
	assign o_mbus_rvalid = mbus_rvalid_o;
	assign o_mbus_rlast = mbus_rlast_o;
	
	//输入信号对齐
	D_FF #(1,0)D_FF1_Inst6(i_clk,i_rstn,1'b0,1'b0,1'b1,~mbus_wdata_x_i[0],input_xj3[0]);
	D_FF #(1,0)D_FF1_Inst7(i_clk,i_rstn,1'b0,1'b0,1'b1,mbus_wdata_x_i[1],input_xj3[1]);
	D_FF #(1,0)D_FF1_Inst8(i_clk,i_rstn,1'b0,1'b0,1'b1,~mbus_wdata_y_i[0],input_yj3[0]);
	D_FF #(1,0)D_FF1_Inst9(i_clk,i_rstn,1'b0,1'b0,1'b1,mbus_wdata_y_i[1],input_yj3[1]);
	
	//----------------输出信号处理-------------//
	//读通道-数据有效信号
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)mbus_rvalid_o <= 1'b0;
		else mbus_rvalid_o <= mbus_wvalid_i[INITIAL_DELAY - 1] | mbus_wvalid_i[INITIAL_DELAY];
	end
	
	//读通道-数据结束信号
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)mbus_rlast_o <= 2'b00;
		else mbus_rlast_o <= mbus_wlast_i[INITIAL_DELAY];
	end
		
	//如果是串行
	generate if(PARALLEL_ENABLE == 1'd0)begin:gen_serial_radix2_adder

		//第一级
		//计算数据连线
		assign cal_gj3[0] = input_yj3[0];
		
		//全加器
		Adder_Interface #(
			.DATA_WIDTH_4Bit(8'd1),				//4Bit位宽指数
			.ADDER_MODE("FA"),					//加法器模式,DEFAULT/HA/FA/CRA/CLA/CSA/CCA/KST/BKT
			.DATA_WIDTH(8'd1)					//加法计算位宽
		)Adder_Interface_Inst0(
			.i_A(input_xj3[1]),					//加数A
			.i_B(input_xj3[0]),					//加数B
			.i_Ci(input_yj3[1]),				//上一级进位Cin,无进位则给0
			.o_Sum(cal_gj3[1]),					//和数Sum
			.o_Co(cal_hj2)						//进位Cout
		);
		
		//缓冲打拍对齐,gj+3->gj+2
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)
				cal_gj2 <= 2'b11;
			else if(mbus_wvalid_i == 2'b00)
				cal_gj2 <= 2'b11;
			//else if(mbus_wlast_i[INITIAL_DELAY - 1])cal_gj2 <= 2'b11;
			else 
				cal_gj2 <= cal_gj3;
		end
		
		//第二级
		//全加器
		Adder_Interface #(
			.DATA_WIDTH_4Bit(8'd1),				//4Bit位宽指数
			.ADDER_MODE("FA"),					//加法器模式,DEFAULT/HA/FA/CRA/CLA/CSA/CCA/KST/BKT
			.DATA_WIDTH(8'd1)					//加法计算位宽
		)Adder_Interface_Inst1(
			.i_A(cal_gj2[1]),					//加数A
			.i_B(cal_gj2[0]),					//加数B
			.i_Ci(cal_hj2),						//上一级进位Cin,无进位则给0
			.o_Sum(cal_wj2),					//和数Sum
			.o_Co(cal_tj1)						//进位Cout
		);
		
		//第三级
		//缓冲打拍对齐,wj+2->wj+1
		D_FF #(1,0)D_FF1_Inst12(i_clk,i_rstn,1'b0,1'b0,1'b1,cal_wj2,cal_wj1);
		
		//得到z数据
		assign cal_zj1[0] = ~cal_tj1;
		assign cal_zj1[1] = cal_wj1;
		
		//----------------输出信号处理-------------//
		//读通道-数据信号
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)
				mbus_rdata_o <= 2'b00;
			else 
				mbus_rdata_o <= cal_zj1;
		end
	end
	
	//并行计算
	else begin:gen_parallel_radix2_adder
		genvar i;

		//第一级
		//输入数据
		assign input_serialx[2] = input_xj3;
		assign input_serialy[2] = input_yj3;
		
		//缓冲打拍,总共3个
		for(i = 2;i > 0;i = i - 1)begin
			D_FF #(2,0)D_FF2_Instx(i_clk,i_rstn,1'b0,1'b0,1'b1,input_serialx[i],input_serialx[i - 1]);
			D_FF #(2,0)D_FF2_Insty(i_clk,i_rstn,1'b0,1'b0,1'b1,input_serialy[i],input_serialy[i - 1]);
		end

		//全加器和进位数据
		for(i = 0;i < 3;i = i + 1)begin
			//数据连线
			assign cal_serialg[i][0] = input_serialy[i][0];
			
			//全加器接口实例化
			Adder_Interface #(
				.DATA_WIDTH_4Bit(8'd1),				//4Bit位宽指数
				.ADDER_MODE("FA"),					//加法器模式,DEFAULT/HA/FA/CRA/CLA/CSA/CCA/KST/BKT
				.DATA_WIDTH(8'd1)					//加法计算位宽
			)Adder_Interface_Inst0(
				.i_A(input_serialx[i][1]),			//加数A
				.i_B(input_serialx[i][0]),			//加数B
				.i_Ci(input_serialy[i][1]),			//上一级进位Cin,无进位则给0
				.o_Sum(cal_serialg[i][1]),			//和数Sum
				.o_Co(cal_serialh[i])				//进位Cout
			);
		end
		
		//第二级
		//对齐进位
		assign cal_serialh[3] = 0;
		
		//全加器
		for(i = 0;i < 3;i = i + 1)begin
			//全加器接口实例化
			Adder_Interface #(
				.DATA_WIDTH_4Bit(8'd1),				//4Bit位宽指数
				.ADDER_MODE("FA"),					//加法器模式,DEFAULT/HA/FA/CRA/CLA/CSA/CCA/KST/BKT
				.DATA_WIDTH(8'd1)					//加法计算位宽
			)Adder_Interface_Inst1(
				.i_A(cal_serialg[i][1]),			//加数A
				.i_B(cal_serialg[i][0]),			//加数B
				.i_Ci(cal_serialh[i + 1]),			//上一级进位Cin,无进位则给0
				.o_Sum(cal_serialw[i]),				//和数Sum
				.o_Co(cal_serialt[i])				//进位Cout
			);
		end
		
		//----------------输出信号处理-------------//
		//读通道-数据信号
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)mbus_rdata_o <= 2'b00;
			else mbus_rdata_o <= {cal_serialw[0],~cal_serialt[1]};
		end
		
	end endgenerate

	
	//----------------输入信号缓存-------------//
	//写通道
	D_FF #(1,0)D_FF1_Inst0(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wvalid,mbus_wvalid_i[0]);
	D_FF #(1,0)D_FF1_Inst1(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wen,mbus_wen_i);
	
	S_FF #(INITIAL_DELAY,0)S_FF_Inst0(i_clk,i_rstn,1'b1,mbus_wvalid_i[0] & mbus_wen_i,mbus_wvalid_i[INITIAL_DELAY:1]);
	S_FF #(INITIAL_DELAY + 1,0)S_FF_Inst1(i_clk,i_rstn,1'b1,i_mbus_wlast,mbus_wlast_i);
	
	D_FF #(1,0)D_FF1_Inst2(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wdata_x[0],mbus_wdata_x_i[0]);
	D_FF #(1,0)D_FF1_Inst3(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wdata_x[1],mbus_wdata_x_i[1]);
	D_FF #(1,0)D_FF1_Inst4(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wdata_y[0],mbus_wdata_y_i[0]);
	D_FF #(1,0)D_FF1_Inst5(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wdata_y[1],mbus_wdata_y_i[1]);
	
endmodule

