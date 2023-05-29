`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/05 22:33:39
// Design Name: 
// Module Name: msdf_mult_op
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


module msdf_mult_op
	#(
		parameter TARGET_PRECISION = 32'd16
	)(
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
	localparam INITIAL_DELAY = 4'd9;
    

	//------------------内部信号----------------//
	wire join_valid;				//输入侧两操作数同时有效
	wire rstn = ~rst;

    wire msdf_ready;                 //msdf单元的ready输出
    wire [1:0]msdf_dout;			//运算单元的数据输出
    reg msdf_valid;                 //msdf单元的valid输出
    wire msdf_last;                  //msdf单元的last输出

    wire oehb_ready;			    //oehb的ready输出
    
    //控制信号
    reg last_flag;                  //指示是否收到输入的last
	reg ce;							//运算单元的ce输入
    wire clear;						//运算单元的clr输入
	
    
    /* 处理读写计数器 */
    reg [31:0]wr_cnt;
    reg [31:0]rd_cnt;
    
	/* 写入本模块的计数器 */
	always @(posedge clk) begin
        if(~rstn)begin
            wr_cnt <= 'd0;
        end
        else if(clear)begin
            wr_cnt <= 'd0;
        end
        else if(join_valid & msdf_ready)begin //有效输入
            wr_cnt <= wr_cnt+1;
        end
    end
    
	/* 从本模块读出的计数器 */
	always @(posedge clk ) begin
        if(~rstn)begin
            rd_cnt <= 'd0;
        end
        else if(clear)begin
            rd_cnt <= 'd0;
        end
        else if(msdf_valid & oehb_ready)begin //有效输出
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
        else if(join_valid&msdf_ready&dataInArray_0[2])begin //有效输入
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
        else if(wr_cnt<=INITIAL_DELAY-2)begin //初始阶段
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
    assign clear = (~rstn)|(rd_cnt==TARGET_PRECISION-1);
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
        .nReady(msdf_ready)
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




    msdf_mult_pipeline msdf_mult_pipeline_inst(
        .clk(clk),
        .rstn(~clear),
        .ce(ce),
        .clear(clear),
        .dataInArray_0(dataInArray_0[1:0]),					//操作数1
        .dataInArray_1(dataInArray_1[1:0]),					//操作数2
        .dataOutArray(msdf_dout)			//读数据
    );
endmodule

module msdf_mult_pipeline(
    input clk,
    input rstn,
    //控制通道
    input ce,
    input clear,
    //写通道
	input [1:0]dataInArray_0,					//操作数1
	input [1:0]dataInArray_1,					//操作数2
    //读通道
	output [1:0]dataOutArray					//读数据
);
    //------------------参数数据----------------//
	localparam UPPER_WIDTH	= 8'd5;
    localparam ENCODING_MODE = "signed-digit";
    localparam ACCURATE_MAX = 16'd256;
	localparam POINT_WIDTH = 8;
    //------------------复位信号----------------//
    wire rst = ~rstn;

	//------------------编码数据----------------//
	wire [1:0]encode_minus1;
	wire [1:0]encode_plus1;
	wire [1:0]encode_product;
	//------------------计算数据----------------//
	//CA-Reg数据
	wire ca_wen_x,ca_wen_y;
	wire [ACCURATE_MAX * 2 - 1:0]ca_data_x;
	wire [ACCURATE_MAX * 2 - 1:0]ca_data_y;
    //Selector数据
	wire [1:0]sel_xj3;
	wire [1:0]sel_yj3;
	wire [1:0]sel_xj4;
	wire [1:0]sel_yj4;
	reg [ACCURATE_MAX * 2 - 1:0]sel_data_x = 0;
	reg [ACCURATE_MAX * 2 - 1:0]sel_data_y = 0;

	wire sel_wen_xy;
	wire [ACCURATE_MAX * 2 - 1:0]sel_sum_xy;
	wire [1:0]sel_cout_xy;
	wire sel_rvalid_xy;
	wire sel_wen_v;
	reg [ACCURATE_MAX * 2 - 1:0]sel_data_w = 0;
	wire [ACCURATE_MAX * 2 - 1:0]sel_sum_v;
	wire [1:0]sel_cout_v;
	wire sel_rvalid_v;
	wire adder_wen_v;
	wire [UPPER_WIDTH * 2 - 1:0]adder_data_xy;
	reg [UPPER_WIDTH * 2 - 1:0]adder_data_w = 0;
	wire [UPPER_WIDTH * 2 - 1:0]adder_sum_v;
	wire [1:0]adder_cout_v;
	wire adder_rvalid_v;
	wire [1:0]shift_data;						
	wire [UPPER_WIDTH - 1:0]v_selm;
	wire [UPPER_WIDTH - 1:0]v_plus;				
	wire [UPPER_WIDTH - 1:0]v_minus;
	wire [ACCURATE_MAX - 1:0]t_plus;
	wire [ACCURATE_MAX - 1:0]t_minus;
	wire [1:0]lsd_cmp;							
	reg [1:0]p_data = 0;			

    
	
	
	//sign digit编码
    assign encode_minus1 = 2'b01;
    assign encode_plus1 = 2'b10;
    assign encode_product = {~v_selm[UPPER_WIDTH - 1],v_selm[UPPER_WIDTH - 1]};

	//功能控制有关的
	reg [7:0] ce_cnt;
	always @(posedge clk ) begin
		if(~rstn)begin
			ce_cnt <= 'd0;
		end
		else if(clear)begin
			ce_cnt <= 'd0;
		end
		else if(ce)begin
			ce_cnt <= ce_cnt+1;
		end
	end

	assign dataOutArray = p_data;
	assign sel_xj3 = dataInArray_0;
	assign sel_yj3 = dataInArray_1;
	D_FF #(2,0)D_FF2_Inst2(clk,rstn,clear,1'b0,ce,sel_xj3,sel_xj4);
	D_FF #(2,0)D_FF2_Inst3(clk,rstn,clear,1'b0,ce,sel_yj3,sel_yj4);

	assign ca_wen_y = ce;
	assign ca_wen_x = (ce_cnt>'d0)&ce;
	assign sel_wen_xy = (ce_cnt>'d0)&ce;
	assign sel_wen_v = (ce_cnt>'d1)&ce;
	assign adder_wen_v = (ce_cnt>'d2)&ce;


	/* 输入为第0级 */
	MSDF_Conversion_Interface #(
		.RADIX_MODE(8'd1),							
		.ENCODING_MODE(ENCODING_MODE),				
		.CONVERT_MODE("Append"),					
		.CA_REG_ENABLE(1'd1),						
		.ACCURATE_MAX(ACCURATE_MAX),				
		.DATA_WIDTH(8'd2),							
		.POINT_WIDTH(POINT_WIDTH)					
	)MSDF_Conversion_Interface_Inst_Y(
		.i_clk(clk),
		.i_rstn(~clear),
		.i_mbus_wen(ca_wen_y),						
		.i_mbus_wdata(sel_yj3),						
		.i_mbus_wpoint(1'b0),						
		.i_mbus_wvalid(ca_wen_y),				
		.i_mbus_wlast(1'b0),					
		.o_mbus_wstop(),							
		.o_mbus_wclr(),								
		.o_mbus_rdata(ca_data_y),					
		.o_mbus_rpoint(),							
		.o_mbus_rvalid(),							
		.i_mbus_rstop(1'b0),				
		.i_mbus_rclr(1'b0)					
	);

	/* 输入为第1级 */
	MSDF_Conversion_Interface #(
		.RADIX_MODE(8'd1),							
		.ENCODING_MODE(ENCODING_MODE),				
		.CONVERT_MODE("Append"),					
		.CA_REG_ENABLE(1'd1),						
		.ACCURATE_MAX(ACCURATE_MAX),				
		.DATA_WIDTH(8'd2),							
		.POINT_WIDTH(POINT_WIDTH)					
	)MSDF_Conversion_Interface_Inst_X(
		.i_clk(clk),
		.i_rstn(~clear),
		.i_mbus_wen(ca_wen_x),						
		.i_mbus_wdata(sel_xj4),						
		.i_mbus_wpoint(1'b0),						
		.i_mbus_wvalid(ca_wen_x),				
		.i_mbus_wlast(1'b0),					
		.o_mbus_wstop(),							
		.o_mbus_wclr(),								
		.o_mbus_rdata(ca_data_x),					
		.o_mbus_rpoint(),							
		.o_mbus_rvalid(),							
		.i_mbus_rstop(1'b0),				
		.i_mbus_rclr(1'b0)					
	);

	// sxw_generate_CA_reg_v2#(
    // .unrolling(72),
    // .ADDR_WIDTH(8)
	// ) sxw_CA_inst(
	// .enable(ca_wen_y),
	// .refresh(0),
	// .rst(~rstn),
	// .clk(clk),
	// .x_in(sel_xj3),
	// .y_in(sel_yj3),
	// .x_plus_delay(),
	// .x_minus_delay(),
	// .y_plus_rd(),
	// .y_minus_rd(),
	// .accum(0)
	// );


	/* 第一级 */
	always@(posedge clk)begin
		if(rstn == 1'b0)sel_data_x <= {(ACCURATE_MAX * 2){1'b0}};
		else if(~ce)sel_data_x <= sel_data_x;
		else if(sel_yj4 == encode_minus1)sel_data_x <= ~ca_data_x;
		else if(sel_yj4 == encode_plus1)sel_data_x <= ca_data_x;
		else sel_data_x <= {(ACCURATE_MAX * 2){1'b0}};
	end
	always@(posedge clk)begin
		if(rstn == 1'b0)sel_data_y <= {(ACCURATE_MAX * 2){1'b0}};
		else if(~ce)sel_data_y <= sel_data_y;
		else if(sel_xj4 == encode_minus1)sel_data_y <= ~ca_data_y;
		else if(sel_xj4 == encode_plus1)sel_data_y <= ca_data_y;
		else sel_data_y <= {(ACCURATE_MAX * 2){1'b0}};
	end

	/* 第一级 */
	MSDF_Adder_Interface #(
		.RADIX_MODE(8'd1),							
		.ENCODING_MODE(ENCODING_MODE),				
		.ADDER_MODE("Parallel"),					
		.ACCURATE_MAX(ACCURATE_MAX),				
		.DATA_WIDTH(8'd2)							
	)MSDF_Adder_Interface_Inst_XY(
		.i_clk(clk),
		.i_rstn(~clear),
		.i_mbus_wen(sel_wen_xy),					
		.i_mbus_wpdata_x(sel_data_x),				
		.i_mbus_wpdata_y(sel_data_y),				
		.i_mbus_wpcin(2'b00),						
		.i_mbus_wvalid(sel_wen_xy),				
		.o_mbus_wstop(),							
		.o_mbus_wclr(),								
		.o_mbus_rpdata(sel_sum_xy),					
		.o_mbus_rpcout(sel_cout_xy),				
		.o_mbus_rvalid(sel_rvalid_xy),				
		.i_mbus_rstop(1'b0),				
		.i_mbus_rclr(1'b0)					
	);

	/* 第二级 */
	MSDF_Adder_Interface #(
		.RADIX_MODE(8'd1),							
		.ENCODING_MODE(ENCODING_MODE),				
		.ADDER_MODE("Parallel"),					
		.ACCURATE_MAX(ACCURATE_MAX),				
		.DATA_WIDTH(8'd2)							
	)MSDF_Adder_Interface_Inst_V(
		.i_clk(clk),
		.i_rstn(~clear),
		.i_mbus_wen(sel_wen_v),						
		.i_mbus_wpdata_x(sel_sum_xy),				
		.i_mbus_wpdata_y(sel_data_w),				
		.i_mbus_wpcin(2'b00),						
		.i_mbus_wvalid(sel_wen_v),				
		.o_mbus_wstop(),							
		.o_mbus_wclr(),								
		.o_mbus_rpdata(sel_sum_v),					
		.o_mbus_rpcout(sel_cout_v),					
		.o_mbus_rvalid(sel_rvalid_v),				
		.i_mbus_rstop(1'b0),				
		.i_mbus_rclr(1'b0)					
	);
	always@(*)begin
		if(rstn == 1'b0)sel_data_w <= {(ACCURATE_MAX * 2){1'b0}};
		else if(sel_rvalid_v == 1'b1)sel_data_w <= {sel_sum_v[(ACCURATE_MAX - 1) * 2 - 1:0],2'b00};
		else sel_data_w <= sel_data_w;
	end

	/* 第三级 */
	MSDF_Adder_Interface #(
		.RADIX_MODE(8'd1),							
		.ENCODING_MODE(ENCODING_MODE),				
		.ADDER_MODE("Parallel"),					
		.ACCURATE_MAX(UPPER_WIDTH),					
		.DATA_WIDTH(8'd2)							
	)MSDF_Adder_Interface_Inst_Sum(
		.i_clk(clk),
		.i_rstn(rstn),
		.i_mbus_wen(adder_wen_v),					
		.i_mbus_wpdata_x(adder_data_xy),			
		.i_mbus_wpdata_y(adder_data_w),				
		.i_mbus_wpcin(sel_cout_v),					
		.i_mbus_wvalid(adder_wen_v),				
		.o_mbus_wstop(),							
		.o_mbus_wclr(),								
		.o_mbus_rpdata(adder_sum_v),				
		.o_mbus_rpcout(adder_cout_v),				
		.o_mbus_rvalid(adder_rvalid_v),			
		.i_mbus_rstop(1'b0),				
		.i_mbus_rclr(1'b0)					
	);
	assign adder_data_xy[UPPER_WIDTH * 2 - 1:2] = 0;
	assign adder_data_xy[1:0] = sel_cout_xy;

	D_FF_new #(2,1,0)D_FF_new1_Inst_AdderWshift(clk,rstn,clear,1'b1,sel_sum_v[ACCURATE_MAX * 2 - 1:(ACCURATE_MAX - 1) * 2],shift_data);
	always@(*)begin
		adder_data_w[(UPPER_WIDTH - 1) * 2 - 1:0] <= {adder_sum_v[(UPPER_WIDTH - 2) * 2 - 1:0],shift_data};
	end
	always@(*)begin
		if(adder_sum_v[(UPPER_WIDTH - 1) * 2 - 1] ^ adder_sum_v[(UPPER_WIDTH - 2) * 2] ^ p_data[1] ^ p_data[0])begin
			adder_data_w[UPPER_WIDTH * 2 - 1:(UPPER_WIDTH - 1) * 2] <= {adder_sum_v[(UPPER_WIDTH - 1) * 2 - 1] ^ p_data[1],adder_sum_v[(UPPER_WIDTH - 2) * 2] ^ p_data[0]};
		end else begin
			adder_data_w[UPPER_WIDTH * 2 - 1:(UPPER_WIDTH - 1) * 2] <= 0;
		end
	end
	generate begin
		genvar k;
		for(k = 0;k < UPPER_WIDTH;k = k + 1)begin
			assign v_plus[k] = adder_sum_v[k * 2 + 1];
			assign v_minus[k] = adder_sum_v[k * 2 + 0];
		end
		for(k = 0;k < ACCURATE_MAX;k = k + 1)begin
			assign t_plus[k] = sel_sum_v[k * 2 + 1];
			assign t_minus[k] = sel_sum_v[k * 2 + 0];
		end
	end endgenerate
	assign v_selm = v_plus - v_minus - lsd_cmp[1];
	assign lsd_cmp[0] = t_plus < t_minus;
	D_FF_new #(1,1,0)D_FF_new1_Inst_CMP(clk,rstn,clear,1'b1,lsd_cmp[0],lsd_cmp[1]);
	always@(*)begin
		if(rstn == 1'b0)p_data <= 2'b00;
		else if(v_selm[UPPER_WIDTH - 1:UPPER_WIDTH - 3] == 3'b000)p_data <= 2'b00;
		else if(v_selm[UPPER_WIDTH - 1:UPPER_WIDTH - 3] == 3'b111)p_data <= 2'b00;
		else p_data <= encode_product;
	end


endmodule