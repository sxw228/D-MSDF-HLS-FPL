`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/22 15:27:46
// Design Name: 
// Module Name: tb_OnTheFly_Adder_Interface
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


module tb_OnTheFly_Adder_Interface();
	
	//定义时钟信号
	reg clk_100MHz = 0;
	
	//复位信号
	reg resetn = 0;
	
	//时钟反转
	always #5 clk_100MHz = ~clk_100MHz;
	
	//接口参数
	parameter RADIX_MODE		= 8'd1;				//进制模式,默认2**RADIX_MODE进制
	parameter PARALLEL_ENABLE	= 1'd1;				//并行使能
	parameter ENCODING_MODE		= "signed-digit";	//编码模式,signed-digit/borrow-save
	parameter DATA_WIDTH		= 8'd2;				//数据位宽
	parameter ACCURATE_SET		= 8'd8;
	parameter TEST_NUMBER		= 8'd0;				//正确:
	
	
	//----------------外部控制信号--------------//
	//写通道
	reg mbus_wen = 0;							//写使能信号,高电平有效
	reg signed[DATA_WIDTH - 1:0]mbus_wdata_x = 0;//写数据,乘数X
	reg signed[DATA_WIDTH - 1:0]mbus_wdata_y = 0;//写数据,乘数Y
	reg mbus_wvalid = 0;						//写数据有效信号
	reg mbus_wlast = 0;							//写数据结束信号
	
	//读通道
	wire [DATA_WIDTH - 1:0]mbus_rdata_serial;	//读数据
	wire mbus_rvalid_serial;					//读数据有效信号
	wire mbus_rlast_serial;						//读数据结束信号
	wire [DATA_WIDTH - 1:0]mbus_rdata_parallel;	//读数据
	wire mbus_rvalid_parallel;					//读数据有效信号
	wire mbus_rlast_parallel;					//读数据结束信号
	
	//计数
	integer i;
	integer seed = TEST_NUMBER;
	
	//标志
	reg flag_initial_x = 0;
	reg flag_initial_y = 0;

	//激励信号产生
	generate if(RADIX_MODE == 8'd1)begin:gen_radix2_tb
		
		//测试例0:3代表-1
		if(TEST_NUMBER == 8'd0)begin:gen_res_10301310
			initial begin
				#5;
				resetn = 1'b1;
				
				@(posedge clk_100MHz);
				
				//准备写入
				mbus_wen = 1'b1;
				mbus_wvalid = 1'b1;
				mbus_wlast = 1'b0;
				if(ENCODING_MODE == "borrow-save")begin
					//数据
					mbus_wdata_x = 0;mbus_wdata_y = 1;
					@(posedge clk_100MHz);
					mbus_wdata_x = 1;mbus_wdata_y = 0;
					@(posedge clk_100MHz);
					mbus_wdata_x = 0;mbus_wdata_y = -1;
					@(posedge clk_100MHz);
					mbus_wdata_x = -1;mbus_wdata_y = 0;
					@(posedge clk_100MHz);
					mbus_wdata_x = 1;mbus_wdata_y = 1;
					@(posedge clk_100MHz);
					mbus_wdata_x = 1;mbus_wdata_y = -1;
					@(posedge clk_100MHz);
					mbus_wdata_x = 0;mbus_wdata_y = -1;
					@(posedge clk_100MHz);
					mbus_wdata_x = -1;mbus_wdata_y = 0;
				end else if(ENCODING_MODE == "signed-digit")begin
					//数据
					mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b10;
					@(posedge clk_100MHz);
					mbus_wdata_x = 2'b10;mbus_wdata_y = 2'b00;
					@(posedge clk_100MHz);
					mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b01;
					@(posedge clk_100MHz);
					mbus_wdata_x = 2'b01;mbus_wdata_y = 2'b00;
					@(posedge clk_100MHz);
					mbus_wdata_x = 2'b10;mbus_wdata_y = 2'b10;
					@(posedge clk_100MHz);
					mbus_wdata_x = 2'b10;mbus_wdata_y = 2'b01;
					@(posedge clk_100MHz);
					mbus_wdata_x = 2'b00;mbus_wdata_y = 2'b01;
					@(posedge clk_100MHz);
					mbus_wdata_x = 2'b01;mbus_wdata_y = 2'b00;
				end
				
				mbus_wlast = 1'b1;
				@(posedge clk_100MHz);
				mbus_wdata_x = 2'b00;
				mbus_wdata_y = 2'b00;
				
				//结束写入
				mbus_wen = 1'b0;
				mbus_wvalid = 1'b0;
				mbus_wlast = 1'b0;
				@(posedge clk_100MHz);
				
			end
		end
	
		//测试例随机
		else begin:gen_res_rand
			initial begin
				#5;
				resetn = 1'b1;
				
				forever begin
					resetn = 1'b0;
					@(posedge clk_100MHz);
					resetn = 1'b1;
					@(posedge clk_100MHz);
					
					flag_initial_x = 1'd0;
					flag_initial_y = 1'd0;
					
					//准备写入
					mbus_wen = 1'b1;
					mbus_wvalid = 1'b1;
						
					//数据
					for(i = 0;i < ACCURATE_SET;i = i + 1)begin
						
						mbus_wdata_x = $random(seed) % 2;
						mbus_wdata_y = $random(seed) % 2;
						
						//确保输入数据x∈(-1,1)
						if(flag_initial_x == 1'd0)begin
							while(mbus_wdata_x < 0)mbus_wdata_x = $random(seed) % 2;
						end
						//确保输入数据y∈(-1,1)
						if(flag_initial_y == 1'd0)begin
							while(mbus_wdata_y < 0)mbus_wdata_y = $random(seed) % 2;
						end
						
						if(mbus_wdata_x > 0)flag_initial_x = 1;
						if(mbus_wdata_y > 0)flag_initial_y = 1;
						
						if(ENCODING_MODE == "signed-digit")begin
							if(mbus_wdata_x == -1)mbus_wdata_x = 2'b01;
							else if(mbus_wdata_x == 1)mbus_wdata_x = 2'b10;
							
							if(mbus_wdata_y == -1)mbus_wdata_y = 2'b01;
							else if(mbus_wdata_y == 1)mbus_wdata_y = 2'b10;
						end
						
						//写数据结束信号
						if(i == ACCURATE_SET - 1)mbus_wlast = 1'b1;
						else mbus_wlast = 1'b0;
						
						@(posedge clk_100MHz);
					end
					
					mbus_wdata_x = 0;
					mbus_wdata_y = 0;
					
					//结束写入
					mbus_wen = 1'b0;
					mbus_wvalid = 1'b0;
					mbus_wlast = 1'b0;
					@(posedge clk_100MHz);
					@(posedge clk_100MHz);
					@(posedge clk_100MHz);
				end
			end
		end
	end

	endgenerate
	
	//动态加法接口
	OnTheFly_Adder_Interface #(
		.RADIX_MODE(RADIX_MODE),					//进制模式,默认2**RADIX_MODE进制
		.PARALLEL_ENABLE(1'd0),						//并行使能
		.ENCODING_MODE(ENCODING_MODE),				//编码模式,signed-digit/borrow-save
		.DATA_WIDTH(DATA_WIDTH)						//数据位宽
	)OnTheFly_Adder_Interface_InstSerial(
		.i_clk(clk_100MHz),
		.i_rstn(resetn),
		
		//----------------外部控制信号--------------//
		//写通道
		.i_mbus_wen(mbus_wen),						//写使能信号,高电平有效
		.i_mbus_wdata_x(mbus_wdata_x),				//写数据,乘数X
		.i_mbus_wdata_y(mbus_wdata_y),				//写数据,乘数Y
		.i_mbus_wvalid(mbus_wvalid),				//写数据有效信号
		.i_mbus_wlast(mbus_wlast),					//写数据结束信号
		
		//读通道
		.o_mbus_rdata(mbus_rdata_serial),			//读数据
		.o_mbus_rvalid(mbus_rvalid_serial),			//读数据有效信号
		.o_mbus_rlast(mbus_rlast_serial)			//读数据结束信号
	);
	
	//动态加法接口
	OnTheFly_Adder_Interface #(
		.RADIX_MODE(RADIX_MODE),					//进制模式,默认2**RADIX_MODE进制
		.PARALLEL_ENABLE(1'd1),						//并行使能
		.ENCODING_MODE(ENCODING_MODE),				//编码模式,signed-digit/borrow-save
		.DATA_WIDTH(DATA_WIDTH)						//数据位宽
	)OnTheFly_Adder_Interface_InstParallel(
		.i_clk(clk_100MHz),
		.i_rstn(resetn),
		
		//----------------外部控制信号--------------//
		//写通道
		.i_mbus_wen(mbus_wen),						//写使能信号,高电平有效
		.i_mbus_wdata_x(mbus_wdata_x),				//写数据,乘数X
		.i_mbus_wdata_y(mbus_wdata_y),				//写数据,乘数Y
		.i_mbus_wvalid(mbus_wvalid),				//写数据有效信号
		.i_mbus_wlast(mbus_wlast),					//写数据结束信号
		
		//读通道
		.o_mbus_rdata(mbus_rdata_parallel),			//读数据
		.o_mbus_rvalid(mbus_rvalid_parallel),		//读数据有效信号
		.o_mbus_rlast(mbus_rlast_parallel)			//读数据结束信号
	);
endmodule
