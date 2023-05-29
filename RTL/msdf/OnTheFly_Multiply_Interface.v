`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/12 15:41:24
// Design Name: 
// Module Name: OnTheFly_Multiply_Interface
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

//Online计算乘法接口
module OnTheFly_Multiply_Interface
#(
	parameter RADIX_MODE	= 8'd1,				//进制模式,默认2**RADIX_MODE进制
	parameter ENCODING_MODE	= "signed-digit",	//编码模式,signed-digit/borrow-save
	parameter ACCURATE_MAX	= 8'd64,				//最大支持精度数
	parameter DATA_WIDTH	= 8'd2				//数据位宽
)
(
	input i_clk,
	input i_rstn,
	
	//----------------外部控制信号--------------//
	//写通道
	input i_mbus_wen,							//写使能信号,高电平有效
	input [DATA_WIDTH - 1:0]i_mbus_wdata_x,		//写数据,乘数X
	input [DATA_WIDTH - 1:0]i_mbus_wdata_y,		//写数据,乘数Y
	input i_mbus_wvalid,						//写数据有效信号
	input i_mbus_wlast,							//写数据结束信号
	output o_mbus_wready,						//写准备好信号
	
	//读通道
	output [DATA_WIDTH - 1:0]o_mbus_rdata,		//读数据
	output o_mbus_rvalid,						//读数据有效信号
	output o_mbus_rlast							//读数据结束信号
);
	
	//根据进制模式
	//如果是2进制
	generate if(RADIX_MODE == 8'd1)begin:gen_radix2_multiply
	
		//2进制Online计算乘法接口实例化
		OnTheFly_Multiply_Radix2_Interface #(
			.ENCODING_MODE(ENCODING_MODE),				//编码模式,signed-digit/borrow-save
			.ACCURATE_MAX(ACCURATE_MAX)					//最大支持精度数
		)OnTheFly_Multiply_Radix2_Interface_Inst(
			.i_clk(i_clk),
			.i_rstn(i_rstn),
			
			//----------------外部控制信号--------------//
			//写通道
			.i_mbus_wen(i_mbus_wen),					//写使能信号,高电平有效
			.i_mbus_wdata_x(i_mbus_wdata_x),			//写数据,乘数X
			.i_mbus_wdata_y(i_mbus_wdata_y),			//写数据,乘数Y
			.i_mbus_wvalid(i_mbus_wvalid),				//写数据有效信号
			.i_mbus_wlast(i_mbus_wlast),				//写数据结束信号
			.o_mbus_wready(o_mbus_wready),				//写准备好信号
			
			//读通道
			.o_mbus_rdata(o_mbus_rdata),				//读数据
			.o_mbus_rvalid(o_mbus_rvalid),				//读数据有效信号
			.o_mbus_rlast(o_mbus_rlast)					//读数据结束信号
		);
	end
	
	//未知
	else begin:gen_unkown
		//----------------输出信号连线--------------//
		//写通道
		assign o_mbus_wready = 0;
		
		//读通道
		assign o_mbus_rdata = 0;
		assign o_mbus_rvalid = 0;
		assign o_mbus_rlast = 0;
	end endgenerate
	
endmodule

//2进制Online计算乘法接口:输入数据范围(-1,1)
module OnTheFly_Multiply_Radix2_Interface
#(
	parameter ENCODING_MODE	= "signed-digit",	//编码模式,signed-digit/borrow-save
	parameter ACCURATE_MAX	= 8'd64				//最大支持精度数
)
(
	input i_clk,
	input i_rstn,
	
	//----------------外部控制信号--------------//
	//写通道
	input i_mbus_wen,							//写使能信号,高电平有效
	input [1:0]i_mbus_wdata_x,					//写数据,乘数X
	input [1:0]i_mbus_wdata_y,					//写数据,乘数Y
	input i_mbus_wvalid,						//写数据有效信号
	input i_mbus_wlast,							//写数据结束信号
	output o_mbus_wready,						//写准备好信号
	
	//读通道
	output [1:0]o_mbus_rdata,					//读数据
	output o_mbus_rvalid,						//读数据有效信号
	output o_mbus_rlast							//读数据结束信号
);
	//------------------参数数据----------------//
	localparam INITIAL_DELAY = 4'd3;
	
	//------------------标志信号----------------//
	wire flag_residual_reset;					//残差数据复位
	reg flag_cal_over = 0;						//乘法计算结束标志
	
	//------------------编码数据----------------//
	wire [1:0]encode_minus1;
	wire [1:0]encode_plus1;
	wire [1:0]encode_product;
	
	//------------------计算数据----------------//
	//CA-Reg数据
	reg ca_resetn = 0;
	wire [ACCURATE_MAX - 1:0]ca_datax;
	wire [ACCURATE_MAX - 1:0]ca_datay;
	
	//Selector数据
	wire [1:0]sel_xj4;
	wire [1:0]sel_yj4;
	reg [ACCURATE_MAX + 4:0]sel_datax = 0;
	reg [ACCURATE_MAX + 4:0]sel_datay = 0;
	
	//负数进位
	reg Cx_data = 0;
	reg Cy_data = 0;
	
	//加法数据
	//[4:2]压缩加法
	wire [3:0]adder42_data[ACCURATE_MAX + 4:0];	//[4:2]加法器计算数据
	wire [ACCURATE_MAX + 4:0]adder42_ci;		//[4:2]加法器上一级进位
	wire [ACCURATE_MAX + 4:0]adder42_sum;		//[4:2]加法器伪和
	wire [ACCURATE_MAX + 4:0]adder42_carry;		//[4:2]加法器进位
	wire [ACCURATE_MAX + 4:0]adder42_co;		//[4:2]加法器进位输出
	wire [ACCURATE_MAX + 4:0]adder42_hasCarry;	//[4:2]加法器是否存在进位
	
	//V-Block,CPA进位传播加法器
	wire [3:0]adder_cpa_v_data;					//CPA进位传播4bit加法器输出
	wire adder_cpa_co;
	
	//迭代残差数据
	reg [ACCURATE_MAX + 3:0]residual_ws = 0;	//伪和
	reg [ACCURATE_MAX + 3:0]residual_wc = 0;	//进位
	
	//----------------输入缓存信号--------------//
	//写通道
	wire mbus_wen_i;
	wire [1:0]mbus_wdata_x_i;
	wire [1:0]mbus_wdata_y_i;
	wire [INITIAL_DELAY + 2:0]mbus_wvalid_i;
	wire [INITIAL_DELAY + 2:0]mbus_wlast_i;
	
	//------------------输出信号----------------//
	//写通道
	reg mbus_wready_o = 0;
	
	//读通道
	reg [1:0]mbus_rdata_o = 0;
	reg mbus_rvalid_o = 0;
	reg mbus_rlast_o = 0;
	
	//----------------其他信号连线--------------//
	//残差数据复位
	assign flag_residual_reset = flag_cal_over & mbus_wvalid_i[0];
	
	//如果是signed-digit编码方式
	generate if(ENCODING_MODE == "signed-digit")begin:gen_signed_digit_encode
		//用到的编码信号
		assign encode_minus1 = 2'b01;
		assign encode_plus1 = 2'b10;
		assign encode_product = {~adder_cpa_v_data[3],adder_cpa_v_data[3]};
	end
	//如果是borrow-save编码方式
	else if(ENCODING_MODE == "borrow-save")begin:gen_borrow_save_encode
		//用到的编码信号
		assign encode_minus1 = 2'b11;
		assign encode_plus1 = 2'b01;
		assign encode_product = {adder_cpa_v_data[3],1'b1};
	end
	//自定义编码
	else begin:gen_self_define_encode
		//用到的编码信号
		assign encode_minus1 = 0;
		assign encode_plus1 = 0;
		assign encode_product = 0;
	end endgenerate
	
	//----------------输出信号连线--------------//
	//写通道
	assign o_mbus_wready = mbus_wready_o;
	
	//读通道
	assign o_mbus_rdata = mbus_rdata_o;
	assign o_mbus_rvalid = mbus_rvalid_o;
	assign o_mbus_rlast = mbus_rlast_o;
	
	//----------------输出信号处理--------------//
	//写通道
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)mbus_wready_o <= 1'b1;
		else if(i_mbus_wen == 1'b1 && i_mbus_wvalid == 1'b1)mbus_wready_o <= 1'b0;
		else if(mbus_wlast_i[INITIAL_DELAY] == 1'b1)mbus_wready_o <= 1'b1;
		else mbus_wready_o <= mbus_wready_o;
	end
	
	//读通道-读数据有效信号
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)mbus_rvalid_o <= 1'b0;
		else mbus_rvalid_o <= mbus_wvalid_i[INITIAL_DELAY + 2];
	end
	
	//读通道-读数据结束信号
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)mbus_rlast_o <= 1'b0;
		else mbus_rlast_o <= mbus_wlast_i[INITIAL_DELAY + 2];
	end
	
	//第一级
	//动态转换接口实例化CA-RegX
	OnTheFly_Conversion_Interface #(
		.RADIX_MODE(8'd1),							//进制模式,默认2**RADIX_MODE进制
		.ENCODING_MODE(ENCODING_MODE),				//编码模式,signed-digit/borrow-save
		.SHIFT_ENABLE(1'd0),						//移位使能,1'd1代表是移位进入数据;1'd0代表在下一个Bit添加数据
		.ACCURATE_MAX(ACCURATE_MAX),				//最大支持精度数
		.DATA_WIDTH(8'd2)							//写数据位宽
	)OnTheFly_Conversion_Interface_InstX(
		.i_clk(i_clk),
		.i_rstn(ca_resetn),
		
		//----------------外部控制信号--------------//
		//写通道
		.i_mbus_wen(mbus_wen_i),					//写使能信号,高电平有效
		.i_mbus_wdata(mbus_wdata_x_i),				//写数据
		.i_mbus_wvalid(mbus_wvalid_i[0]),			//写数据有效信号
		
		//读通道
		.o_mbus_rdata(ca_datax)						//读数据
	);
	
	//动态转换接口实例化CA-RegY
	OnTheFly_Conversion_Interface #(
		.RADIX_MODE(8'd1),							//进制模式,默认2**RADIX_MODE进制
		.ENCODING_MODE(ENCODING_MODE),				//编码模式,signed-digit/borrow-save
		.SHIFT_ENABLE(1'd0),						//移位使能,1'd1代表是移位进入数据;1'd0代表在下一个Bit添加数据
		.ACCURATE_MAX(ACCURATE_MAX),				//最大支持精度数
		.DATA_WIDTH(8'd2)							//写数据位宽
	)OnTheFly_Conversion_Interface_InstY(
		.i_clk(i_clk),
		.i_rstn(ca_resetn),
		
		//----------------外部控制信号--------------//
		//写通道
		.i_mbus_wen(i_mbus_wen),					//写使能信号,高电平有效
		.i_mbus_wdata(i_mbus_wdata_y),				//写数据
		.i_mbus_wvalid(i_mbus_wvalid),				//写数据有效信号
		
		//读通道
		.o_mbus_rdata(ca_datay)						//读数据
	);
	
	//CA复位信号
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)ca_resetn <= 1'b0;
		else if(mbus_wlast_i[INITIAL_DELAY] == 1'b1)ca_resetn <= 1'b0;
		else ca_resetn <= 1'b1;
	end
	
	//第二级Selector
	//X选择
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)sel_datax <= {(ACCURATE_MAX + 5){1'b0}};
		else if(sel_yj4 == encode_minus1)sel_datax <= {5'b11111,~ca_datax};
		else if(sel_yj4 == encode_plus1)sel_datax <= {5'd0,ca_datax};
		else sel_datax <= {(ACCURATE_MAX + 5){1'b0}};
	end
	
	//Y选择
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)sel_datay <= {(ACCURATE_MAX + 5){1'b0}};
		else if(sel_xj4 == encode_minus1)sel_datay <= {5'b11111,~ca_datay};
		else if(sel_xj4 == encode_plus1)sel_datay <= {5'd0,ca_datay};
		else sel_datay <= {(ACCURATE_MAX + 5){1'b0}};
	end
	
	//进位数据X
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)Cx_data <= 1'b0;
		else if(sel_xj4 == encode_minus1)Cx_data <= 1'b1;
		else Cx_data <= 1'b0;
	end
	
	//进位数据Y
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)Cy_data <= 1'b0;
		else if(sel_yj4 == encode_minus1)Cy_data <= 1'b1;
		else Cy_data <= 1'b0;
	end
	
	//第三级[4:2]ADDER
	generate begin
		genvar i;
		
		//最低位
		assign adder42_data[0][0] = Cx_data;
		assign adder42_data[0][1] = sel_datay[0];
		assign adder42_data[0][2] = sel_datax[0];
		assign adder42_data[0][3] = 1'd0;
		assign adder42_ci[0] = Cy_data;
		assign adder42_hasCarry[0] = 1'b0;
		
		//数据连接
		for(i = 1;i < ACCURATE_MAX + 5;i = i + 1)begin
			assign adder42_data[i][0] = residual_wc[i - 1];
			assign adder42_data[i][1] = sel_datay[i];
			assign adder42_data[i][2] = sel_datax[i];
			assign adder42_data[i][3] = residual_ws[i - 1];
			assign adder42_ci[i] = adder42_co[i - 1];
			assign adder42_hasCarry[i] = (adder42_sum[i] & adder42_carry[i - 1]) | (adder42_sum[i] & adder42_hasCarry[i - 1]) | (adder42_carry[i - 1] & adder42_hasCarry[i - 1]);
		end
		
		//遍历连接
		for(i = 0;i < ACCURATE_MAX + 5;i = i + 1)begin
			//[4:2]压缩加法器接口实例化
			Compressed_Adder_Interface #(
				.COMPRESSED_MODE("4-2"),	//压缩加法器模式,3-2/4-2/5-2
				.DATA_WIDTH_0(4),			//数据位宽0,与模式有关,"-"前面的数据
				.DATA_WIDTH_1(1)			//数据位宽1,与模式有关,进位宽度
			)Compressed_Adder_Interface_Inst(
				.i_X(adder42_data[i]),		//加数,X[0]~X[DATA_WIDTH_0 - 1]
				.i_Ci(adder42_ci[i]),		//上一级进位Cin
				.o_Sum(adder42_sum[i]),		//伪和
				.o_Carry(adder42_carry[i]),	//进位
				.o_Co(adder42_co[i])		//输出,如果是3-2压缩器,则此位不生效
			);
		end
	end endgenerate
	
	//第四级V-Block
	//4bit加法器实例化
	Adder_Interface #(
		.DATA_WIDTH_4Bit(8'd1),									//4Bit位宽指数
		.ADDER_MODE("CSA")										//加法器模式,DEFAULT/HA/FA/CRA/CLA/CSA/CCA/KST/BKT
	)Adder_Interface_Inst(
		.i_A(adder42_sum[ACCURATE_MAX + 4:ACCURATE_MAX + 1]),	//加数A
		.i_B(adder42_carry[ACCURATE_MAX + 3:ACCURATE_MAX]),		//加数B
		.i_Ci(adder42_hasCarry[ACCURATE_MAX]),					//上一级进位Cin,无进位则给0
		.o_Sum(adder_cpa_v_data),								//和数Sum
		.o_Co(adder_cpa_co)										//进位Cout
	);

	//第五级SELM
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)mbus_rdata_o <= 2'b00;
		else if(adder_cpa_v_data[3:1] == 3'b000)mbus_rdata_o <= 2'b00;
		else if(adder_cpa_v_data[3:1] == 3'b111)mbus_rdata_o <= 2'b00;
		else mbus_rdata_o <= encode_product;
	end
	
	//第六级M-Block计算
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'd0)begin
			residual_ws[ACCURATE_MAX + 3] <= 1'd0;
		end else if(flag_residual_reset == 1'b1)begin
			residual_ws[ACCURATE_MAX + 3] <= 1'd0;
		end else if(mbus_wvalid_i[INITIAL_DELAY + 2] == 1'b0)begin
			residual_ws[ACCURATE_MAX + 3] <= adder_cpa_v_data[2] ^ adder42_hasCarry[ACCURATE_MAX + 2];
		end else if(adder_cpa_v_data[1] == 1'b0)begin
			residual_ws[ACCURATE_MAX + 3] <= (~adder_cpa_v_data[2] & adder_cpa_v_data[3]) ^ adder42_hasCarry[ACCURATE_MAX + 2];
		end else if(adder_cpa_v_data[3:2] == 2'b01)begin
			residual_ws[ACCURATE_MAX + 3] <= 1'd0 ^ adder42_hasCarry[ACCURATE_MAX + 2];
		end else begin
			residual_ws[ACCURATE_MAX + 3] <= 1'd1 ^ adder42_hasCarry[ACCURATE_MAX + 2];
		end
	end
	
	//残差数据更新
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'd0)begin
			residual_ws[ACCURATE_MAX + 2:0] <= {(ACCURATE_MAX + 3){1'd0}};
			residual_wc[ACCURATE_MAX + 3:0] <= {(ACCURATE_MAX + 4){1'd0}};
		end else if(flag_residual_reset == 1'b1)begin
			residual_ws[ACCURATE_MAX + 2:0] <= {(ACCURATE_MAX + 3){1'd0}};
			residual_wc[ACCURATE_MAX + 3:0] <= {(ACCURATE_MAX + 4){1'd0}};
		end else begin
			residual_ws[ACCURATE_MAX + 2:0] <= adder42_sum[ACCURATE_MAX + 2:0];
			residual_wc[ACCURATE_MAX + 3:0] <= {1'd0,adder42_carry[ACCURATE_MAX + 1:0],1'd0};
		end 
	end
	
	//检测上一次乘法是否计算完毕,下次开始计算时清零
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'd0)flag_cal_over <= 1'b0;
		else if(mbus_wlast_i[INITIAL_DELAY + 2] == 1'b1)flag_cal_over <= 1'b1;
		else if(mbus_wvalid_i[0] == 1'b1)flag_cal_over <= 1'b0;
		else flag_cal_over <= flag_cal_over;
	end
	
	//----------------其他信号缓存-------------//
	//选择信号
	D_FF #(2,0)D_FF2_Inst2(i_clk,i_rstn,1'b0,1'b0,1'b1,mbus_wdata_x_i,sel_xj4);
	D_FF #(2,0)D_FF2_Inst3(i_clk,i_rstn,1'b0,1'b0,1'b1,mbus_wdata_y_i,sel_yj4);
	
	//----------------输入信号缓存-------------//
	//写通道
	D_FF #(1,0)D_FF1_Inst0(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wen,mbus_wen_i);
	D_FF #(2,0)D_FF2_Inst0(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wdata_x,mbus_wdata_x_i);
	D_FF #(2,0)D_FF2_Inst1(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wdata_y,mbus_wdata_y_i);
	S_FF #(INITIAL_DELAY + 3,0)S_FF_Inst0(i_clk,i_rstn,1'b1,i_mbus_wvalid,mbus_wvalid_i);
	S_FF #(INITIAL_DELAY + 3,0)S_FF_Inst1(i_clk,i_rstn,1'b1,i_mbus_wlast,mbus_wlast_i);
	
endmodule