`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/29 12:15:13
// Design Name: 
// Module Name: msdf_add_op
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

//2进制Online计算加法接口:输入数据范围(-1,1)
module msdf_add_op#(parameter TARGET_PRECISION = 32'd16)
(
    input wire clk,
    input wire rst,

    input wire [2:0] dataInArray_0,
    input wire [2:0] dataInArray_1,

    input wire pValidArray_0,
    input wire pValidArray_1,
    output wire readyArray_0,
    output wire readyArray_1,


    output wire [2:0] dataOutArray_0,
    output wire validArray_0,
    input wire nReadyArray_0
);
    //------------------参数数据----------------//
	localparam INITIAL_DELAY = 4'd1;
    

	//------------------内部信号----------------//
	wire join_valid;				    //输入侧两操作数同时有效
    wire rstn = ~rst;

    wire msdf_ready;                    //msdf单元的ready输出
    wire [1:0]msdf_dout;			    //运算单元的数据输出
    reg msdf_valid;                     //msdf单元的valid输出
    wire msdf_last;                     //msdf单元的last输出


    wire oehb_ready;			        //oehb的ready输出
    
    //控制信号
    reg last_flag;                      //指示是否收到输入的last
    reg ce;							    //运算单元的ce输入
    wire clear;						    //运算单元的clr输入
	
    
    //处理读写计数器
    reg [31:0]wr_cnt;
    reg [31:0]rd_cnt;
    always @(posedge clk ) begin
        if(~rstn)begin
            wr_cnt <= 'd0;
        end
        else if(clear)begin
            wr_cnt <= 'd0;
        end
        else if(join_valid&msdf_ready)begin //有效输入
            wr_cnt <= wr_cnt+1;
        end
    end
    always @(posedge clk ) begin
        if(~rstn)begin
            rd_cnt <= 'd0;
        end
        else if(clear)begin
            rd_cnt <= 'd0;
        end
        else if(msdf_valid&oehb_ready)begin //有效输出
            rd_cnt <= rd_cnt+1;
        end
    end

    //生成last_flag
    always @(posedge clk ) begin
        if(~rstn)begin
            last_flag <= 'd0;
        end
        else if(clear)begin
            last_flag <= 'd0;
        end
        else if(join_valid&msdf_ready& wr_cnt ==TARGET_PRECISION-2)begin //有效输入
            last_flag <= 'd1;
        end
    end
    //生成msdf的ready
    assign msdf_ready = (~last_flag) & (oehb_ready);

    //生成msdf的valid,初始阶段为0，传输阶段跟随输入，补全阶段为1
    always @(posedge clk ) begin
        if(~rstn)begin
            msdf_valid <= 'd0;
        end
        else if(clear)begin
            msdf_valid <= 'd0;
        end
        else if(wr_cnt<=INITIAL_DELAY-1)begin //初始阶段
            msdf_valid <= 'd0;
        end
        else if(~last_flag)begin //传输阶段
            msdf_valid <= join_valid &&msdf_ready;
        end
        else if(rd_cnt<=TARGET_PRECISION-2)begin
            msdf_valid <= 'd1;
        end
        else begin
            msdf_valid <= 'd0;
        end
    end
    //生成msdf的last
    assign msdf_last = rd_cnt==TARGET_PRECISION-1;

    //生成clear
    assign clear = (~rstn)|(rd_cnt==TARGET_PRECISION);
    //生成ce
    always @(*) begin
        if(~rstn)begin
            ce = 'd0;
        end
        else if(clear)begin
            ce = 'd0;
        end
        else if(join_valid&msdf_ready)begin //有效输入
            ce = 'd1;
        end
        else if(last_flag&msdf_valid&oehb_ready)begin
            ce = 'd1;
        end
        else 
            ce = 'd0;
    end
    Join#(.SIZE(2)) 
	Join_int(
        .pValidArray({pValidArray_1,pValidArray_0}),
        .valid(join_valid),
        .readyArray({readyArray_1,readyArray_0}),
        .nReady(oehb_ready)
    );


    OEHB#(.DATA_WIDTH(3))
	OEHB_inst(
        .clk(clk),
        .rstn(rstn),
        .dataInArray({msdf_last,msdf_dout}),
        .pValidArray(msdf_valid),
        .readyArray(oehb_ready),
        .dataOutArray(dataOutArray_0),
        .validArray(validArray_0),
        .nReadyArray(nReadyArray_0)
    );

    wire [1:0]msdf_add_pipeline_dataInArray_0;
    wire [1:0]msdf_add_pipeline_dataInArray_1;
    reg no_more_din;
    always @(posedge clk) begin
        if(rst)begin
            no_more_din <= 1'b0;
        end        
        else if(clear)begin
            no_more_din <= 1'b0;
        end
        else if(wr_cnt==TARGET_PRECISION-1)begin
            no_more_din <= 1'b1;
        end
        else begin
            no_more_din <= no_more_din;
        end
    end
    assign msdf_add_pipeline_dataInArray_0[0] = dataInArray_0[0] & (~no_more_din);
    assign msdf_add_pipeline_dataInArray_0[1] = dataInArray_0[1] & (~no_more_din);
    assign msdf_add_pipeline_dataInArray_1[0] = dataInArray_1[0] & (~no_more_din);
    assign msdf_add_pipeline_dataInArray_1[1] = dataInArray_1[1] & (~no_more_din);

    msdf_add_pipeline msdf_add_pipeline_inst(
        .clk(clk),
        .rstn(rstn),
        .ce(ce),
        .clear(clear),
        .dataInArray_0(msdf_add_pipeline_dataInArray_0),					//操作数1
        .dataInArray_1(msdf_add_pipeline_dataInArray_1),					//操作数2
        .dataOutArray(msdf_dout)					//读数据
    );
	
endmodule
module msdf_add_pipeline
(
	input clk,
	input rstn,
    //控制通道
    input ce,
    input clear,
	//写通道
	input [1:0]dataInArray_0,					//操作数1
	input [1:0]dataInArray_1,					//操作数2
	//读通道
	output wire[1:0]dataOutArray					//读数据
);

    //------------------计算数据----------------//
	//第一级输入
	wire [1:0]input_xj3;
	wire [1:0]input_yj3;

	
	//第一级输出
	wire cal_hj2;
	wire [1:0]cal_gj3;
	reg [1:0]cal_gj2 = 0;

	
	//第二级输出
	wire cal_tj1;
	wire cal_wj2;
	reg cal_wj1;

	
	//第三级输出
	wire [1:0]cal_zj1;

    //输入
    wire [1:0] op0_reg;
    wire [1:0] op1_reg;


    assign op0_reg[0] = ~dataInArray_0[0];
    assign op0_reg[1] = dataInArray_0[1];
    assign op1_reg[0] = ~dataInArray_1[0];
    assign op1_reg[1] = dataInArray_1[1];

    assign input_xj3 = op0_reg;
    assign input_yj3 = op1_reg;
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

    /*****************************************第一拍*************************************************/
    //缓冲打拍对齐,gj+3->gj+2
    always@(posedge clk or negedge rstn)begin
        if(rstn == 1'b0)
            cal_gj2 <= 2'b11;
        else if(clear)
            cal_gj2 <= 2'b11;
        else if(~ce)
            cal_gj2 <= cal_gj2;
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
    /*****************************************第二拍*************************************************/
    //第三级
    //缓冲打拍对齐,wj+2->wj+1
    always@(posedge clk or negedge rstn)begin
        if(rstn == 1'b0)
            cal_wj1 <= 1'b0;
        else if(clear)
            cal_wj1 <= 1'b0;
        else if(~ce)
            cal_wj1 <= cal_wj1;
        else
            cal_wj1 <= cal_wj2;
            
    end
 
    //得到z数据
    assign cal_zj1[0] = ~cal_tj1;
    assign cal_zj1[1] = cal_wj1;

   
    //输出
    assign dataOutArray = cal_zj1;

endmodule