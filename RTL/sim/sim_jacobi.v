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


module sim_jacobi();

	//定义时钟信号
	reg clk_100MHz = 0;
	//复位信号
	reg resetn = 0;
	//时钟反转
	always #5 clk_100MHz = ~clk_100MHz;
	
    reg [47:0]digit_vector_x0;
    reg [47:0]digit_vector_x1;
    reg [47:0]digit_vector_x0_new;
    reg [47:0]digit_vector_x1_new;

	wire [2:0]jacobi_x0_start_in;
	reg jacobi_x0_start_valid;
    wire jacobi_x0_start_ready;
	wire [2:0]jacobi_x0_end_out;
	wire jacobi_x0_end_valid;
    reg jacobi_x0_end_ready;
	assign jacobi_x0_start_in = digit_vector_x0[47:45];

	wire [2:0]jacobi_x1_start_in;
	wire jacobi_x1_start_valid;
    wire jacobi_x1_start_ready;
	wire [2:0]jacobi_x1_end_out;
	wire jacobi_x1_end_valid;
    reg jacobi_x1_end_ready;
	assign jacobi_x1_start_in = digit_vector_x1[47:45];
    assign jacobi_x1_start_valid = jacobi_x0_start_valid;
    //控制状态机
    //写状态 写完状态 更新
    //有效写计数
    reg [7:0]start_cnt_x0;
    always @(posedge clk_100MHz ) begin
        if(~resetn)begin
            jacobi_x0_start_valid <= 1'b1;
        end
        else if(jacobi_x0_start_in[2]==1'b1)begin         //发送了last就拉低        
            jacobi_x0_start_valid <= 1'b0;
        end
        else if(digit_vector_x0_new[2]==1'b1)begin     //更新后重新开始
            jacobi_x0_start_valid <= 1'b1;
        end
    end
    
    always @(posedge clk_100MHz ) begin
        if(~resetn)begin
            start_cnt_x0 <= 'd0;
        end
        else if(digit_vector_x0[2]==1'b1)begin                  //归零
            start_cnt_x0 <= 'd0;
        end
        else if(jacobi_x0_start_valid & jacobi_x0_start_ready)begin     //有效输出
            start_cnt_x0 <= start_cnt_x0+1;
        end
    end
    //有效读计数
    reg [7:0]end_cnt_x0;
    always @(posedge clk_100MHz ) begin
        if(~resetn)begin
            end_cnt_x0 <= 'd0;
        end
        else if(digit_vector_x0_new[2]==1'b1)begin                  //归零
            end_cnt_x0 <= 'd0;
        end
        else if(jacobi_x0_end_valid & jacobi_x0_end_ready)begin     //有效输出
            end_cnt_x0 <= end_cnt_x0+1;
        end
    end

    //输入数据更新x0
    //0000_0000_0000_0001
    //0000_0000_0000_0000
    //0000_0000_0000_0000
    always @(posedge clk_100MHz ) begin
        if(~resetn)begin
            digit_vector_x0 <= 'd4;
        end
        else if(jacobi_x0_start_valid & jacobi_x0_start_ready)begin  //有效输入
            digit_vector_x0 <= {digit_vector_x0[44:0],3'b000};
        end
        else if(digit_vector_x0_new[2]==1'b1)begin      //已经输出完了，可以更新
            digit_vector_x0 <= digit_vector_x0_new;
            jacobi_x0_start_valid <=1'b1;
        end
        
        
    end

    //输入数据更新x1
    //0000_0000_0000_0001
    //0000_0000_0000_0000
    //0000_0000_0000_0000
    always @(posedge clk_100MHz ) begin
        if(~resetn)begin
            digit_vector_x1 <= 'd4;
        end
        else if(jacobi_x1_start_valid & jacobi_x1_start_ready)begin  //有效输入
            digit_vector_x1 <= {digit_vector_x1[44:0],3'b000};
        end
        else if(digit_vector_x1_new[2]==1'b1)begin      //已经输出完了，可以更新
            digit_vector_x1 <= digit_vector_x1_new;
        end 
    end
    
    //输出数据更新x0_new
    always @(posedge clk_100MHz ) begin
        if(~resetn)begin
            digit_vector_x0_new <= 'd0;
        end
        else if(jacobi_x0_end_valid & jacobi_x0_end_ready)begin  //有效输出
            digit_vector_x0_new <= {digit_vector_x0_new[44:0],jacobi_x0_end_out};
        end
    end
    //输入数据更新x1_new
    always @(posedge clk_100MHz ) begin
        if(~resetn)begin
            digit_vector_x1_new <= 'd0;
        end
        else if(jacobi_x1_end_valid & jacobi_x1_end_ready)begin  //有效输出
            digit_vector_x1_new <= {digit_vector_x1_new[44:0],jacobi_x1_end_out};
        end
    end
	//激励信号产生
    initial begin
        
        jacobi_x0_end_ready = 1;
        jacobi_x1_end_ready = 1;
  
        #50;
        resetn = 1'b1;
        #50
        @(posedge clk_100MHz )
 
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        @(posedge clk_100MHz )
        // jacobi_x0_start_valid = 1'b0;
        // jacobi_x1_start_valid = 1'b0;
        #5000;
        $stop;

    end


	jacobi_2 jacobi_2_inst
    (
        .clk(clk_100MHz),
        .rstn(resetn),

        .start_in_0(jacobi_x0_start_in),
        .start_valid_0(jacobi_x0_start_valid),
        .start_ready_0(jacobi_x0_start_ready),


        .end_out_0(jacobi_x0_end_out),
        .end_valid_0(jacobi_x0_end_valid),
		.end_ready_0(jacobi_x0_end_ready),

        .start_in_1(jacobi_x1_start_in),
        .start_valid_1(jacobi_x1_start_valid),
        .start_ready_1(jacobi_x1_start_ready),


        .end_out_1(jacobi_x1_end_out),
        .end_valid_1(jacobi_x1_end_valid),
		.end_ready_1(jacobi_x1_end_ready)

        
    );

wire[31:0]jacobi_x0_parallel;
wire[31:0]jacobi_x1_parallel;

OnTheFly_Conversion_Interface 
#( 
	.RADIX_MODE(8'd1),				//进制模式,默认2**RADIX_MODE进制
	.ENCODING_MODE("signed-digit"),	//编码模式,signed-digit/borrow-save
	.SHIFT_ENABLE(1'd0),				//移位使能,1'd1代表是移位进入数据;1'd0代表在下一个Bit添加数据
	.ACCURATE_MAX(8'd64),			//最大支持精度数
	.DATA_WIDTH(8'd2)				//写数据位宽
) OnTheFly_Conversion_Interface_x0
(
	.i_clk(clk_100MHz),
	.i_rstn(resetn),
	
	//----------------外部控制信号--------------//
	//写通道
	.i_mbus_wen(jacobi_x0_end_valid),							//写使能信号,高电平有效
	.i_mbus_wdata(jacobi_x0_end_out[1:0]),		//写数据[DATA_WIDTH - 1:0]
	.i_mbus_wvalid(jacobi_x0_end_valid),						//写数据有效信号
	
	//读通道
	.o_mbus_rdata(jacobi_x0_parallel)		//读数据[ACCURATE_MAX - 1:0]
);
OnTheFly_Conversion_Interface
#(
	.RADIX_MODE(8'd1),				//进制模式,默认2**RADIX_MODE进制
	.ENCODING_MODE("signed-digit"),	//编码模式,signed-digit/borrow-save
	.SHIFT_ENABLE(1'd0),				//移位使能,1'd1代表是移位进入数据;1'd0代表在下一个Bit添加数据
	.ACCURATE_MAX(8'd32),			//最大支持精度数
	.DATA_WIDTH(8'd2)				//写数据位宽
) OnTheFly_Conversion_Interface_x1
( 
	.i_clk(clk_100MHz),
	.i_rstn(resetn),
	
	//----------------外部控制信号--------------//
	//写通道
	.i_mbus_wen(jacobi_x1_end_valid),							//写使能信号,高电平有效
	.i_mbus_wdata(jacobi_x1_end_out[1:0]),		//写数据[DATA_WIDTH - 1:0]
	.i_mbus_wvalid(jacobi_x1_end_valid),						//写数据有效信号
	
	//读通道
	.o_mbus_rdata(jacobi_x1_parallel)		//读数据[ACCURATE_MAX - 1:0]
);







endmodule
