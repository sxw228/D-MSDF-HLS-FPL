`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/15 16:56:27
// Design Name: 
// Module Name: tb_OnTheFly_INCR_Interface
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


module tb_OnTheFly_INCR_Interface();

//定义时钟信号
	reg clk_100MHz = 0;
	
	//复位信号
	reg resetn = 0;
	
	//时钟反转
	always #5 clk_100MHz = ~clk_100MHz;
	
	//接口参数
	parameter RADIX_MODE	= 8'd1;				//进制模式,默认2**RADIX_MODE进制
	parameter ENCODING_MODE	= "signed-digit";	//编码模式,signed-digit/borrow-save
	parameter PIPLINE_ENABLE= 1'b1;				//流水线模式使能,如果开启,则自动默认wend信号触发时,将最后一轮加法输出直接输出,而不是等待外部请求
	parameter ACCURATE_MAX	= 8'd8;				//最大支持精度数
	parameter DATA_LEN_WIDTH= 8'd5;				//数据长度宽度
	parameter EXTEND_WIDTH	= 8'd1;				//扩展位宽,给累加器使用,如3次累加,不能低于1;位宽为2;5次累加,位宽为3
	parameter DATA_WIDTH	= 8'd2;				//数据位宽
	
	parameter ACCURATE_SET	= 8'd8;
	parameter TEST_NUMBER	= 8'd0;				//正确:0,1,2,3,4,5,6,7
	
	
	//----------------外部控制信号--------------//
	//写通道
	reg mbus_wen = 0;							//写使能信号,高电平有效
	reg signed[DATA_WIDTH - 1:0]mbus_wdata = 0;	//写数据,加数
	reg mbus_wvalid = 0;						//写数据有效信号
	reg mbus_wlast = 0;							//写数据结束信号
	reg mbus_wend = 0;							//写计算结束信号,代表着这是最后一次的输入数据
	wire mbus_wready;							//写准备好信号
	
	//读通道
	reg mbus_rrq = 0;							//读请求信号,高电平有效
	reg [DATA_LEN_WIDTH - 1:0]mbus_rlen = 0;	//读长度,在请求信号拉高的同时加载
	wire mbus_rready;							//读准备好,高电平有效
	wire [DATA_WIDTH - 1:0]mbus_rdata;			//读数据
	wire mbus_rvalid;							//读数据有效信号
	wire mbus_rlast;							//读数据结束信号
	
	//计数
	integer i;
	integer seed = TEST_NUMBER;
	
	//标志
	reg flag_initial = 0;
	
	//激励信号产生
	generate if(RADIX_MODE == 8'd1)begin:gen_radix2_tb
		
		//测试例0:3代表-1
		if(TEST_NUMBER == 8'd0)begin:gen_res_10301310
			initial begin
				#5;
				resetn = 1'b1;
				@(posedge clk_100MHz);
				
				forever begin
					if(mbus_wready == 1'b0)begin
						mbus_wen = 1'b0;
						mbus_wvalid = 1'b0;
						mbus_wlast = 1'b0;
						@(posedge clk_100MHz);
					end else if(mbus_wend == 1'b1 && PIPLINE_ENABLE == 1'b0)begin
						mbus_wen = 1'b0;
						mbus_wvalid = 1'b0;
						mbus_wlast = 1'b0;
						@(posedge clk_100MHz);
						
						if(mbus_rlast == 1'b1)begin
							mbus_wend = 1'b0;
							@(posedge clk_100MHz);
						end
					end else begin
						
						//准备写入
						mbus_wen = 1'b1;
						mbus_wend = 1'b1;
						mbus_wvalid = 1'b1;
				
						if(ENCODING_MODE == "borrow-save")begin
							//数据
							mbus_wdata = 0;
							@(posedge clk_100MHz);
							mbus_wdata = 1;
							@(posedge clk_100MHz);
							mbus_wdata = 0;
							@(posedge clk_100MHz);
							mbus_wdata = -1;
							@(posedge clk_100MHz);
							mbus_wdata = 1;
							@(posedge clk_100MHz);
							mbus_wdata = 1;
							@(posedge clk_100MHz);
							mbus_wdata = 0;
							@(posedge clk_100MHz);
							mbus_wdata = -1;
						end else if(ENCODING_MODE == "signed-digit")begin
							//数据
							mbus_wdata = 2'b00;
							@(posedge clk_100MHz);
							mbus_wdata = 2'b10;
							@(posedge clk_100MHz);
							mbus_wdata = 2'b00;
							@(posedge clk_100MHz);
							mbus_wdata = 2'b01;
							@(posedge clk_100MHz);
							mbus_wdata = 2'b10;
							@(posedge clk_100MHz);
							mbus_wdata = 2'b10;
							@(posedge clk_100MHz);
							mbus_wdata = 2'b00;
							@(posedge clk_100MHz);
							mbus_wdata = 2'b01;
						end
						
						mbus_wlast = 1'b1;
						@(posedge clk_100MHz);
						mbus_wdata = 2'b00;
						
						//结束写入
						mbus_wen = 1'b0;
						mbus_wvalid = 1'b0;
						mbus_wlast = 1'b0;
						@(posedge clk_100MHz);
					end
				end
			end
		end

		//测试例随机
		else begin:gen_res_rand
			initial begin
				#5;
				resetn = 1'b1;
				@(posedge clk_100MHz);
				
				forever begin
					if(mbus_wready == 1'b0)begin
						mbus_wen = 1'b0;
						mbus_wvalid = 1'b0;
						mbus_wlast = 1'b0;
						@(posedge clk_100MHz);
					end else if(mbus_wend == 1'b1 && PIPLINE_ENABLE == 1'b0)begin
						mbus_wen = 1'b0;
						mbus_wvalid = 1'b0;
						mbus_wlast = 1'b0;
						@(posedge clk_100MHz);
						
						if(mbus_rlast == 1'b1)begin
							mbus_wend = 1'b0;
							@(posedge clk_100MHz);
						end
					end else begin
						
						//准备写入
						mbus_wen = 1'b1;
						mbus_wend = 1'b1;
						mbus_wvalid = 1'b1;
						flag_initial = 0;
						
						//数据
						for(i = 0;i < ACCURATE_SET;i = i + 1)begin
							
							mbus_wdata = $random(seed) % 2;
							
							//确保输入数据x∈(-1,1)
							if(flag_initial == 1'd0)begin
								while(mbus_wdata < 0)mbus_wdata = $random(seed) % 2;
							end
							
							if(mbus_wdata > 0)flag_initial = 1;
							
							if(ENCODING_MODE == "signed-digit")begin
								if(mbus_wdata == -1)mbus_wdata = 2'b01;
								else if(mbus_wdata == 1)mbus_wdata = 2'b10;
							end
							
							//写数据结束信号
							if(i == ACCURATE_SET - 1)mbus_wlast = 1'b1;
							else mbus_wlast = 1'b0;
							
							@(posedge clk_100MHz);
						end
						
						mbus_wdata = 0;
						
						//结束写入
						mbus_wen = 1'b0;
						mbus_wvalid = 1'b0;
						mbus_wlast = 1'b0;
						@(posedge clk_100MHz);
					end
				end
			end
		end
	end

	endgenerate
	
	//读请求
	always@(posedge clk_100MHz or negedge resetn)begin
		if(resetn == 1'b0)begin
			mbus_rrq <= 1'b0;
			mbus_rlen <= {DATA_LEN_WIDTH{1'b0}};
		end else if(mbus_rready == 1'b1)begin
			mbus_rrq <= 1'b1;
			mbus_rlen <= {DATA_LEN_WIDTH{1'b0}};
		end else begin
			mbus_rrq <= 1'b0;
			mbus_rlen <= mbus_rlen;
		end
	end
	
	wire mbus_wen_buff;
	wire [DATA_WIDTH - 1:0]mbus_wdata_buff;
	wire mbus_wvalid_buff;
	wire mbus_wlast_buff;
	wire mbus_wend_buff;
	
	D_FF #(1,0)D_FF_Inst0(clk_100MHz,resetn,1'b0,1'b0,1'b1,mbus_wen,mbus_wen_buff);
	D_FF #(DATA_WIDTH,0)D_FF_Inst1(clk_100MHz,resetn,1'b0,1'b0,1'b1,mbus_wdata,mbus_wdata_buff);
	D_FF #(1,0)D_FF_Inst2(clk_100MHz,resetn,1'b0,1'b0,1'b1,mbus_wvalid,mbus_wvalid_buff);
	D_FF #(1,0)D_FF_Inst3(clk_100MHz,resetn,1'b0,1'b0,1'b1,mbus_wlast,mbus_wlast_buff);
	D_FF #(1,0)D_FF_Inst4(clk_100MHz,resetn,1'b0,1'b0,1'b1,mbus_wend,mbus_wend_buff);
	
	//动态乘加器接口
	OnTheFly_INCR_Interface #(
		.RADIX_MODE(RADIX_MODE),					//进制模式,默认2**RADIX_MODE进制
		.ENCODING_MODE(ENCODING_MODE),				//编码模式,signed-digit/borrow-save
		.PIPLINE_ENABLE(PIPLINE_ENABLE),			//流水线模式使能,如果开启,则自动默认wend信号触发时,将最后一轮加法输出直接输出,而不是等待外部请求
		.ACCURATE_MAX(ACCURATE_MAX),				//最大支持精度数
		.DATA_LEN_WIDTH(DATA_LEN_WIDTH),			//数据长度宽度
		.EXTEND_WIDTH(EXTEND_WIDTH),				//扩展位宽,给累加器使用,不能低于1;如3次累加,位宽为2;5次累加,位宽为3
		.DATA_WIDTH(DATA_WIDTH)						//数据位宽
	)OnTheFly_INCR_Interface_Inst(
		.i_clk(clk_100MHz),
		.i_rstn(resetn),
		
		//----------------外部控制信号--------------//
		//写通道
		.i_mbus_wen(mbus_wen_buff),					//写使能信号,高电平有效
		.i_mbus_wdata(mbus_wdata_buff),				//写数据,加数
		.i_mbus_wvalid(mbus_wvalid_buff),			//写数据有效信号
		.i_mbus_wlast(mbus_wlast_buff),				//写数据结束信号
		.i_mbus_wend(mbus_wend_buff),				//写计算结束信号,代表着这是最后一次的输入数据
		.o_mbus_wready(mbus_wready),				//写准备好信号
		
		//读通道
		.i_mbus_rrq(mbus_rrq),						//读请求信号,高电平有效
		.i_mbus_rlen(mbus_rlen),					//读长度,在请求信号拉高的同时加载
		.o_mbus_rready(mbus_rready),				//读准备好,高电平有效
		.o_mbus_rdata(mbus_rdata),					//读数据
		.o_mbus_rvalid(mbus_rvalid),				//读数据有效信号
		.o_mbus_rlast(mbus_rlast)					//读数据结束信号
	);
	
endmodule
