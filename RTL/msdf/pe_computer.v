module pe_compute
#(  //--------------------------------------------------------------------------------------
	parameter peId = 0,
	parameter puId = 0,
    parameter integer dataLen = 32,
    parameter integer logNumFn = 3
    //--------------------------------------------------------------------------------------
) ( //--------------------------------------------------------------------------------------
    input  wire [dataLen  - 1 : 0 ] operand1,
    input  wire                     operand1_v,
    input  wire [dataLen  - 1 : 0 ] operand2,
    input  wire                     operand2_v,
    input  wire [dataLen  - 1 : 0 ] operand3,
    input  wire                     operand3_v,
    input  wire [logNumFn - 1 : 0 ] fn,
    output reg  [dataLen  - 1 : 0 ] resultOut,
    output reg                      done,
    output wire                     eol_flag
);  //--------------------------------------------------------------------------------------



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




endmodule
