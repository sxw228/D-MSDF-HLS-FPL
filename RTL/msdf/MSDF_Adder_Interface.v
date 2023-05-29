`timescale 1ns / 1ps
module MSDF_Adder_Interface
#(
	parameter RADIX_MODE	 = 8'd1,			
	parameter ENCODING_MODE	 = "signed-digit",	
	parameter ADDER_MODE	 = "Default",		
	parameter ACCURATE_MAX	 = 8'd64,			
	parameter DATA_WIDTH	 = 8'd2,			
	parameter PARALLEL_WIDTH = ACCURATE_MAX * DATA_WIDTH	
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
	input i_mbus_rclr,							
	input [PARALLEL_WIDTH - 1:0]i_mbus_wpdata_x,
	input [PARALLEL_WIDTH - 1:0]i_mbus_wpdata_y,
	input [DATA_WIDTH - 1:0]i_mbus_wpcin,		
	output [PARALLEL_WIDTH - 1:0]o_mbus_rpdata,	
	output [DATA_WIDTH - 1:0]o_mbus_rpcout		
);
	generate if(RADIX_MODE == 8'd1)begin:gen_radix2_adder
		MSDF_Adder_Radix2_Interface #(
			.ENCODING_MODE(ENCODING_MODE),				
			.ADDER_MODE(ADDER_MODE),					
			.ACCURATE_MAX(ACCURATE_MAX),				
			.PARALLEL_WIDTH(PARALLEL_WIDTH)				
		)MSDF_Adder_Radix2_Interface_Inst(
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
			.i_mbus_rclr(i_mbus_rclr),					
			.i_mbus_wpdata_x(i_mbus_wpdata_x),			
			.i_mbus_wpdata_y(i_mbus_wpdata_y),			
			.i_mbus_wpcin(i_mbus_wpcin),				
			.o_mbus_rpdata(o_mbus_rpdata),				
			.o_mbus_rpcout(o_mbus_rpcout)				
		);
	end
	else begin:gen_unkown
		assign o_mbus_wstop = 0;
		assign o_mbus_wclr = 0;
		assign o_mbus_rdata = 0;
		assign o_mbus_rpoint = 0;
		assign o_mbus_rvalid = 0;
		assign o_mbus_rlast = 0;
		assign o_mbus_rpdata = 0;
		assign o_mbus_rpcout = 0;
	end endgenerate
endmodule
module MSDF_Adder_Radix2_Interface
#(
	parameter ENCODING_MODE	= "signed-digit",	
	parameter ADDER_MODE	 = "Default",		
	parameter ACCURATE_MAX	 = 8'd64,			
	parameter PARALLEL_WIDTH = ACCURATE_MAX * 2	
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
	input i_mbus_rclr,							
	input [PARALLEL_WIDTH - 1:0]i_mbus_wpdata_x,
	input [PARALLEL_WIDTH - 1:0]i_mbus_wpdata_y,
	input [1:0]i_mbus_wpcin,					
	output [PARALLEL_WIDTH - 1:0]o_mbus_rpdata,	
	output [1:0]o_mbus_rpcout					
);
	wire write_enable;
	wire [1:0]input_xj3;
	wire [1:0]input_yj3;
	wire [1:0]input_serialx[2:0];
	wire [1:0]input_serialy[2:0];
	wire cal_hj2;
	wire [1:0]cal_gj3;
	reg [1:0]cal_gj2 = 0;
	wire [1:0]cal_serialg[2:0];
	wire [3:0]cal_serialh;
	wire cal_tj1;
	wire cal_wj2;
	wire cal_wj1;
	wire [2:0]cal_serialt;
	wire [2:0]cal_serialw;
	wire [1:0]cal_zj1;
	reg mbus_wvalid_i = 0;
	wire mbus_wlast_i;
	wire mbus_rclr_i;
	reg [1:0]mbus_rdata_o = 0;
	reg mbus_rvalid_o = 0;
	reg mbus_rlast_o = 0;
	assign input_xj3 = {i_mbus_wdata_x[1],~i_mbus_wdata_x[0]};
	assign input_yj3 = {i_mbus_wdata_y[1],~i_mbus_wdata_y[0]};
	assign write_enable = i_mbus_wen & i_mbus_wvalid & ~i_mbus_rstop;
	generate if(ADDER_MODE == "Default")begin:gen_serial_radix2_adder
		assign o_mbus_wstop = i_mbus_rstop;
		assign o_mbus_wclr = mbus_rclr_i;
		assign o_mbus_rdata = mbus_rdata_o;
		assign o_mbus_rvalid = mbus_rvalid_o;
		assign o_mbus_rlast = mbus_rlast_o;
		assign o_mbus_rpdata = 0;
		assign o_mbus_rpcout = 0; 
		D_FF_new #(1,3,0)D_FF_new_Inst_Rpoint(i_clk,i_rstn,mbus_wlast_i | i_mbus_rclr,write_enable,i_mbus_wpoint,o_mbus_rpoint);
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)mbus_rvalid_o <= 1'b0;
			else if(i_mbus_rclr | mbus_rclr_i)mbus_rvalid_o <= 1'b0;
			else if(i_mbus_rstop == 1'b1)mbus_rvalid_o <= 1'b0;
			else mbus_rvalid_o <= mbus_wvalid_i;
		end
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)mbus_rlast_o <= 1'b0;
			else if(i_mbus_rclr | mbus_rclr_i)mbus_rlast_o <= 1'b0;
			else if(i_mbus_rstop == 1'b1)mbus_rlast_o <= 1'b0;
			else mbus_rlast_o <= mbus_wlast_i & mbus_wvalid_i;
		end
		assign cal_gj3[0] = input_yj3[0];
		Adder_Interface #(
			.DATA_WIDTH_4Bit(8'd1),				
			.ADDER_MODE("FA"),					
			.DATA_WIDTH(8'd1)					
		)Adder_Interface_Inst_FA0(
			.i_A(input_xj3[1]),					
			.i_B(input_xj3[0]),					
			.i_Ci(input_yj3[1]),				
			.o_Sum(cal_gj3[1]),					
			.o_Co(cal_hj2)						
		);
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)cal_gj2 <= 2'b11;
			else if(mbus_wlast_i == 1'b1)cal_gj2 <= 2'b11;
			else if(write_enable == 1'b0)cal_gj2 <= cal_gj2;
			else cal_gj2 <= cal_gj3;
		end
		Adder_Interface #(
			.DATA_WIDTH_4Bit(8'd1),				
			.ADDER_MODE("FA"),					
			.DATA_WIDTH(8'd1)					
		)Adder_Interface_Inst_FA1(
			.i_A(cal_gj2[1]),					
			.i_B(cal_gj2[0]),					
			.i_Ci(cal_hj2),						
			.o_Sum(cal_wj2),					
			.o_Co(cal_tj1)						
		);
		D_FF_new #(1,1,0)D_FF_new1_Inst_WJ(i_clk,i_rstn,mbus_wlast_i,write_enable,cal_wj2,cal_wj1);
		assign cal_zj1[0] = ~cal_tj1;
		assign cal_zj1[1] = cal_wj1;
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)mbus_rdata_o <= 2'b00;
			else if(mbus_wlast_i == 1'b1)mbus_rdata_o <= 2'b00;
			else if(write_enable == 1'b0)mbus_rdata_o <= mbus_rdata_o;
			else mbus_rdata_o <= cal_zj1;
		end
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)mbus_wvalid_i <= 1'b0;
			else if(i_mbus_rclr | mbus_rclr_i)mbus_wvalid_i <= 1'b0;
			else if(write_enable == 1'b0 && mbus_wlast_i == 1'b1)mbus_wvalid_i <= 1'b0;
			else if(write_enable == 1'b0)mbus_wvalid_i <= mbus_wvalid_i;
			else mbus_wvalid_i <= i_mbus_wvalid;
		end
	end
	else if(ADDER_MODE == "Serial-NoDelay")begin:gen_no_delay_radix2_adder
		genvar i;
		assign o_mbus_wstop = i_mbus_rstop;
		assign o_mbus_wclr = mbus_rclr_i;
		assign o_mbus_rdata = mbus_rdata_o;
		assign o_mbus_rvalid = mbus_rvalid_o;
		assign o_mbus_rlast = mbus_rlast_o;
		assign o_mbus_rpdata = 0;
		assign o_mbus_rpcout = 0; 
		D_FF_new #(1,2,0)D_FF_new_Inst_Rpoint(i_clk,i_rstn,mbus_wlast_i | i_mbus_rclr,write_enable,i_mbus_wpoint,o_mbus_rpoint);
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)mbus_rvalid_o <= 1'b0;
			else if(i_mbus_rclr | mbus_rclr_i)mbus_rvalid_o <= 1'b0;
			else if(i_mbus_rstop == 1'b1)mbus_rvalid_o <= 1'b0;
			else mbus_rvalid_o <= i_mbus_wvalid;
		end
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)mbus_rlast_o <= 1'b0;
			else if(i_mbus_rclr | mbus_rclr_i)mbus_rlast_o <= 1'b0;
			else if(i_mbus_rstop == 1'b1)mbus_rlast_o <= 1'b0;
			else mbus_rlast_o <= i_mbus_wlast & i_mbus_wvalid;
		end
		assign input_serialx[2] = input_xj3;
		assign input_serialy[2] = input_yj3;
		for(i = 2;i > 0;i = i - 1)begin
			D_FF_new #(2,1,0)D_FF_new2_Instx(i_clk,i_rstn,i_mbus_rclr | mbus_rclr_i,write_enable,input_serialx[i],input_serialx[i - 1]);
			D_FF_new #(2,1,0)D_FF_new2_Insty(i_clk,i_rstn,i_mbus_rclr | mbus_rclr_i,write_enable,input_serialy[i],input_serialy[i - 1]);
		end
		for(i = 0;i < 3;i = i + 1)begin
			assign cal_serialg[i][0] = input_serialy[i][0];
			Adder_Interface #(
				.DATA_WIDTH_4Bit(8'd1),				
				.ADDER_MODE("FA"),					
				.DATA_WIDTH(8'd1)					
			)Adder_Interface_Inst0(
				.i_A(input_serialx[i][1]),			
				.i_B(input_serialx[i][0]),			
				.i_Ci(input_serialy[i][1]),			
				.o_Sum(cal_serialg[i][1]),			
				.o_Co(cal_serialh[i])				
			);
		end
		assign cal_serialh[3] = cal_serialh[0];
		for(i = 0;i < 3;i = i + 1)begin
			Adder_Interface #(
				.DATA_WIDTH_4Bit(8'd1),				
				.ADDER_MODE("FA"),					
				.DATA_WIDTH(8'd1)					
			)Adder_Interface_Inst1(
				.i_A(cal_serialg[i][1]),			
				.i_B(cal_serialg[i][0]),			
				.i_Ci(cal_serialh[i + 1]),			
				.o_Sum(cal_serialw[i]),				
				.o_Co(cal_serialt[i])				
			);
		end
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)mbus_rdata_o <= 2'b00;
			else if(mbus_wlast_i == 1'b1)mbus_rdata_o <= 2'b00;
			else if(write_enable == 1'b0)mbus_rdata_o <= mbus_rdata_o;
			else mbus_rdata_o <= {cal_serialw[1],~cal_serialt[2]};
		end
	end 
	else if(ADDER_MODE == "Parallel")begin:gen_parallel_radix2_adder
		genvar i;
		wire [1:0]RAM_Data[ACCURATE_MAX - 1:0];
		wire [3:0]adder42_data[ACCURATE_MAX - 1:0];	
		wire [ACCURATE_MAX - 1:0]adder42_ci;		
		wire [ACCURATE_MAX - 1:0]adder42_sum;		
		wire [ACCURATE_MAX - 1:0]adder42_carry;		
		wire [ACCURATE_MAX - 1:0]adder42_co;		
		assign adder42_data[0][3] = ~i_mbus_wpdata_y[0];
		assign adder42_data[0][2] = i_mbus_wpdata_y[1];	
		assign adder42_data[0][1] = ~i_mbus_wpdata_x[0];
		assign adder42_data[0][0] = i_mbus_wpdata_x[1];	
		assign adder42_ci[0] = i_mbus_wpcin[1];
		for(i = 1;i < ACCURATE_MAX;i = i + 1)begin
			assign adder42_data[i][3] = ~i_mbus_wpdata_y[2 * i + 0];
			assign adder42_data[i][2] = i_mbus_wpdata_y[2 * i + 1];
			assign adder42_data[i][1] = ~i_mbus_wpdata_x[2 * i + 0];
			assign adder42_data[i][0] = i_mbus_wpdata_x[2 * i + 1];
			assign adder42_ci[i] = adder42_co[i - 1];
		end
		for(i = 0;i < ACCURATE_MAX;i = i + 1)begin
			Compressed_Adder_Interface #(
				.COMPRESSED_MODE("4-2"),	
				.DATA_WIDTH_0(4),			
				.DATA_WIDTH_1(1)			
			)Compressed_Adder_Interface_Inst(
				.i_X(adder42_data[i]),		
				.i_Ci(adder42_ci[i]),		
				.o_Sum(adder42_sum[i]),		
				.o_Carry(adder42_carry[i]),	
				.o_Co(adder42_co[i])		
			);	
		end
		assign o_mbus_wstop = i_mbus_rstop;
		assign o_mbus_wclr = 0;
		assign o_mbus_rdata = 0;
		assign o_mbus_rpoint = 0;
		assign o_mbus_rvalid = mbus_rvalid_o;
		assign o_mbus_rlast = mbus_wlast_i;
		for(i = 0;i < ACCURATE_MAX;i = i + 1)begin
			assign o_mbus_rpdata[(i + 1) * 2 - 1:i * 2] = RAM_Data[i];
		end
		D_FF_new #(1,1,0)D_FF_new1_Inst_Rpcout0(i_clk,i_rstn,1'b0,write_enable,~adder42_carry[ACCURATE_MAX - 1],o_mbus_rpcout[0]);
		D_FF_new #(1,1,0)D_FF_new1_Inst_Rpcout1(i_clk,i_rstn,1'b0,write_enable,adder42_co[ACCURATE_MAX - 1],o_mbus_rpcout[1]);
		D_FF_new #(1,1,0)D_FF_new1_Inst_Rdata_Plus0(i_clk,i_rstn,1'b0,write_enable,adder42_sum[0],RAM_Data[0][1]);
		D_FF_new #(1,1,0)D_FF_new1_Inst_Rdata_Minus0(i_clk,i_rstn,1'b0,write_enable,i_mbus_wpcin[0],RAM_Data[0][0]);
		for(i = 1;i < ACCURATE_MAX;i = i + 1)begin
			D_FF_new #(1,1,0)D_FF_new1_Inst_Rdata_Plus(i_clk,i_rstn,i_mbus_rclr | mbus_rclr_i,write_enable,adder42_sum[i],RAM_Data[i][1]);
			D_FF_new #(1,1,0)D_FF_new1_Inst_Rdata_Minus(i_clk,i_rstn,i_mbus_rclr | mbus_rclr_i,write_enable,~adder42_carry[i - 1],RAM_Data[i][0]);
		end
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)mbus_rvalid_o <= 1'b0;
			else if(i_mbus_rclr | mbus_rclr_i)mbus_rvalid_o <= 1'b0;
			else if(i_mbus_rstop == 1'b1)mbus_rvalid_o <= 1'b0;
			else mbus_rvalid_o <= i_mbus_wvalid;
		end
	end
	else begin:gen_unkown
		assign o_mbus_wstop = 0;
		assign o_mbus_wclr = 0;
		assign o_mbus_rdata = 0;
		assign o_mbus_rpoint = 0;
		assign o_mbus_rvalid = 0;
		assign o_mbus_rlast = 0;
		assign o_mbus_rpdata = 0;
		assign o_mbus_rpcout = 0;
		initial begin
			$display("ParameterCheck:Warning! The ADDER_MODE should be set between {Default,Serial-NoDelay,Parallel}!\n");
			$finish;
		end
	end	endgenerate
	D_FF_new #(1,1,1)D_FF_new1_Inst_Wlast(i_clk,i_rstn,i_mbus_rclr | mbus_rclr_i,write_enable,i_mbus_wlast,mbus_wlast_i);
	D_FF_new #(1,1,0)D_FF_new1_Inst_Rclr(i_clk,i_rstn,1'b0,1'b1,i_mbus_rclr,mbus_rclr_i);
endmodule