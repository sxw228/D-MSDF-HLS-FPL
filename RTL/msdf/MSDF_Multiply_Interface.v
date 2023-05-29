`timescale 1ns / 1ps
module MSDF_Multiply_Interface
#(
	parameter RADIX_MODE	= 8'd1,				
	parameter ENCODING_MODE	= "signed-digit",	
	parameter ACCURATE_MAX	= 8'd64,			
	parameter DATA_WIDTH	= 8'd2,				
	parameter POINT_WIDTH	= 8'd8				
)
(
	input i_clk,
	input i_rstn,
	input i_mbus_wen,							
	input [DATA_WIDTH - 1:0]i_mbus_wdata_x,		
	input [DATA_WIDTH - 1:0]i_mbus_wdata_y,		
	input i_mbus_wpoint,						
	input i_mbus_wvalid,						
	input i_mbus_wlast,							
	output o_mbus_wstop,						
	output o_mbus_wclr,							
	output [DATA_WIDTH - 1:0]o_mbus_rdata,		
	output o_mbus_rpoint,						
	output o_mbus_rvalid,						
	output o_mbus_rlast,						
	input i_mbus_rstop,							
	input i_mbus_rclr							
);
	generate if(RADIX_MODE == 8'd1)begin:gen_radix2_multiply
		MSDF_Multiply_Radix2_Interface #(
			.ENCODING_MODE(ENCODING_MODE),				
			.ACCURATE_MAX(ACCURATE_MAX),				
			.POINT_WIDTH(POINT_WIDTH)					
		)MSDF_Multiply_Radix2_Interface_Inst(
			.i_clk(i_clk),
			.i_rstn(i_rstn),
			.i_mbus_wen(i_mbus_wen),					
			.i_mbus_wdata_x(i_mbus_wdata_x),			
			.i_mbus_wdata_y(i_mbus_wdata_y),			
			.i_mbus_wpoint(i_mbus_wpoint),				
			.i_mbus_wvalid(i_mbus_wvalid),				
			.i_mbus_wlast(i_mbus_wlast),				
			.o_mbus_wstop(o_mbus_wstop),				
			.o_mbus_wclr(o_mbus_wclr),					
			.o_mbus_rdata(o_mbus_rdata),				
			.o_mbus_rpoint(o_mbus_rpoint),				
			.o_mbus_rvalid(o_mbus_rvalid),				
			.o_mbus_rlast(o_mbus_rlast),				
			.i_mbus_rstop(i_mbus_rstop),				
			.i_mbus_rclr(i_mbus_rclr)					
		);
	end
	else begin:gen_unkown
		assign o_mbus_wstop = 0;
		assign o_mbus_wclr = 0;
		assign o_mbus_rdata = 0;
		assign o_mbus_rpoint = 0;
		assign o_mbus_rvalid = 0;
		assign o_mbus_rlast = 0;
	end endgenerate
endmodule
module MSDF_Multiply_Radix2_Interface
#(
	parameter ENCODING_MODE	= "signed-digit",	
	parameter ACCURATE_MAX	= 8'd64,			
	parameter POINT_WIDTH	= 8'd8				
)
(
	input i_clk,
	input i_rstn,
	input i_mbus_wen,							
	input [1:0]i_mbus_wdata_x,					
	input [1:0]i_mbus_wdata_y,					
	input i_mbus_wpoint,						
	input i_mbus_wvalid,						
	input i_mbus_wlast,							
	output o_mbus_wstop,						
	output o_mbus_wclr,							
	output [1:0]o_mbus_rdata,					
	output o_mbus_rpoint,						
	output o_mbus_rvalid,						
	output o_mbus_rlast,						
	input i_mbus_rstop,							
	input i_mbus_rclr							
);
	localparam UPPER_WIDTH	= 8'd5;
	wire write_enable;
	wire [1:0]encode_minus1;
	wire [1:0]encode_plus1;
	wire [1:0]encode_product;
	wire ca_wen_x,ca_wen_y;
	wire ca_wvalid_x,ca_wvalid_y;
	wire ca_wlast_x,ca_wlast_y;
	wire [ACCURATE_MAX * 2 - 1:0]ca_data_x;
	wire [ACCURATE_MAX * 2 - 1:0]ca_data_y;
	wire [1:0]sel_xj3;
	wire [1:0]sel_yj3;
	wire [1:0]sel_xj4;
	wire [1:0]sel_yj4;
	reg [ACCURATE_MAX * 2 - 1:0]sel_data_x = 0;
	reg [ACCURATE_MAX * 2 - 1:0]sel_data_y = 0;
	wire sel_wen_xy;
	wire sel_wvalid_xy;
	wire sel_delay_wen_xy;
	wire sel_delay_wvalid_xy;
	wire [ACCURATE_MAX * 2 - 1:0]sel_sum_xy;
	wire [1:0]sel_cout_xy;
	wire sel_rvalid_xy;
	wire sel_wen_v;
	wire sel_wvalid_v;
	wire sel_delay_wen_v;
	wire sel_delay_wvalid_v;
	reg [ACCURATE_MAX * 2 - 1:0]sel_data_w = 0;
	wire [ACCURATE_MAX * 2 - 1:0]sel_sum_v;
	wire [1:0]sel_cout_v;
	wire sel_rvalid_v;
	wire adder_wen_v;
	wire adder_wvalid_v;
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
	wire mbus_wlast_i;
	wire mbus_rstop_i;
	wire mbus_rclr_i;
	assign write_enable = i_mbus_wen & i_mbus_wvalid & ~mbus_rstop_i;
	generate if(ENCODING_MODE == "signed-digit")begin:gen_signed_digit_encode
		assign encode_minus1 = 2'b01;
		assign encode_plus1 = 2'b10;
		assign encode_product = {~v_selm[UPPER_WIDTH - 1],v_selm[UPPER_WIDTH - 1]};
	end
	else if(ENCODING_MODE == "borrow-save")begin:gen_borrow_save_encode
		assign encode_minus1 = 2'b11;
		assign encode_plus1 = 2'b01;
		assign encode_product = {v_selm[UPPER_WIDTH - 1],1'b1};
	end
	else begin:gen_self_define_encode
		assign encode_minus1 = 0;
		assign encode_plus1 = 0;
		assign encode_product = 0;
	end endgenerate
	assign o_mbus_wstop = i_mbus_rstop;
	assign o_mbus_wclr = mbus_rclr_i;
	assign o_mbus_rdata = p_data;
	assign o_mbus_rpoint = 0;
	D_FF_new #(1,9,0)D_FF_new1_Inst_Rvalid(i_clk,i_rstn,1'b0,1'b1,i_mbus_wvalid,o_mbus_rvalid);
	D_FF_new #(1,9,0)D_FF_new1_Inst_Rlast(i_clk,i_rstn,1'b0,1'b1,i_mbus_wlast,o_mbus_rlast);
	assign ca_wen_y = i_mbus_wen;
	assign ca_wvalid_y = i_mbus_wvalid;
	assign ca_wlast_y = i_mbus_wlast;
	D_FF_new #(1,1,0)D_FF_new1_Inst_WenX(i_clk,i_rstn,1'b0,1'b1,i_mbus_wen,ca_wen_x);
	D_FF_new #(1,1,0)D_FF_new1_Inst_WvalidX(i_clk,i_rstn,1'b0,1'b1,i_mbus_wvalid,ca_wvalid_x);
	D_FF_new #(1,1,0)D_FF_new1_Inst_WlastX(i_clk,i_rstn,1'b0,1'b1,i_mbus_wlast,ca_wlast_x);
	MSDF_Conversion_Interface #(
		.RADIX_MODE(8'd1),							
		.ENCODING_MODE(ENCODING_MODE),				
		.CONVERT_MODE("Append"),					
		.CA_REG_ENABLE(1'd1),						
		.ACCURATE_MAX(ACCURATE_MAX),				
		.DATA_WIDTH(8'd2),							
		.POINT_WIDTH(POINT_WIDTH)					
	)MSDF_Conversion_Interface_Inst_X(
		.i_clk(i_clk),
		.i_rstn(i_rstn),
		.i_mbus_wen(ca_wen_x),						
		.i_mbus_wdata(sel_xj4),						
		.i_mbus_wpoint(1'b0),						
		.i_mbus_wvalid(ca_wvalid_x),				
		.i_mbus_wlast(ca_wlast_x),					
		.o_mbus_wstop(),							
		.o_mbus_wclr(),								
		.o_mbus_rdata(ca_data_x),					
		.o_mbus_rpoint(),							
		.o_mbus_rvalid(),							
		.i_mbus_rstop(i_mbus_rstop),				
		.i_mbus_rclr(i_mbus_rclr)					
	);
	MSDF_Conversion_Interface #(
		.RADIX_MODE(8'd1),							
		.ENCODING_MODE(ENCODING_MODE),				
		.CONVERT_MODE("Append"),					
		.CA_REG_ENABLE(1'd1),						
		.ACCURATE_MAX(ACCURATE_MAX),				
		.DATA_WIDTH(8'd2),							
		.POINT_WIDTH(POINT_WIDTH)					
	)MSDF_Conversion_Interface_Inst_Y(
		.i_clk(i_clk),
		.i_rstn(i_rstn),
		.i_mbus_wen(ca_wen_y),						
		.i_mbus_wdata(sel_yj3),						
		.i_mbus_wpoint(1'b0),						
		.i_mbus_wvalid(ca_wvalid_y),				
		.i_mbus_wlast(ca_wlast_y),					
		.o_mbus_wstop(),							
		.o_mbus_wclr(),								
		.o_mbus_rdata(ca_data_y),					
		.o_mbus_rpoint(),							
		.o_mbus_rvalid(),							
		.i_mbus_rstop(i_mbus_rstop),				
		.i_mbus_rclr(i_mbus_rclr)					
	);
	assign sel_xj3 = i_mbus_wdata_x;
	assign sel_yj3 = i_mbus_wdata_y;
	D_FF_new #(2,1,0)D_FF_new2_Inst_WdataX(i_clk,i_rstn,mbus_wlast_i,write_enable,sel_xj3,sel_xj4);
	D_FF_new #(2,1,0)D_FF_new2_Inst_WdataY(i_clk,i_rstn,mbus_wlast_i,write_enable,sel_yj3,sel_yj4);
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)sel_data_x <= {(ACCURATE_MAX * 2){1'b0}};
		else if(sel_yj4 == encode_minus1)sel_data_x <= ~ca_data_x;
		else if(sel_yj4 == encode_plus1)sel_data_x <= ca_data_x;
		else sel_data_x <= {(ACCURATE_MAX * 2){1'b0}};
	end
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)sel_data_y <= {(ACCURATE_MAX * 2){1'b0}};
		else if(write_enable == 1'b0)sel_data_y <= sel_data_y;
		else if(sel_xj4 == encode_minus1)sel_data_y <= ~ca_data_y;
		else if(sel_xj4 == encode_plus1)sel_data_y <= ca_data_y;
		else sel_data_y <= {(ACCURATE_MAX * 2){1'b0}};
	end
	assign sel_wen_xy = ca_wen_x | sel_delay_wen_xy;
	assign sel_wvalid_xy = ca_wvalid_x | sel_delay_wvalid_xy;
	assign sel_wen_v = sel_delay_wen_xy | sel_delay_wen_v;
	assign sel_wvalid_v = sel_delay_wvalid_xy | sel_delay_wvalid_v;
	D_FF_new #(1,1,0)D_FF_new1_Inst_SelWenDelay_V(i_clk,i_rstn,1'b0,1'b1,ca_wen_x,sel_delay_wen_xy);
	D_FF_new #(1,1,0)D_FF_new1_Inst_SelWvalidDelay_V(i_clk,i_rstn,1'b0,1'b1,ca_wvalid_x,sel_delay_wvalid_xy);
	D_FF_new #(1,5,0)D_FF_new1_Inst_SelWen_V(i_clk,i_rstn,1'b0,1'b1,sel_delay_wen_xy,sel_delay_wen_v);
	D_FF_new #(1,5,0)D_FF_new1_Inst_SelWvalid_V(i_clk,i_rstn,1'b0,1'b1,sel_delay_wvalid_xy,sel_delay_wvalid_v);
	MSDF_Adder_Interface #(
		.RADIX_MODE(8'd1),							
		.ENCODING_MODE(ENCODING_MODE),				
		.ADDER_MODE("Parallel"),					
		.ACCURATE_MAX(ACCURATE_MAX),				
		.DATA_WIDTH(8'd2)							
	)MSDF_Adder_Interface_Inst_XY(
		.i_clk(i_clk),
		.i_rstn(i_rstn),
		.i_mbus_wen(sel_wen_xy),					
		.i_mbus_wpdata_x(sel_data_x),				
		.i_mbus_wpdata_y(sel_data_y),				
		.i_mbus_wpcin(2'b00),						
		.i_mbus_wvalid(sel_wvalid_xy),				
		.o_mbus_wstop(),							
		.o_mbus_wclr(),								
		.o_mbus_rpdata(sel_sum_xy),					
		.o_mbus_rpcout(sel_cout_xy),				
		.o_mbus_rvalid(sel_rvalid_xy),				
		.i_mbus_rstop(i_mbus_rstop),				
		.i_mbus_rclr(i_mbus_rclr)					
	);
	MSDF_Adder_Interface #(
		.RADIX_MODE(8'd1),							
		.ENCODING_MODE(ENCODING_MODE),				
		.ADDER_MODE("Parallel"),					
		.ACCURATE_MAX(ACCURATE_MAX),				
		.DATA_WIDTH(8'd2)							
	)MSDF_Adder_Interface_Inst_V(
		.i_clk(i_clk),
		.i_rstn(i_rstn),
		.i_mbus_wen(sel_wen_v),						
		.i_mbus_wpdata_x(sel_sum_xy),				
		.i_mbus_wpdata_y(sel_data_w),				
		.i_mbus_wpcin(2'b00),						
		.i_mbus_wvalid(sel_wvalid_v),				
		.o_mbus_wstop(),							
		.o_mbus_wclr(),								
		.o_mbus_rpdata(sel_sum_v),					
		.o_mbus_rpcout(sel_cout_v),					
		.o_mbus_rvalid(sel_rvalid_v),				
		.i_mbus_rstop(i_mbus_rstop),				
		.i_mbus_rclr(i_mbus_rclr)					
	);
	always@(*)begin
		if(i_rstn == 1'b0)sel_data_w <= {(ACCURATE_MAX * 2){1'b0}};
		else if(sel_rvalid_v == 1'b1)sel_data_w <= {sel_sum_v[(ACCURATE_MAX - 1) * 2 - 1:0],2'b00};
		else sel_data_w <= sel_data_w;
	end
	MSDF_Adder_Interface #(
		.RADIX_MODE(8'd1),							
		.ENCODING_MODE(ENCODING_MODE),				
		.ADDER_MODE("Parallel"),					
		.ACCURATE_MAX(UPPER_WIDTH),					
		.DATA_WIDTH(8'd2)							
	)MSDF_Adder_Interface_Inst_Sum(
		.i_clk(i_clk),
		.i_rstn(i_rstn),
		.i_mbus_wen(adder_wen_v),					
		.i_mbus_wpdata_x(adder_data_xy),			
		.i_mbus_wpdata_y(adder_data_w),				
		.i_mbus_wpcin(sel_cout_v),					
		.i_mbus_wvalid(adder_wvalid_v),				
		.o_mbus_wstop(),							
		.o_mbus_wclr(),								
		.o_mbus_rpdata(adder_sum_v),				
		.o_mbus_rpcout(adder_cout_v),				
		.o_mbus_rvalid(adder_rvalid_v),			
		.i_mbus_rstop(i_mbus_rstop),				
		.i_mbus_rclr(i_mbus_rclr)					
	);
	assign adder_data_xy[UPPER_WIDTH * 2 - 1:2] = 0;
	assign adder_data_xy[1:0] = sel_cout_xy;
	D_FF_new #(1,1,0)D_FF_new1_Inst_AdderWen_V(i_clk,i_rstn,1'b0,1'b1,sel_wen_v,adder_wen_v);
	D_FF_new #(1,1,0)D_FF_new1_Inst_AdderWvalid_V(i_clk,i_rstn,1'b0,1'b1,sel_wvalid_v,adder_wvalid_v);
	D_FF_new #(2,1,0)D_FF_new1_Inst_AdderWshift(i_clk,i_rstn,1'b0,1'b1,sel_sum_v[ACCURATE_MAX * 2 - 1:(ACCURATE_MAX - 1) * 2],shift_data);
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
	D_FF_new #(1,1,0)D_FF_new1_Inst_CMP(i_clk,i_rstn,1'b0,1'b1,lsd_cmp[0],lsd_cmp[1]);
	always@(*)begin
		if(i_rstn == 1'b0)p_data <= 2'b00;
		else if(v_selm[UPPER_WIDTH - 1:UPPER_WIDTH - 3] == 3'b000)p_data <= 2'b00;
		else if(v_selm[UPPER_WIDTH - 1:UPPER_WIDTH - 3] == 3'b111)p_data <= 2'b00;
		else p_data <= encode_product;
	end
	D_FF_new #(1,1,1)D_FF_new1_Inst_Wlast(i_clk,i_rstn,i_mbus_rclr | mbus_rclr_i,write_enable,i_mbus_wlast,mbus_wlast_i);
	D_FF_new #(1,1,0)D_FF_new1_Inst_Rclr(i_clk,i_rstn,1'b0,1'b1,i_mbus_rclr,mbus_rclr_i);
	D_FF_new #(1,1,0)D_FF_new1_Inst_Rstop(i_clk,i_rstn,1'b0,1'b1,i_mbus_rstop,mbus_rstop_i);
endmodule