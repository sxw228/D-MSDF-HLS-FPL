`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/29 16:26:29
// Design Name: 
// Module Name: OnTheFly_Integer_Interface
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

//动态Online整数转Online数据接口
module OnTheFly_Integer_Interface
#(
	parameter RADIX_MODE	= 8'd1,				//进制模式,默认2**RADIX_MODE进制
	parameter ENCODING_MODE	= "signed-digit",	//编码模式,signed-digit/borrow-save
	parameter ADJUST_ENABLE	= 1'b0,				//调整使能,1'b1代表开启,开启时自动归一化去零
	parameter INT_WIDTH		= 8'd8,				//整数位宽
	parameter OFFSET_WIDTH	= 8'd4,				//偏移位宽
	parameter DATA_WIDTH	= 8'd2				//数据位宽
)
(
	input i_clk,
	input i_rstn,
	
	//----------------外部控制信号--------------//
	//写通道
	input i_mbus_wen,							//写使能信号,高电平有效
	input [OFFSET_WIDTH - 1:0]i_mbus_woffset,	//写偏移数,由于前几级累加导致精度的偏移
	input signed[INT_WIDTH:0]i_mbus_wdata,		//写数据,有符号数,用于转换输出
	input i_mbus_wvalid,						//写数据有效信号
	input i_mbus_wlast,							//写数据结束信号
	
	//读通道
	output [DATA_WIDTH - 1:0]o_mbus_rdata,		//读数据
	output o_mbus_rvalid,						//读数据有效信号
	output o_mbus_rlast							//读数据结束信号
);
	
	//如果是2进制
	generate if(RADIX_MODE == 8'd1)begin:gen_radix2_integer_trans
		//2进制动态Online整数转Online数据接口实例化
		OnTheFly_Integer_Radix2_Interface #(
			.ENCODING_MODE(ENCODING_MODE),				//编码模式,signed-digit/borrow-save
			.ADJUST_ENABLE(ADJUST_ENABLE),				//调整使能,1'b1代表开启,开启时自动归一化去零
			.INT_WIDTH(INT_WIDTH),						//整数位宽
			.OFFSET_WIDTH(OFFSET_WIDTH)					//偏移位宽
		)OnTheFly_Integer_Radix2_Interface_Inst(
			.i_clk(i_clk),
			.i_rstn(i_rstn),
			
			//----------------外部控制信号--------------//
			//写通道
			.i_mbus_wen(i_mbus_wen),					//写使能信号,高电平有效
			.i_mbus_woffset(i_mbus_woffset),			//写偏移数,由于前几级累加导致精度的偏移
			.i_mbus_wdata(i_mbus_wdata),				//写数据,有符号数,用于转换输出
			.i_mbus_wvalid(i_mbus_wvalid),				//写数据有效信号
			.i_mbus_wlast(i_mbus_wlast),				//写数据结束信号
			
			//读通道
			.o_mbus_rdata(o_mbus_rdata),				//读数据
			.o_mbus_rvalid(o_mbus_rvalid),				//读数据有效信号
			.o_mbus_rlast(o_mbus_rlast)					//读数据结束信号
		);
	end
		
	//自定义
	else begin:gen_self_define
		//----------------输出信号连线--------------//
		//读通道
		assign o_mbus_rdata = 0;
		assign o_mbus_rvalid = 0;
		assign o_mbus_rlast = 0;
	end endgenerate
	
endmodule

//2进制动态Online整数转Online数据接口:
//例如:
// 3-> 0.75->0.11;		 5-> 0.625->0.101;
//-3->-0.75->0.-1-1;	-5->-0.625->0.-10-1;
module OnTheFly_Integer_Radix2_Interface
#(
	parameter ENCODING_MODE	= "signed-digit",	//编码模式,signed-digit/borrow-save
	parameter ADJUST_ENABLE	= 1'b0,				//调整使能,1'b1代表开启,开启时自动归一化去零
	parameter INT_WIDTH		= 8'd8,				//整数位宽
	parameter OFFSET_WIDTH	= 8'd4				//偏移位宽
)
(
	input i_clk,
	input i_rstn,
	
	//----------------外部控制信号--------------//
	//写通道
	input i_mbus_wen,							//写使能信号,高电平有效
	input [OFFSET_WIDTH - 1:0]i_mbus_woffset,	//写偏移数,由于前几级累加导致精度的偏移
	input signed[INT_WIDTH:0]i_mbus_wdata,		//写数据,有符号数,用于转换输出
	input i_mbus_wvalid,						//写数据有效信号
	input i_mbus_wlast,							//写数据结束信号
	
	//读通道
	output [1:0]o_mbus_rdata,					//读数据
	output o_mbus_rvalid,						//读数据有效信号
	output o_mbus_rlast							//读数据结束信号
);
	//------------------计数信号----------------//
	reg [OFFSET_WIDTH - 1:0]write_cnt = 0;
	
	//------------------编码数据----------------//
	wire [1:0]encode_minus1;
	wire [1:0]encode_plus1;
	
	//------------------数据信号----------------//
	reg [INT_WIDTH:0]Ram_Data = 0;
	reg Ram_Sign = 0;
	
	//------------------控制信号----------------//
	//写使能
	wire [1:0]write_enable;
	
	//写偏移标志,如果写数目达到偏移数,则标志为1;否则为0;如果偏移数为0,则标志为1
	reg flag_write_offset = 0;
	
	//写初始标志,移位找到第一个非零位置
	reg flag_write_start = 0;
	
	//----------------输入缓存信号--------------//
	//写通道
	wire [1:0]mbus_wen_i;
	wire [OFFSET_WIDTH - 1:0]mbus_woffset_i;
	reg [INT_WIDTH:0]mbus_wdata_i = 0;
	wire [1:0]mbus_wvalid_i;
	wire [2:0]mbus_wlast_i;
	
	//------------------输出信号----------------//
	//读通道
	reg [1:0]mbus_rdata_o = 0;
	reg mbus_rvalid_o = 0;
	reg mbus_rlast_o = 0;
	
	//----------------其他信号连线--------------//
	//写使能信号
	assign write_enable = mbus_wvalid_i & mbus_wen_i;
	
	//如果是signed-digit编码方式
	generate if(ENCODING_MODE == "signed-digit")begin:gen_signed_digit_encode
		//用到的编码信号
		assign encode_minus1 = 2'b01;
		assign encode_plus1 = 2'b10;
	end
	//如果是borrow-save编码方式
	else if(ENCODING_MODE == "borrow-save")begin:gen_borrow_save_encode
		//用到的编码信号
		assign encode_minus1 = 2'b11;
		assign encode_plus1 = 2'b01;
	end
	//自定义编码
	else begin:gen_self_define_encode
		//用到的编码信号
		assign encode_minus1 = 0;
		assign encode_plus1 = 0;
	end endgenerate
	
	//----------------输出信号连线--------------//
	//读通道
	assign o_mbus_rdata = mbus_rdata_o;
	assign o_mbus_rvalid = mbus_rvalid_o;
	assign o_mbus_rlast = mbus_rlast_o;
	
	//----------------输出信号处理--------------//
	//读通道-读数据信号
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)mbus_rdata_o <= 2'b00;
		else if(flag_write_offset == 1'b0)mbus_rdata_o <= 2'b00;
		else if(Ram_Sign == 1'b1 && Ram_Data[INT_WIDTH] == 1'b1)mbus_rdata_o <= encode_minus1;
		else if(Ram_Sign == 1'b0 && Ram_Data[INT_WIDTH] == 1'b1)mbus_rdata_o <= encode_plus1;
		else mbus_rdata_o <= 2'b00;
	end
	
	//读通道-读数据有效信号
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)mbus_rvalid_o <= 1'b0;
		else mbus_rvalid_o <= flag_write_start;
	end
	
	//读通道-读数据结束信号
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)mbus_rlast_o <= 1'b0;
		else mbus_rlast_o <= mbus_wlast_i[2];
	end
	
	//----------------主要任务处理-------------//
	//写计数
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)write_cnt <= {OFFSET_WIDTH{1'd0}};
		else if(flag_write_start == 1'b0)write_cnt <= {OFFSET_WIDTH{1'd0}};
		else write_cnt <= write_cnt + 1'd1;
	end
	
	//写偏移标志
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)flag_write_offset <= 1'd0;
		else if(flag_write_start == 1'b0)flag_write_offset <= 1'd0;
		else if(write_cnt >= mbus_woffset_i)flag_write_offset <= 1'd1;
		else flag_write_offset <= flag_write_offset;
	end
	
	//是否开启调整使能
	generate if(ADJUST_ENABLE == 1'b1)begin:gen_auto_adjust
		//写初始标志
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)flag_write_start <= 1'd0;
			else if(write_enable[1] == 1'b0)flag_write_start <= 1'd0;
			else if(Ram_Data == 0)flag_write_start <= 1'd1;
			else if(Ram_Data[INT_WIDTH - 1] == 1'b1)flag_write_start <= 1'd1;
			else flag_write_start <= flag_write_start;
		end
	end else begin:gen_common_source
		//写初始标志
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)flag_write_start <= 1'd0;
			else if(write_enable[1] == 1'b0)flag_write_start <= 1'd0;
			else flag_write_start <= 1'd1;
		end
	end endgenerate
	
	//RAM数据
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)Ram_Data <= {(INT_WIDTH + 1){1'd0}};
		else if(write_enable[1] == 1'b0)Ram_Data <= {1'd0,mbus_wdata_i[INT_WIDTH - 1:0]};
		else if(flag_write_offset == 1'b0 && flag_write_start == 1'b1)Ram_Data <= Ram_Data;
		else Ram_Data <= Ram_Data << 1;
	end
	
	//RAM符号
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)Ram_Sign <= 1'b0;
		else if(write_enable[1] == 1'b0)Ram_Sign <= mbus_wdata_i[INT_WIDTH];
		else Ram_Sign <= Ram_Sign;
	end
	
	//----------------输入信号缓存-------------//
	//写通道
	S_FF #(2,0)S_FF_Inst0(i_clk,i_rstn,1'b1,i_mbus_wen,mbus_wen_i);
	S_FF #(2,0)S_FF_Inst1(i_clk,i_rstn,1'b1,i_mbus_wvalid,mbus_wvalid_i);
	S_FF #(3,0)S_FF_Inst2(i_clk,i_rstn,1'b1,i_mbus_wlast,mbus_wlast_i);
	D_FF #(OFFSET_WIDTH,0)D_FF_Inst0(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_woffset,mbus_woffset_i);
	
	//写数据求绝对值
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)begin
			mbus_wdata_i <= {(INT_WIDTH + 1){1'd0}};
		end else if(i_mbus_wdata[INT_WIDTH] == 1'b0)begin
			mbus_wdata_i <= i_mbus_wdata;
		end else begin
			mbus_wdata_i[INT_WIDTH] <= 1'b1;
			mbus_wdata_i[INT_WIDTH - 1:0] <= (~i_mbus_wdata[INT_WIDTH - 1:0]) + 1'b1;
		end
	end
	
endmodule