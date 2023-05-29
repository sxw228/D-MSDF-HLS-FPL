`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/15 20:35:29
// Design Name: 
// Module Name: tb_OnTheFly_Multiply_Interface
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


module tb_OnTheFly_Multiply_Interface();

	//定义时钟信号
	reg clk_100MHz = 0;
	
	//复位信号
	reg resetn = 0;
	
	//时钟反转
	always #5 clk_100MHz = ~clk_100MHz;
	
	//接口参数
	parameter RADIX_MODE	= 8'd1;				//进制模式,默认2**RADIX_MODE进制
	parameter ENCODING_MODE	= "signed-digit";	//编码模式,signed-digit/borrow-save
	parameter ACCURATE_MAX	= 8'd64;				//最大支持精度数
	parameter DATA_WIDTH	= 8'd2;				//数据位宽
	parameter ACCURATE_SET	= 8'd8;
	parameter TEST_NUMBER	= 8'd0;				//正确:0,1,2,3,4,5,6,7
	
	
	//----------------外部控制信号--------------//
	//写通道
	reg mbus_wen = 0;							//写使能信号,高电平有效
	reg signed[DATA_WIDTH - 1:0]mbus_wdata_x = 0;//写数据,乘数X
	reg signed[DATA_WIDTH - 1:0]mbus_wdata_y = 0;//写数据,乘数Y
	reg mbus_wvalid = 0;						//写数据有效信号
	reg mbus_wlast = 0;							//写数据结束信号
	wire mbus_wready;							//写准备好信号
	
	wire mbus_wen_buff;
	wire [DATA_WIDTH - 1:0]mbus_wdata_x_buff;
	wire [DATA_WIDTH - 1:0]mbus_wdata_y_buff;
	wire mbus_wvalid_buff;
	wire mbus_wlast_buff;

	wire mbus_wen_buff1;
	wire [DATA_WIDTH - 1:0]mbus_wdata_x_buff1;
	wire [DATA_WIDTH - 1:0]mbus_wdata_y_buff1;
	wire mbus_wvalid_buff1;
	wire mbus_wlast_buff1;
	
	//读通道
	wire [DATA_WIDTH - 1:0]mbus_rdata;			//读数据
	wire mbus_rvalid;							//读数据有效信号
	wire mbus_rlast;							//读数据结束信号
	
	//乘积结果
	wire [2 * ACCURATE_MAX - 1:0]Product_Data;
	
	//计数
	integer i;
	integer seed = TEST_NUMBER;
	
	//标志
	reg flag_initial_x = 0;
	reg flag_initial_y = 0;
	


	wire msdf_mult_valid;
	reg end_ready;
	wire [1:0]msdf_mult_dataOut;
	wire msdf_mult_lastOut;

	//激励信号产生
	generate if(RADIX_MODE == 8'd1)begin:gen_radix2_tb
		
		//测试例0:3代表-1
		if(TEST_NUMBER == 8'd0)begin:gen_res_10301310
			initial begin
				end_ready = 1;
				#50;
				resetn = 1'b1;
				#50;
				//准备写入
				mbus_wen = 1'b1;
				mbus_wvalid = 1'b1;
				/*
				0 0
				0 0
				2 0
				0 0
				0 1
				2 0
				0 0
				0 1
				2 0
				0 1
				0 1
				0 1
				0 1
				0 0
				3 1
				6 5
				*/
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b00;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b00;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b10;mbus_wdata_y = 2'b00;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b00;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b01;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b10;mbus_wdata_y = 2'b00;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b00; 
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b01;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b10;mbus_wdata_y = 2'b00;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b00;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b00;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b00;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b00;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b00;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b00; 
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b00;
				mbus_wlast = 1'b1;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;
				mbus_wdata_y = 2'b00;
				
				//结束写入
				mbus_wen = 1'b0;
				mbus_wvalid = 1'b0;
				mbus_wlast = 1'b0;
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				//准备写入
				mbus_wen = 1'b1;
				mbus_wvalid = 1'b1;
				
				//数据
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b00;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b10;mbus_wdata_y = 2'b10;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b10;mbus_wdata_y = 2'b00;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b10;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b01;mbus_wdata_y = 2'b01;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b10;mbus_wdata_y = 2'b01;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b10; 
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b01;mbus_wdata_y = 2'b10;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b10;mbus_wdata_y = 2'b00;
				
				
				mbus_wlast = 1'b1;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;
				mbus_wdata_y = 2'b00;
				
				//结束写入
				mbus_wen = 1'b0;
				mbus_wvalid = 1'b0;
				mbus_wlast = 1'b0;
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);


				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				@(posedge clk_100MHz);
				$stop;
				
				//等待写入完成
				/*forever begin
					if(mbus_rlast == 1'b1)resetn = 1'b0;
					@(posedge clk_100MHz);
				end*/
				
			end
		end
		

	end

	endgenerate
	
	D_FF #(1,0)D_FF1_Inst0(clk_100MHz,resetn,1'b0,1'b0,1'b1,mbus_wen,mbus_wen_buff);
	D_FF #(DATA_WIDTH,0)D_FF_Inst0(clk_100MHz,resetn,1'b0,1'b0,1'b1,mbus_wdata_x,mbus_wdata_x_buff);
	D_FF #(DATA_WIDTH,0)D_FF_Inst1(clk_100MHz,resetn,1'b0,1'b0,1'b1,mbus_wdata_y,mbus_wdata_y_buff);
	D_FF #(1,0)D_FF1_Inst1(clk_100MHz,resetn,1'b0,1'b0,1'b1,mbus_wvalid,mbus_wvalid_buff);
	D_FF #(1,0)D_FF1_Inst2(clk_100MHz,resetn,1'b0,1'b0,1'b1,mbus_wlast,mbus_wlast_buff);
	
	
	//动态乘法接口
	OnTheFly_Multiply_Interface #(
		.RADIX_MODE(RADIX_MODE),					//进制模式,默认2**RADIX_MODE进制
		.ENCODING_MODE(ENCODING_MODE),				//编码模式,signed-digit/borrow-save
		.ACCURATE_MAX(ACCURATE_MAX),				//最大支持精度数
		.DATA_WIDTH(DATA_WIDTH)						//数据位宽
	)OnTheFly_Multiply_Interface_Inst(
		.i_clk(clk_100MHz),
		.i_rstn(resetn),
		
		//----------------外部控制信号--------------//
		//写通道
		.i_mbus_wen(mbus_wen_buff),					//写使能信号,高电平有效
		.i_mbus_wdata_x(mbus_wdata_x_buff),			//写数据,乘数X
		.i_mbus_wdata_y(mbus_wdata_y_buff),			//写数据,乘数Y
		.i_mbus_wvalid(mbus_wvalid_buff),			//写数据有效信号
		.i_mbus_wlast(mbus_wlast_buff),				//写数据结束信号
		.o_mbus_wready(mbus_wready),				//写准备好信号
		
		//读通道
		.o_mbus_rdata(mbus_rdata),					//读数据
		.o_mbus_rvalid(mbus_rvalid),				//读数据有效信号
		.o_mbus_rlast(mbus_rlast)					//读数据结束信号
	);
	
	wire [2:0]MSDF_Multiply_mbus_rdata;
	wire MSDF_Multiply_mbus_rvalid;
	wire MSDF_Multiply_mbus_rlast;
	//动态乘法接口新
	MSDF_Multiply_Interface #(
		.RADIX_MODE(RADIX_MODE),					//进制模式,默认2**RADIX_MODE进制
		.ENCODING_MODE(ENCODING_MODE),				//编码模式,signed-digit/borrow-save
		.ACCURATE_MAX(ACCURATE_MAX),				//最大支持精度数
		.DATA_WIDTH(DATA_WIDTH),					//数据位宽
		.POINT_WIDTH(8)
	)MSDF_Multiply_Interface_Inst(
		.i_clk(clk_100MHz),
		.i_rstn(resetn),
		
		//----------------外部控制信号--------------//
		//写通道
		.i_mbus_wen(mbus_wen_buff),					//写使能信号,高电平有效
		.i_mbus_wdata_x(mbus_wdata_x_buff),			//写数据,乘数X
		.i_mbus_wdata_y(mbus_wdata_y_buff),			//写数据,乘数Y
		.i_mbus_wpoint(1'b0),
		.i_mbus_wvalid(mbus_wvalid_buff),			//写数据有效信号
		.i_mbus_wlast(mbus_wlast_buff),				//写数据结束信号
		
		
		//读通道
		.o_mbus_rdata(MSDF_Multiply_mbus_rdata),					//读数据
		.o_mbus_rpoint(),
		.o_mbus_rvalid(MSDF_Multiply_mbus_rvalid),				//读数据有效信号
		.o_mbus_rlast(MSDF_Multiply_mbus_rlast),					//读数据结束信号
	
		//不知道干啥的
		.i_mbus_rstop(1'b0),
		.i_mbus_rclr(1'b0)
	);

	OnTheFly_Conversion_Interface #(
		.RADIX_MODE(8'd1),							//进制模式,默认2**RADIX_MODE进制
		.ENCODING_MODE(ENCODING_MODE),				//编码模式,signed-digit/borrow-save
		.SHIFT_ENABLE(1'd0),						//移位使能,1'd1代表是移位进入数据;1'd0代表在下一个Bit添加数据
		.ACCURATE_MAX(ACCURATE_MAX * 2),			//最大支持精度数
		.DATA_WIDTH(DATA_WIDTH)						//数据位宽
	)OnTheFly_Conversion_Interface_InstRes(
		.i_clk(clk_100MHz),
		.i_rstn(resetn),
		
		//----------------外部控制信号--------------//
		//写通道
		.i_mbus_wen(1'b1),							//写使能信号,高电平有效
		.i_mbus_wdata(mbus_rdata),					//写数据
		.i_mbus_wvalid(mbus_rvalid |(~mbus_wvalid)),//写数据有效信号
		
		//读通道
		.o_mbus_rdata(Product_Data)					//读数据
	);

	//弹性电路接口
	msdf_mult_op 
	#(.TARGET_PRECISION(16))
	msdf_add_op_inst0
    (
        .clk(clk_100MHz),
        .rst(~resetn),

        .dataInArray_0({mbus_wlast_buff,mbus_wdata_x_buff}),
        .dataInArray_1({mbus_wlast_buff,mbus_wdata_y_buff}),
        .pValidArray_0(mbus_wvalid_buff),
		.pValidArray_1(mbus_wvalid_buff),
        .readyArray_0(),
		.readyArray_1(),


        .dataOutArray_0(),
        .validArray_0(),
        .nReadyArray_0(1'b1)
    );

	


endmodule
