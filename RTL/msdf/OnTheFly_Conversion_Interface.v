`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/11 10:40:02
// Design Name: 
// Module Name: OnTheFly_Conversion_Interface
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

//动态转换接口
module OnTheFly_Conversion_Interface
#(
	parameter RADIX_MODE		= 8'd1,				//进制模式,默认2**RADIX_MODE进制
	parameter ENCODING_MODE		= "signed-digit",	//编码模式,signed-digit/borrow-save
	parameter SHIFT_ENABLE		= 1'd0,				//移位使能,1'd1代表是移位进入数据;1'd0代表在下一个Bit添加数据
	parameter ACCURATE_MAX		= 8'd64,			//最大支持精度数
	parameter DATA_WIDTH		= 8'd2				//写数据位宽
)
(
	input i_clk,
	input i_rstn,
	
	//----------------外部控制信号--------------//
	//写通道
	input i_mbus_wen,							//写使能信号,高电平有效
	input [DATA_WIDTH - 1:0]i_mbus_wdata,		//写数据
	input i_mbus_wvalid,						//写数据有效信号
	
	//读通道
	output [ACCURATE_MAX - 1:0]o_mbus_rdata		//读数据
);
	
	//根据进制模式
	//如果是2进制
	generate if(RADIX_MODE == 8'd1)begin:gen_radix2_conversion
		//2进制动态转换接口实例化
		OnTheFly_Conversion_Radix2_Interface #(
			.ENCODING_MODE(ENCODING_MODE),		//编码模式,signed-digit/borrow-save
			.SHIFT_ENABLE(SHIFT_ENABLE),		//移位使能,1'd1代表是移位进入数据;1'd0代表在下一个Bit添加数据
			.ACCURATE_MAX(ACCURATE_MAX)			//最大支持精度数
		)OnTheFly_Conversion_Radix2_Interface_Inst(
			.i_clk(i_clk),
			.i_rstn(i_rstn),
			
			//----------------外部控制信号--------------//
			//写通道
			.i_mbus_wen(i_mbus_wen),					//写使能信号,高电平有效
			.i_mbus_wdata(i_mbus_wdata),				//写数据,{-1,0,1};其中signed-digit模式下:{x+,x-}->{01,00,10};borrow-save模式下为有符号数->{11,00,01}
			.i_mbus_wvalid(i_mbus_wvalid),				//写数据有效信号
			
			//读通道
			.o_mbus_rdata(o_mbus_rdata)					//读数据
		);
	end
		
	//如果是4进制
	else if(RADIX_MODE == 8'd2)begin:gen_radix4_conversion
		//4进制动态转换接口实例化
		OnTheFly_Conversion_Radix4_Interface #(
			.ENCODING_MODE(ENCODING_MODE),		//编码模式,signed-digit/borrow-save
			.SHIFT_ENABLE(SHIFT_ENABLE),		//移位使能,1'd1代表是移位进入数据;1'd0代表在下一个Bit添加数据
			.ACCURATE_MAX(ACCURATE_MAX),		//最大支持精度数
			.DATA_WIDTH(DATA_WIDTH)				//写数据位宽
		)OnTheFly_Conversion_Radix4_Interface_Inst(
			.i_clk(i_clk),
			.i_rstn(i_rstn),
			
			//----------------外部控制信号--------------//
			//写通道
			.i_mbus_wen(i_mbus_wen),					//写使能信号,高电平有效
			.i_mbus_wdata(i_mbus_wdata),				//写数据,{-3,-2,-1,0,1,2,3}
			.i_mbus_wvalid(i_mbus_wvalid),				//写数据有效信号
			
			//读通道
			.o_mbus_rdata(o_mbus_rdata)					//读数据
		);
	end
	
	//其他情况
	else begin:gen_unkown
		//----------------输出信号连线--------------//
		//读通道
		assign o_mbus_rdata = 0;
	
	end endgenerate
	
endmodule

//2进制转换:编码{-1,0,1}
module OnTheFly_Conversion_Radix2_Interface
#(
	parameter ENCODING_MODE		= "signed-digit",	//编码模式,signed-digit/borrow-save
	parameter SHIFT_ENABLE		= 1'd0,				//移位使能,1'd1代表是移位进入数据;1'd0代表在下一个Bit添加数据
	parameter ACCURATE_MAX		= 8'd64				//最大支持精度数
)
(
	input i_clk,
	input i_rstn,
	
	//----------------外部控制信号--------------//
	//写通道
	input i_mbus_wen,							//写使能信号,高电平有效
	input [1:0]i_mbus_wdata,					//写数据,{-1,0,1};其中signed-digit模式下:{x+,x-}->{01,00,10};borrow-save模式下为有符号数->{11,00,01}
	input i_mbus_wvalid,						//写数据有效信号
	
	//读通道
	output [ACCURATE_MAX - 1:0]o_mbus_rdata		//读数据
);
	
	//------------------存储数据----------------//
	//存储RAM
	reg [ACCURATE_MAX - 1:0]Ram_Q = 0;
	reg [ACCURATE_MAX - 1:0]Ram_QM = 0;
	
	//加载数据
	wire Shift_Q;
	wire Load_Q;
	wire Shift_QM;
	wire Load_QM;
	
	//------------------控制数据----------------//
	//写使能
	wire write_enable;
	
	//加载使能
	wire Cload_Q;
	wire Cload_QM;
	
	//----------------输入缓存信号--------------//
	//写通道
	wire mbus_wen_i;
	wire [1:0]mbus_wdata_i;
	wire mbus_wvalid_i;
	
	//----------------其他信号连线--------------//
	//写使能
	assign write_enable = i_mbus_wen & i_mbus_wvalid;
	
	//如果编码模式是signed-digit
	generate if(ENCODING_MODE == "signed-digit")begin:gen_sign_digit_connect
		//使能信号
		assign Cload_Q = ~mbus_wdata_i[1] & mbus_wdata_i[0];	//{x+,x-}->{0,1}->{-1};
		assign Cload_QM = ~mbus_wdata_i[0] & mbus_wdata_i[1];	//{x+,x-}->{1,0}->{1};
		
		//加载数据
		assign Shift_Q = ~mbus_wdata_i[0] & mbus_wdata_i[1];	//{1,0}->1;{0,0}->0;{1,1}->0;
		assign Load_Q = 1'b1;
		assign Shift_QM = mbus_wdata_i[1] | (~mbus_wdata_i[0]);	//{0,1}->0;{0,0}->1;{1,1}->1;
		assign Load_QM = 1'b0;
	end
	
	//如果编码模式是borrow-save
	else if(ENCODING_MODE == "borrow-save")begin:gen_borrow_save_connect
		//使能信号
		assign Cload_Q = mbus_wdata_i[1];						//{1,x}->{<0}->{-1}
		assign Cload_QM = ~mbus_wdata_i[1] & mbus_wdata_i[0];	//{0,1}->{1}
		
		//加载数据
		assign Shift_Q = mbus_wdata_i[0];
		assign Load_Q = 1'b1;
		assign Shift_QM = ~mbus_wdata_i[0];
		assign Load_QM = 1'b0;
	end
	
	//如果编码模式是其他
	else begin:gen_self_define
		//使能信号
		assign Cload_Q = 0;
		assign Cload_QM = 0;
	end endgenerate
	
	//----------------输出信号连线--------------//
	//读通道
	assign o_mbus_rdata = Ram_Q;
	
	//----------------主要任务处理--------------//
	//如果是移位方式
	generate if(SHIFT_ENABLE == 1'd1)begin:gen_store_shift
		//Q存储
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)
				Ram_Q <= {ACCURATE_MAX{1'b0}};
			else if(write_enable == 1'b0)
				Ram_Q <= Ram_Q;
			else if(Cload_Q == 1'b0)begin
				Ram_Q <= {Ram_Q[ACCURATE_MAX - 2:0],Shift_Q};
			end else begin
				Ram_Q <= {Ram_QM[ACCURATE_MAX - 2:0],Load_Q};
			end
		end
		
		//QM存储
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)
				Ram_QM <= {ACCURATE_MAX{1'b0}};
			else if(write_enable == 1'b0)
				Ram_QM <= Ram_QM;
			else if(Cload_QM == 1'b0)begin
				Ram_QM <= {Ram_QM[ACCURATE_MAX - 2:0],Shift_QM};
			end else begin
				Ram_QM <= {Ram_Q[ACCURATE_MAX - 2:0],Load_QM};
			end
		end
	end else begin:gen_store
		//------------------计数数据----------------//
		reg [7:0]data_cnt = 0;
		
		//Q存储
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)
				Ram_Q = {ACCURATE_MAX{1'b0}};
			else if(write_enable == 1'b0)
				Ram_Q = Ram_Q;
			else if(Cload_Q == 1'b0)begin
				Ram_Q[data_cnt] = Shift_Q;
			end else begin
				Ram_Q = Ram_QM;
				Ram_Q[data_cnt] = Load_Q;
			end
		end
		
		//QM存储
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)
				Ram_QM = {ACCURATE_MAX{1'b0}};
			else if(write_enable == 1'b0)
				Ram_QM = Ram_QM;
			else if(Cload_QM == 1'b0)begin
				Ram_QM[data_cnt] = Shift_QM;
			end else begin
				Ram_QM = Ram_Q;
				Ram_QM[data_cnt] = Load_QM;
			end
		end
		
		//输入数据计数
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)
				data_cnt <= ACCURATE_MAX - 1;
			else if(write_enable == 1'b0)
				data_cnt <= data_cnt;
			else 
				data_cnt <= data_cnt - 1'b1;
		end
		
	end endgenerate
	
	
	//----------------输入信号缓存-------------//
	//写通道
	//D_FF #(1,0)D_FF1_Inst0(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wen,mbus_wen_i);
	D_FF #(2,0)D_FF2_Inst0(i_clk,i_rstn,1'b0,1'b0,write_enable,i_mbus_wdata,mbus_wdata_i);
	//D_FF #(1,0)D_FF1_Inst1(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wvalid,mbus_wvalid_i);
	
endmodule

//4进制转换:编码{-3,-2,-1,0,1,2,3}
module OnTheFly_Conversion_Radix4_Interface
#(
	parameter ENCODING_MODE		= "signed-digit",	//编码模式,signed-digit/borrow-save
	parameter SHIFT_ENABLE		= 1'd0,				//移位使能,1'd1代表是移位进入数据;1'd0代表在下一个Bit添加数据
	parameter ACCURATE_MAX		= 8'd64,			//最大支持精度数
	parameter DATA_WIDTH		= 8'd4				//写数据位宽
)
(
	input i_clk,
	input i_rstn,
	
	//----------------外部控制信号--------------//
	//写通道
	input i_mbus_wen,							//写使能信号,高电平有效
	input [DATA_WIDTH - 1:0]i_mbus_wdata,		//写数据,{-3,-2,-1,0,1,2,3}
	input i_mbus_wvalid,						//写数据有效信号
	
	//读通道
	output [ACCURATE_MAX - 1:0]o_mbus_rdata		//读数据
);
	
	//------------------计数信号----------------//
	integer i;
	
	//------------------存储数据----------------//
	//存储RAM
	reg [DATA_WIDTH - 1:0]Ram_Q[ACCURATE_MAX - 1:0];
	reg [DATA_WIDTH - 1:0]Ram_QM[ACCURATE_MAX - 1:0];
	
	//加载数据
	wire [DATA_WIDTH - 1:0]Shift_Q;
	wire [DATA_WIDTH - 1:0]Load_Q;
	wire [DATA_WIDTH - 1:0]Shift_QM;
	wire [DATA_WIDTH - 1:0]Load_QM;
	
	//------------------控制数据----------------//
	//写使能
	wire write_enable;
	
	//加载使能
	wire Cload_Q;
	wire Cload_QM;
	
	//----------------输入缓存信号--------------//
	//写通道
	wire mbus_wen_i;
	wire [DATA_WIDTH - 1:0]mbus_wdata_i;
	wire mbus_wvalid_i;
	
	//----------------其他信号连线--------------//
	//写使能
	assign write_enable = mbus_wen_i & mbus_wvalid_i;
	
	//如果编码模式是signed-digit
	generate if(ENCODING_MODE == "signed-digit")begin:gen_sign_digit_connect
		//{00-11,00-10,00-01,00-00,01-00,10-00,11-00}
		//->{-3,-2,-1,0,1,2,3}
		//使能信号
		assign Cload_Q = mbus_wdata_i[1] | mbus_wdata_i[0];	//x+ < x-
		assign Cload_QM = mbus_wdata_i[3] | mbus_wdata_i[2];//x+>x-
		
		//加载数据
		assign Shift_Q = mbus_wdata_i[3:2];
		assign Load_Q = mbus_wdata_i[1:0];
		assign Shift_QM = ~mbus_wdata_i[1:0];
		assign Load_QM = {mbus_wdata_i[3] & mbus_wdata_i[2],~mbus_wdata_i[2]};
	end
	
	//如果编码模式是borrow-save
	else if(ENCODING_MODE == "borrow-save")begin:gen_borrow_save_connect
		//{101,110,111,000,001,010,011}
		//>{-3,-2,-1,0,1,2,3}
		//使能信号
		assign Cload_Q = mbus_wdata_i[2];
		assign Cload_QM = ~mbus_wdata_i[2] & (mbus_wdata_i[1] | mbus_wdata_i[0]);
		
		//加载数据
		assign Shift_Q = mbus_wdata_i[1:0];
		assign Load_Q = mbus_wdata_i[1:0];
		assign Shift_QM = {mbus_wdata_i[1] & mbus_wdata_i[0],~mbus_wdata_i[1] & mbus_wdata_i[0]};
		assign Load_QM = {mbus_wdata_i[1]^~mbus_wdata_i[0],~mbus_wdata_i[0]};
	end
	
	//如果编码模式是其他
	else begin:gen_self_define
		//使能信号
		assign Cload_Q = 0;
		assign Cload_QM = 0;
	end endgenerate
	
	//----------------输出信号连线--------------//
	generate begin
		genvar j;
		//读通道
		for(j = 0;j < ACCURATE_MAX;j = j + 1)begin
			assign o_mbus_rdata[(j + 1) * DATA_WIDTH - 1:j * DATA_WIDTH] = Ram_Q[j];
		end
	end endgenerate

	//----------------主要任务处理-------------//
	//如果是移位方式
	generate if(SHIFT_ENABLE == 1'd1)begin:gen_store_shift
		
		//Q存储
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)begin
				for(i = 0;i < ACCURATE_MAX;i = i + 1)Ram_Q[i] <= {DATA_WIDTH{1'b0}};
			end else if(write_enable == 1'b0)begin
				for(i = 0;i < ACCURATE_MAX;i = i + 1)Ram_Q[i] <= Ram_Q[i];
			end else if(Cload_Q == 1'b0)begin
				for(i = 1;i < ACCURATE_MAX;i = i + 1)Ram_Q[i] <= Ram_Q[i - 1];
				Ram_Q[0] <= Shift_Q;
			end else begin
				for(i = 1;i < ACCURATE_MAX;i = i + 1)Ram_Q[i] <= Ram_QM[i - 1];
				Ram_Q[0] <= Load_Q;
			end
		end
		
		//QM存储
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)begin
				for(i = 0;i < ACCURATE_MAX;i = i + 1)Ram_QM[i] <= {DATA_WIDTH{1'b0}};
			end else if(write_enable == 1'b0)begin
				for(i = 0;i < ACCURATE_MAX;i = i + 1)Ram_QM[i] <= Ram_QM[i];
			end else if(Cload_QM == 1'b0)begin
				for(i = 1;i < ACCURATE_MAX;i = i + 1)Ram_QM[i] <= Ram_QM[i - 1];
				Ram_QM[0] <= Shift_QM;
			end else begin
				for(i = 1;i < ACCURATE_MAX;i = i + 1)Ram_QM[i] <= Ram_Q[i - 1];
				Ram_QM[0] <= Load_QM;
			end
		end

	end else begin:gen_store
		//------------------计数数据----------------//
		reg [7:0]data_cnt = 0;
		
		//Q存储
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)begin
				for(i = 0;i < ACCURATE_MAX;i = i + 1)Ram_Q[i] = {DATA_WIDTH{1'b0}};
			end else if(write_enable == 1'b0)begin
				for(i = 0;i < ACCURATE_MAX;i = i + 1)Ram_Q[i] = Ram_Q[i];
			end else if(Cload_Q == 1'b0)begin
				Ram_Q[data_cnt] = Shift_Q;
			end else begin
				for(i = 0;i < ACCURATE_MAX;i = i + 1)Ram_Q[i] = Ram_QM[i];
				Ram_Q[data_cnt] = Load_Q;
			end
		end
		
		//QM存储
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)begin
				for(i = 0;i < ACCURATE_MAX;i = i + 1)Ram_QM[i] = {DATA_WIDTH{1'b0}};
			end else if(write_enable == 1'b0)begin
				for(i = 0;i < ACCURATE_MAX;i = i + 1)Ram_QM[i] = Ram_QM[i];
			end else if(Cload_QM == 1'b0)begin
				Ram_QM[data_cnt] = Shift_QM;
			end else begin
				for(i = 0;i < ACCURATE_MAX;i = i + 1)Ram_QM[i] = Ram_Q[i];
				Ram_QM[data_cnt] = Load_QM;
			end
		end
		
		//输入数据计数
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)data_cnt <= ACCURATE_MAX - 1;
			else if(write_enable == 1'b0)data_cnt <= data_cnt;
			else data_cnt <= data_cnt - 1'b1;
		end
		
	end endgenerate
	
	//----------------输入信号缓存-------------//
	//写通道
	D_FF #(1,0)D_FF1_Inst0(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wen,mbus_wen_i);
	D_FF #(DATA_WIDTH,0)D_FF2_Inst0(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wdata,mbus_wdata_i);
	D_FF #(1,0)D_FF1_Inst1(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wvalid,mbus_wvalid_i);
	
endmodule