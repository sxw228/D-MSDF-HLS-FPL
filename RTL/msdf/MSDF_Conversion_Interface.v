`timescale 1ns / 1ps
module MSDF_Conversion_Interface
#(
	parameter RADIX_MODE	= 8'd1,				
	parameter ENCODING_MODE	= "signed-digit",	
	parameter CONVERT_MODE	= "Common",			
	parameter CA_REG_ENABLE	= 1'd0,				
	parameter ACCURATE_MAX	= 16'd64,			
	parameter DATA_WIDTH	= 8'd2,				
	parameter POINT_WIDTH	= 8'd8,				
	parameter RDATA_WIDTH	= CA_REG_ENABLE ? ACCURATE_MAX * DATA_WIDTH:ACCURATE_MAX	
)
(
	input i_clk,
	input i_rstn,
	input i_mbus_wen,							
	input [DATA_WIDTH - 1:0]i_mbus_wdata,		
	input i_mbus_wpoint,						
	input i_mbus_wvalid,						
	input i_mbus_wlast,							
	output o_mbus_wstop,						
	output o_mbus_wclr,							
	output [RDATA_WIDTH - 1:0]o_mbus_rdata,		
	output [POINT_WIDTH - 1:0]o_mbus_rpoint,	
	output o_mbus_rvalid,						
	input i_mbus_rstop,							
	input i_mbus_rclr							
);
	generate if(CA_REG_ENABLE == 1'd1)begin:gen_CA_Reg
		genvar i;
		integer j;
		reg [DATA_WIDTH - 1:0]Ram_Data[ACCURATE_MAX - 1:0];
		wire write_enable;
		wire mbus_wlast_i;
		wire mbus_rstop_i;
		wire mbus_rclr_i;
		reg mbus_rvalid_o = 0;
		assign write_enable = i_mbus_wen & i_mbus_wvalid & ~mbus_rstop_i;
		assign o_mbus_wstop = i_mbus_rstop;
		assign o_mbus_wclr = mbus_rclr_i;
		assign o_mbus_rpoint = 0;
		assign o_mbus_rvalid = mbus_rvalid_o;
		for(i = 0;i < ACCURATE_MAX;i = i + 1)begin
			assign o_mbus_rdata[(i + 1) * DATA_WIDTH - 1:i * DATA_WIDTH] = Ram_Data[i];
		end
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)mbus_rvalid_o <= 1'b0;
			else if(i_mbus_rclr == 1'b1 | mbus_rclr_i == 1'b1)mbus_rvalid_o <= 1'b0;
			else if(write_enable == 1'b0)mbus_rvalid_o <= 1'b0;
			else mbus_rvalid_o <= i_mbus_wlast;
		end
		if(CONVERT_MODE == "Common")begin:gen_shift_common
			always@(posedge i_clk or negedge i_rstn)begin
				if(i_rstn == 1'b0)Ram_Data[0] <= 1'b0;
				else if(i_mbus_rclr == 1'b1)Ram_Data[0] <= 1'b0;
				else if(write_enable == 1'b0)Ram_Data[0] <= Ram_Data[0];
				else Ram_Data[0] <= i_mbus_wdata;
			end
			for(i = 1;i < ACCURATE_MAX;i = i + 1)begin
				always@(posedge i_clk or negedge i_rstn)begin
					if(i_rstn == 1'b0)Ram_Data[i] <= {DATA_WIDTH{1'b0}};
					else if(write_enable == 1'b0)Ram_Data[i] <= Ram_Data[i];
					else if(mbus_wlast_i == 1'b1)Ram_Data[i] <= {DATA_WIDTH{1'b0}};
					else Ram_Data[i] <= Ram_Data[i - 1];
				end
			end
		end
		else if(CONVERT_MODE == "Append")begin
			reg [POINT_WIDTH - 1:0]data_cnt = 0;
			always@(posedge i_clk or negedge i_rstn)begin
				if(i_rstn == 1'b0)begin
					for(j = 0;j < ACCURATE_MAX;j = j + 1)Ram_Data[j] = {DATA_WIDTH{1'b0}};
				end else if(write_enable == 1'b0)begin
					for(j = 0;j < ACCURATE_MAX;j = j + 1)Ram_Data[j] = Ram_Data[j];
				end	else if(mbus_wlast_i == 1'b1)begin
					for(j = 0;j < ACCURATE_MAX;j = j + 1)Ram_Data[j] = {DATA_WIDTH{1'b0}};
				end else begin
					Ram_Data[data_cnt] = i_mbus_wdata;
				end
			end
			always@(posedge i_clk or negedge i_rstn)begin
				if(i_rstn == 1'b0)data_cnt <= ACCURATE_MAX - 2;
				else if(mbus_wlast_i == 1'b1)data_cnt <= ACCURATE_MAX - 2;
				else if(write_enable == 1'b0)data_cnt <= data_cnt;
				else data_cnt <= data_cnt - 1'b1;
			end	
		end
		else begin:gen_unkown
			assign o_mbus_wstop = 0;
			assign o_mbus_wclr = 0;
			assign o_mbus_rdata = 0;
			assign o_mbus_rpoint = 0;
			assign o_mbus_rvalid = 0;
			initial begin
				$display("ParameterCheck:Warning! The CONVERT_MODE should be set between {Common,Append}!\n");
				$finish;
			end
		end
		D_FF_new #(1,1,1)D_FF_new1_Inst(i_clk,i_rstn,i_mbus_rclr | mbus_rclr_i,write_enable,i_mbus_wlast,mbus_wlast_i);
		D_FF_new #(1,1,0)D_FF_new1_Inst_Rclr(i_clk,i_rstn,1'b0,1'b1,i_mbus_rclr,mbus_rclr_i);
		D_FF_new #(1,1,0)D_FF_new1_Inst_Rstop(i_clk,i_rstn,1'b0,1'b1,i_mbus_rstop,mbus_rstop_i);
	end 
	else if(RADIX_MODE == 8'd1)begin:gen_radix2_conversion
		MSDF_Conversion_Radix2_Interface #(
			.ENCODING_MODE(ENCODING_MODE),				
			.CONVERT_MODE(CONVERT_MODE),				
			.ACCURATE_MAX(ACCURATE_MAX),				
			.POINT_WIDTH(POINT_WIDTH)					
		)MSDF_Conversion_Radix2_Interface_Inst(
			.i_clk(i_clk),
			.i_rstn(i_rstn),
			.i_mbus_wen(i_mbus_wen),					
			.i_mbus_wdata(i_mbus_wdata),				
			.i_mbus_wpoint(i_mbus_wpoint),				
			.i_mbus_wvalid(i_mbus_wvalid),				
			.i_mbus_wlast(i_mbus_wlast),				
			.o_mbus_wstop(o_mbus_wstop),				
			.o_mbus_wclr(o_mbus_wclr),					
			.o_mbus_rdata(o_mbus_rdata),				
			.o_mbus_rpoint(o_mbus_rpoint),				
			.o_mbus_rvalid(o_mbus_rvalid),				
			.i_mbus_rstop(i_mbus_rstop),				
			.i_mbus_rclr(i_mbus_rclr)					
		);
	end
	else begin:gen_radix_any_conversion
		genvar i;
		integer j;
		reg flag_point = 0;
		reg [POINT_WIDTH - 1:0]point_cnt = 0;
		reg [DATA_WIDTH - 1:0]Ram_Q[ACCURATE_MAX - 1:0];
		reg [DATA_WIDTH - 1:0]Ram_QM[ACCURATE_MAX - 1:0];
		wire [DATA_WIDTH - 1:0]Shift_Q;
		wire [DATA_WIDTH - 1:0]Load_Q;
		wire [DATA_WIDTH - 1:0]Shift_QM;
		wire [DATA_WIDTH - 1:0]Load_QM;
		wire write_enable;
		wire Cload_Q;
		wire Cload_QM;
		wire mbus_wlast_i;
		wire mbus_rstop_i;
		wire mbus_rclr_i;
		reg mbus_rvalid_o = 0;
		assign write_enable = i_mbus_wen & i_mbus_wvalid & ~mbus_rstop_i;
		if(ENCODING_MODE == "signed-digit")begin:gen_sign_digit_connect
			wire [DATA_WIDTH / 2:0]wdata_plus;
			wire [DATA_WIDTH / 2:0]wdata_minus;
			assign wdata_plus = i_mbus_wdata[DATA_WIDTH - 1:DATA_WIDTH / 2];
			assign wdata_minus = i_mbus_wdata[DATA_WIDTH / 2 - 1:0];
			assign Cload_Q = wdata_plus < wdata_minus;
			assign Cload_QM = wdata_plus > wdata_minus;
			assign Shift_Q = wdata_plus - wdata_minus;
			assign Load_Q = RADIX_MODE + wdata_minus - wdata_plus;
			assign Shift_QM = wdata_plus - wdata_minus - 1;
			assign Load_QM = RADIX_MODE - 1 + wdata_minus - wdata_plus;
		end
		else if(ENCODING_MODE == "carry-save")begin:gen_carry_save_connect
			wire signed[DATA_WIDTH / 2:0]wdata_plus;
			wire signed[DATA_WIDTH / 2:0]wdata_minus;
			assign wdata_plus = i_mbus_wdata[DATA_WIDTH - 1:DATA_WIDTH / 2];
			assign wdata_minus = i_mbus_wdata[DATA_WIDTH / 2 - 1:0];
			assign Cload_Q = wdata_plus < wdata_minus;
			assign Cload_QM = wdata_plus > wdata_minus;
			assign Shift_Q = wdata_plus - wdata_minus;
			assign Load_Q = RADIX_MODE + wdata_minus - wdata_plus;
			assign Shift_QM = wdata_plus - wdata_minus - 1;
			assign Load_QM = RADIX_MODE - 1 + wdata_minus - wdata_plus;
		end
		else begin:gen_self_define
			assign Cload_Q = 0;
			assign Cload_QM = 0;
		end
		assign o_mbus_wstop = i_mbus_rstop;
		assign o_mbus_wclr = mbus_rclr_i;
		assign o_mbus_rpoint = point_cnt;
		assign o_mbus_rvalid = mbus_rvalid_o;
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)mbus_rvalid_o <= 1'b0;
			else if(i_mbus_rclr == 1'b1 | mbus_rclr_i == 1'b1)mbus_rvalid_o <= 1'b0;
			else if(write_enable == 1'b0)mbus_rvalid_o <= 1'b0;
			else mbus_rvalid_o <= i_mbus_wlast;
		end
		for(i = 0;i < ACCURATE_MAX;i = i + 1)begin
			assign o_mbus_rdata[(i + 1) * RADIX_MODE - 1:i * RADIX_MODE] = Ram_Q[i][RADIX_MODE - 1:0];
		end
		if(CONVERT_MODE == "Common")begin:gen_store_shift_common
			always@(posedge i_clk or negedge i_rstn)begin
				if(i_rstn == 1'b0)Ram_Q[0] <= 1'b0;
				else if(i_mbus_rclr == 1'b1)Ram_Q[0] <= 1'b0;
				else if(write_enable == 1'b0)Ram_Q[0] <= Ram_Q[0];
				else if(Cload_Q == 1'b0)Ram_Q[0] <= Shift_Q;
				else Ram_Q[0] <= Load_Q;
			end
			always@(posedge i_clk or negedge i_rstn)begin
				if(i_rstn == 1'b0)Ram_QM[0] <= 1'b0;
				else if(i_mbus_rclr == 1'b1)Ram_QM[0] <= 1'b0;
				else if(write_enable == 1'b0)Ram_QM[0] <= Ram_QM[0];
				else if(Cload_QM == 1'b0)Ram_QM[0] <= Shift_QM;
				else Ram_QM[0] <= Load_QM;
			end
			for(i = 1;i < ACCURATE_MAX;i = i + 1)begin
				always@(posedge i_clk or negedge i_rstn)begin
					if(i_rstn == 1'b0)Ram_Q[i] <= {DATA_WIDTH{1'b0}};
					else if(write_enable == 1'b0)Ram_Q[i] <= Ram_Q[i];
					else if(mbus_wlast_i == 1'b1)Ram_Q[i] <= {DATA_WIDTH{1'b0}};
					else if(Cload_Q == 1'b0)Ram_Q[i] <= Ram_Q[i - 1];
					else Ram_Q[i] <= Ram_QM[i - 1];
				end
				always@(posedge i_clk or negedge i_rstn)begin
					if(i_rstn == 1'b0)Ram_QM[i] <= {DATA_WIDTH{1'b0}};
					else if(write_enable == 1'b0)Ram_QM[i] <= Ram_QM[i];
					else if(mbus_wlast_i == 1'b1)Ram_QM[i] <= {DATA_WIDTH{1'b0}};
					else if(Cload_QM == 1'b0)Ram_QM[i] <= Ram_QM[i - 1];
					else Ram_QM[i] <= Ram_Q[i - 1];
				end
			end
		end else begin:gen_store_append
			reg [POINT_WIDTH - 1:0]data_cnt = 0;
			always@(posedge i_clk or negedge i_rstn)begin
				if(i_rstn == 1'b0)Ram_Q[ACCURATE_MAX - 1] = 1'b0;
				else if(i_mbus_rclr == 1'b1)Ram_Q[ACCURATE_MAX - 1] = 1'b0;
				else if(write_enable == 1'b0)Ram_Q[ACCURATE_MAX - 1] = Ram_Q[ACCURATE_MAX - 1];
				else if(Cload_Q == 1'b0 && mbus_wlast_i == 1'b1)Ram_Q[ACCURATE_MAX - 1] = Shift_Q;
				else if(mbus_wlast_i == 1'b1)Ram_Q[ACCURATE_MAX - 1] = Load_Q;
				else if(Cload_Q == 1'b0)Ram_Q[ACCURATE_MAX - 1] = Ram_Q[ACCURATE_MAX - 1];
				else Ram_Q[ACCURATE_MAX - 1] = Ram_QM[ACCURATE_MAX - 1];
			end
			always@(posedge i_clk or negedge i_rstn)begin
				if(i_rstn == 1'b0)Ram_QM[ACCURATE_MAX - 1] = 1'b0;
				else if(i_mbus_rclr == 1'b1)Ram_QM[ACCURATE_MAX - 1] = 1'b0;
				else if(write_enable == 1'b0)Ram_QM[ACCURATE_MAX - 1] = Ram_QM[ACCURATE_MAX - 1];
				else if(Cload_QM == 1'b0 && mbus_wlast_i == 1'b1)Ram_QM[ACCURATE_MAX - 1] = Shift_QM;
				else if(mbus_wlast_i == 1'b1)Ram_QM[ACCURATE_MAX - 1] = Load_QM;
				else if(Cload_QM == 1'b0)Ram_QM[ACCURATE_MAX - 1] = Ram_QM[ACCURATE_MAX - 1];
				else Ram_QM[ACCURATE_MAX - 1] = Ram_Q[ACCURATE_MAX - 1];
			end
			if(ACCURATE_MAX > 8'd1)begin
				always@(posedge i_clk or negedge i_rstn)begin
					if(i_rstn == 1'b0)begin
						for(j = 0;j < ACCURATE_MAX - 1;j = j + 1)Ram_Q[j] = {DATA_WIDTH{1'b0}};
					end else if(write_enable == 1'b0)begin
						for(j = 0;j < ACCURATE_MAX - 1;j = j + 1)Ram_Q[j] = Ram_Q[j];
					end	else if(mbus_wlast_i == 1'b1)begin
						for(j = 0;j < ACCURATE_MAX - 1;j = j + 1)Ram_Q[j] = {DATA_WIDTH{1'b0}};
					end else if(Cload_Q == 1'b0)begin
						Ram_Q[data_cnt] = Shift_Q;
					end else begin
						for(j = 0;j < ACCURATE_MAX - 1;j = j + 1)Ram_Q[j] = Ram_QM[j];
						Ram_Q[data_cnt] = Load_Q;
					end
				end
				always@(posedge i_clk or negedge i_rstn)begin
					if(i_rstn == 1'b0)begin
						for(j = 0;j < ACCURATE_MAX - 1;j = j + 1)Ram_QM[j] = {DATA_WIDTH{1'b0}};
					end else if(write_enable == 1'b0)begin
						for(j = 0;j < ACCURATE_MAX - 1;j = j + 1)Ram_QM[j] = Ram_QM[j];
					end else if(mbus_wlast_i == 1'b1)begin
						for(j = 0;j < ACCURATE_MAX - 1;j = j + 1)Ram_QM[j] = {DATA_WIDTH{1'b0}};
					end else if(Cload_QM == 1'b0)begin
						Ram_QM[data_cnt] = Shift_QM;
					end else begin
						for(j = 0;j < ACCURATE_MAX - 1;j = j + 1)Ram_QM[j] = Ram_Q[j];
						Ram_QM[data_cnt] = Load_QM;
					end
				end
			end
			always@(posedge i_clk or negedge i_rstn)begin
				if(i_rstn == 1'b0)data_cnt <= ACCURATE_MAX - 2;
				else if(mbus_wlast_i == 1'b1)data_cnt <= ACCURATE_MAX - 2;
				else if(write_enable == 1'b0)data_cnt <= data_cnt;
				else data_cnt <= data_cnt - 1'b1;
			end	
		end
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)point_cnt <= {POINT_WIDTH{1'b0}};
			else if(write_enable == 1'b0)point_cnt <= point_cnt;
			else if(mbus_wlast_i == 1'b1)point_cnt <= {POINT_WIDTH{1'b0}} + 1;
			else if(flag_point == 1'b1)point_cnt <= point_cnt + 1;
			else point_cnt <= point_cnt;
		end
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)flag_point <= 1'b0;
			else if(write_enable == 1'b0)flag_point <= flag_point;
			else if(i_mbus_wlast == 1'b1)flag_point <= 1'b0;
			else if(i_mbus_wpoint == 1'b1)flag_point <= 1'b1;
			else flag_point <= flag_point;
		end
		D_FF_new #(1,1,1)D_FF_new1_Inst(i_clk,i_rstn,i_mbus_rclr | mbus_rclr_i,write_enable,i_mbus_wlast,mbus_wlast_i);
		D_FF_new #(1,1,0)D_FF_new1_Inst_Rclr(i_clk,i_rstn,1'b0,1'b1,i_mbus_rclr,mbus_rclr_i);
		D_FF_new #(1,1,0)D_FF_new1_Inst_Rstop(i_clk,i_rstn,1'b0,1'b1,i_mbus_rstop,mbus_rstop_i);
	end endgenerate
endmodule
module MSDF_Conversion_Radix2_Interface
#(
	parameter ENCODING_MODE		= "signed-digit",	
	parameter CONVERT_MODE		= "Common",			
	parameter ACCURATE_MAX		= 16'd64,			
	parameter POINT_WIDTH		= 8'd8				
)
(
	input i_clk,
	input i_rstn,
	input i_mbus_wen,							
	input [1:0]i_mbus_wdata,					
	input i_mbus_wpoint,						
	input i_mbus_wvalid,						
	input i_mbus_wlast,							
	output o_mbus_wstop,						
	output o_mbus_wclr,							
	output [ACCURATE_MAX - 1:0]o_mbus_rdata,	
	output [POINT_WIDTH - 1:0]o_mbus_rpoint,	
	output o_mbus_rvalid,						
	input i_mbus_rstop,							
	input i_mbus_rclr							
);
	reg flag_point = 0;
	reg [POINT_WIDTH - 1:0]point_cnt = 0;
	reg [ACCURATE_MAX - 1:0]Ram_Q = 0;
	reg [ACCURATE_MAX - 1:0]Ram_QM = 0;
	wire Shift_Q;
	wire Load_Q;
	wire Shift_QM;
	wire Load_QM;
	wire write_enable;
	wire Cload_Q;
	wire Cload_QM;
	wire mbus_wlast_i;
	wire mbus_rstop_i;
	wire mbus_rclr_i;
	reg mbus_rvalid_o = 0;
	assign write_enable = i_mbus_wen & i_mbus_wvalid & ~mbus_rstop_i;
	generate if(ENCODING_MODE == "signed-digit")begin:gen_sign_digit_connect
		assign Cload_Q = ~i_mbus_wdata[1] & i_mbus_wdata[0];	
		assign Cload_QM = ~i_mbus_wdata[0] & i_mbus_wdata[1];	
		assign Shift_Q = ~i_mbus_wdata[0] & i_mbus_wdata[1];	
		assign Load_Q = 1'b1;
		assign Shift_QM = i_mbus_wdata[1] | (~i_mbus_wdata[0]);	
		assign Load_QM = 1'b0;
	end
	else if(ENCODING_MODE == "carry-save")begin:gen_carry_save_connect
		assign Cload_Q = i_mbus_wdata[1];						
		assign Cload_QM = ~i_mbus_wdata[1] & i_mbus_wdata[0];	
		assign Shift_Q = i_mbus_wdata[0];
		assign Load_Q = 1'b1;
		assign Shift_QM = ~i_mbus_wdata[0];
		assign Load_QM = 1'b0;
	end
	else begin:gen_self_define
		assign Cload_Q = 0;
		assign Cload_QM = 0;
		assign Shift_Q = 1'b0;
		assign Load_Q = 1'b0;
		assign Shift_QM = 1'b0;
		assign Load_QM = 1'b0;
	end endgenerate
	assign o_mbus_wstop = i_mbus_rstop;
	assign o_mbus_wclr = mbus_rclr_i;
	assign o_mbus_rdata = Ram_Q;
	assign o_mbus_rpoint = point_cnt;
	assign o_mbus_rvalid = mbus_rvalid_o;
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)mbus_rvalid_o <= 1'b0;
		else if(i_mbus_rclr == 1'b1 | mbus_rclr_i == 1'b1)mbus_rvalid_o <= 1'b0;
		else if(write_enable == 1'b0)mbus_rvalid_o <= 1'b0;
		else mbus_rvalid_o <= i_mbus_wlast;
	end
	generate if(CONVERT_MODE == "Common")begin:gen_store_shift_common
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)Ram_Q[0] <= 1'b0;
			else if(i_mbus_rclr == 1'b1)Ram_Q[0] <= 1'b0;
			else if(write_enable == 1'b0)Ram_Q[0] <= Ram_Q[0];
			else if(Cload_Q == 1'b0)Ram_Q[0] <= Shift_Q;
			else Ram_Q[0] <= Load_Q;
		end
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)Ram_QM[0] <= 1'b0;
			else if(i_mbus_rclr == 1'b1)Ram_QM[0] <= 1'b0;
			else if(write_enable == 1'b0)Ram_QM[0] <= Ram_QM[0];
			else if(Cload_QM == 1'b0)Ram_QM[0] <= Shift_QM;
			else Ram_QM[0] <= Load_QM;
		end
		if(ACCURATE_MAX > 8'd1)begin
			always@(posedge i_clk or negedge i_rstn)begin
				if(i_rstn == 1'b0)Ram_Q[ACCURATE_MAX - 1:1] <= {(ACCURATE_MAX - 1){1'b0}};
				else if(write_enable == 1'b0)Ram_Q[ACCURATE_MAX - 1:1] <= Ram_Q[ACCURATE_MAX - 1:1];
				else if(mbus_wlast_i == 1'b1)Ram_Q[ACCURATE_MAX - 1:1] <= {(ACCURATE_MAX - 1){1'b0}};
				else if(Cload_Q == 1'b0)Ram_Q[ACCURATE_MAX - 1:1] <= Ram_Q[ACCURATE_MAX - 2:0];
				else Ram_Q[ACCURATE_MAX - 1:1] <= Ram_QM[ACCURATE_MAX - 2:0];
			end
			always@(posedge i_clk or negedge i_rstn)begin
				if(i_rstn == 1'b0)Ram_QM[ACCURATE_MAX - 1:1] <= {(ACCURATE_MAX - 1){1'b0}};
				else if(write_enable == 1'b0)Ram_QM[ACCURATE_MAX - 1:1] <= Ram_QM[ACCURATE_MAX - 1:1];
				else if(mbus_wlast_i == 1'b1)Ram_QM[ACCURATE_MAX - 1:1] <= {(ACCURATE_MAX - 1){1'b0}};
				else if(Cload_QM == 1'b0)Ram_QM[ACCURATE_MAX - 1:1] <= Ram_QM[ACCURATE_MAX - 2:0];
				else Ram_QM[ACCURATE_MAX - 1:1] <= Ram_Q[ACCURATE_MAX - 2:0];
			end
		end
	end else begin:gen_store_Append
		reg [POINT_WIDTH - 1:0]data_cnt = 0;
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)Ram_Q[ACCURATE_MAX - 1] = 1'b0;
			else if(i_mbus_rclr == 1'b1)Ram_Q[ACCURATE_MAX - 1] = 1'b0;
			else if(write_enable == 1'b0)Ram_Q[ACCURATE_MAX - 1] = Ram_Q[ACCURATE_MAX - 1];
			else if(Cload_Q == 1'b0 && mbus_wlast_i == 1'b1)Ram_Q[ACCURATE_MAX - 1] = Shift_Q;
			else if(mbus_wlast_i == 1'b1)Ram_Q[ACCURATE_MAX - 1] = Load_Q;
			else if(Cload_Q == 1'b0)Ram_Q[ACCURATE_MAX - 1] = Ram_Q[ACCURATE_MAX - 1];
			else Ram_Q[ACCURATE_MAX - 1] = Ram_QM[ACCURATE_MAX - 1];
		end
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)Ram_QM[ACCURATE_MAX - 1] = 1'b0;
			else if(i_mbus_rclr == 1'b1)Ram_QM[ACCURATE_MAX - 1] = 1'b0;
			else if(write_enable == 1'b0)Ram_QM[ACCURATE_MAX - 1] = Ram_QM[ACCURATE_MAX - 1];
			else if(Cload_QM == 1'b0 && mbus_wlast_i == 1'b1)Ram_QM[ACCURATE_MAX - 1] = Shift_QM;
			else if(mbus_wlast_i == 1'b1)Ram_QM[ACCURATE_MAX - 1] = Load_QM;
			else if(Cload_QM == 1'b0)Ram_QM[ACCURATE_MAX - 1] = Ram_QM[ACCURATE_MAX - 1];
			else Ram_QM[ACCURATE_MAX - 1] = Ram_Q[ACCURATE_MAX - 1];
		end
		if(ACCURATE_MAX > 8'd1)begin
			always@(posedge i_clk or negedge i_rstn)begin
				if(i_rstn == 1'b0)Ram_Q[ACCURATE_MAX - 2:0] = {(ACCURATE_MAX - 1){1'b0}};
				else if(write_enable == 1'b0)Ram_Q[ACCURATE_MAX - 2:0] = Ram_Q[ACCURATE_MAX - 2:0];
				else if(mbus_wlast_i == 1'b1)Ram_Q[ACCURATE_MAX - 2:0] = {(ACCURATE_MAX - 1){1'b0}};
				else if(Cload_Q == 1'b0)begin
					Ram_Q[data_cnt] = Shift_Q;
				end else begin
					Ram_Q[ACCURATE_MAX - 2:0] = Ram_QM[ACCURATE_MAX - 2:0];
					Ram_Q[data_cnt] = Load_Q;
				end
			end
			always@(posedge i_clk or negedge i_rstn)begin
				if(i_rstn == 1'b0)Ram_QM[ACCURATE_MAX - 2:0] = {(ACCURATE_MAX - 1){1'b0}};
				else if(write_enable == 1'b0)Ram_QM[ACCURATE_MAX - 2:0] = Ram_QM[ACCURATE_MAX - 2:0];
				else if(mbus_wlast_i == 1'b1)Ram_QM[ACCURATE_MAX - 2:0] = {(ACCURATE_MAX - 1){1'b0}};
				else if(Cload_QM == 1'b0)begin
					Ram_QM[data_cnt] = Shift_QM;
				end else begin
					Ram_QM[ACCURATE_MAX - 2:0] = Ram_Q[ACCURATE_MAX - 2:0];
					Ram_QM[data_cnt] = Load_QM;
				end
			end
		end
		always@(posedge i_clk or negedge i_rstn)begin
			if(i_rstn == 1'b0)data_cnt <= ACCURATE_MAX - 2;
			else if(mbus_wlast_i == 1'b1)data_cnt <= ACCURATE_MAX - 2;
			else if(write_enable == 1'b0)data_cnt <= data_cnt;
			else data_cnt <= data_cnt - 1'b1;
		end
	end endgenerate
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)point_cnt <= {POINT_WIDTH{1'b0}};
		else if(write_enable == 1'b0)point_cnt <= point_cnt;
		else if(mbus_wlast_i == 1'b1)point_cnt <= {POINT_WIDTH{1'b0}} + 1;
		else if(flag_point == 1'b1)point_cnt <= point_cnt + 1;
		else point_cnt <= point_cnt;
	end
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)flag_point <= 1'b0;
		else if(write_enable == 1'b0)flag_point <= flag_point;
		else if(i_mbus_wlast == 1'b1)flag_point <= 1'b0;
		else if(i_mbus_wpoint == 1'b1)flag_point <= 1'b1;
		else flag_point <= flag_point;
	end
	D_FF_new #(1,1,1)D_FF_new1_Inst_Wlast(i_clk,i_rstn,i_mbus_rclr | mbus_rclr_i,write_enable,i_mbus_wlast,mbus_wlast_i);
	D_FF_new #(1,1,0)D_FF_new1_Inst_Rclr(i_clk,i_rstn,1'b0,1'b1,i_mbus_rclr,mbus_rclr_i);
	D_FF_new #(1,1,0)D_FF_new1_Inst_Rstop(i_clk,i_rstn,1'b0,1'b1,i_mbus_rstop,mbus_rstop_i);
endmodule