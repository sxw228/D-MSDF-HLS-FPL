`timescale 1ns / 1ps
module OnTheFly_CMP_Interface
#(
	parameter ENCODING_MODE	= "signed-digit",	
	parameter ERR_WIDTH		= 8'd8				
)
(
	input i_clk,
	input i_rstn,
	input i_mbus_wen,							
	input [ERR_WIDTH - 1:0]i_mbus_werr_limit,	
	input [1:0]i_mbus_wdata_x,					
	input [1:0]i_mbus_wdata_y,					
	input i_mbus_wvalid,						
	input i_mbus_wlast,							
	output [2:0]o_mbus_rdata,					
	output o_mbus_rvalid						
);
	localparam ST_IDLE	= 0;
	localparam ST_EQUAL = 1;	
	localparam ST_LESSY = 2;	
	localparam ST_MOREY = 3;	
	localparam ST_END_E	= 4;	
	localparam ST_END_L	= 5;	
	localparam ST_END_M	= 6;	
	reg [ERR_WIDTH - 1:0]write_cnt = 0;
	wire write_enable;
	reg flag_err_limit = 0;
	reg flag_over = 0;
	reg [1:0]delta_xy_now = 0;
	reg [1:0]delta_xy_last = 0;
	wire [1:0]encode_minus1;
	wire [1:0]encode_plus1;
	wire encode_equal;
	reg [2:0]state_current = 0;
	reg [2:0]state_next = 0;
	wire write_enable_buff;
	wire mbus_wen_i;
	wire [ERR_WIDTH - 1:0]mbus_werr_limit_i;
	wire [1:0]mbus_wdata_x_i;
	wire [1:0]mbus_wdata_y_i;
	wire mbus_wvalid_i;
	wire mbus_wlast_i;
	reg [2:0]mbus_rdata_o = 0;
	reg mbus_rvalid_o = 0;
	assign write_enable = mbus_wvalid_i & mbus_wen_i;

	assign encode_minus1 = 2'b01;
	assign encode_plus1 = 2'b10;
	assign encode_equal = (mbus_wdata_x_i == mbus_wdata_y_i) | ((mbus_wdata_x_i[1] == mbus_wdata_x_i[0]) & (mbus_wdata_y_i[1] == mbus_wdata_y_i[0]));

	assign o_mbus_rdata = mbus_rdata_o;
	assign o_mbus_rvalid = mbus_rvalid_o;
	
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)mbus_rdata_o <= 3'b000;
		else if(state_current == ST_END_E)mbus_rdata_o <= 3'b010;
		else if(state_current == ST_END_L)mbus_rdata_o <= 3'b001;
		else if(state_current == ST_END_M)mbus_rdata_o <= 3'b100;
		else mbus_rdata_o <= 3'b000;
	end
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)mbus_rvalid_o <= 1'b0;
		else if(state_current == ST_END_E)mbus_rvalid_o <= flag_over;
		else if(state_current == ST_END_L)mbus_rvalid_o <= flag_over;
		else if(state_current == ST_END_M)mbus_rvalid_o <= flag_over;
		else mbus_rvalid_o <= 1'b0;
	end
	always@(*)begin
		case(state_current)
			ST_IDLE:begin
				if(write_enable == 1'b0)state_next <= ST_IDLE;
				else if(encode_equal == 1'b1)state_next <= ST_EQUAL;
				else if(mbus_wdata_x_i == encode_plus1)state_next <= ST_MOREY;
				else if(mbus_wdata_y_i == encode_plus1)state_next <= ST_LESSY;
				else if(mbus_wdata_x_i == encode_minus1)state_next <= ST_LESSY;
				else state_next <= ST_MOREY;
			end
			ST_EQUAL:begin
				if(write_enable == 1'b0 | flag_err_limit == 1'b1)state_next <= ST_END_E;
				else if(encode_equal == 1'b1)state_next <= ST_EQUAL;
				else if(mbus_wdata_x_i == encode_plus1)state_next <= ST_MOREY;
				else if(mbus_wdata_y_i == encode_plus1)state_next <= ST_LESSY;
				else if(mbus_wdata_x_i == encode_minus1)state_next <= ST_LESSY;
				else state_next <= ST_MOREY;
			end
			ST_LESSY:begin
				if(write_enable == 1'b0 | flag_err_limit == 1'b1)state_next <= ST_END_L;
				else if(delta_xy_last == 2'b11)state_next <= ST_END_L;					
				else if(mbus_wdata_y_i == encode_minus1 && mbus_wdata_x_i == encode_plus1)state_next <= ST_EQUAL;
				else if(mbus_wdata_y_i == encode_minus1)state_next <= ST_LESSY;
				else state_next <= ST_END_L;
			end
			ST_MOREY:begin
				if(write_enable == 1'b0 | flag_err_limit == 1'b1)state_next <= ST_END_M;
				else if(delta_xy_last == 2'b01)state_next <= ST_END_M;					
				else if(mbus_wdata_x_i == encode_minus1 && mbus_wdata_y_i == encode_plus1)state_next <= ST_EQUAL;
				else if(mbus_wdata_x_i == encode_minus1)state_next <= ST_MOREY;
				else state_next <= ST_END_M;
			end
			ST_END_E,ST_END_L,ST_END_M:begin
				if(write_enable == 1'b0)state_next <= ST_IDLE;
				else state_next <= state_current;
			end
			default:state_next <= ST_IDLE;
		endcase
	end
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)begin
			state_current <= ST_IDLE;
		end else begin
			state_current <= state_next;
		end
	end
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)write_cnt <= {ERR_WIDTH{1'd0}};
		else if(state_current == ST_END_E)write_cnt <= {ERR_WIDTH{1'd0}};
		else if(state_current == ST_END_L)write_cnt <= {ERR_WIDTH{1'd0}};
		else if(state_current == ST_END_M)write_cnt <= {ERR_WIDTH{1'd0}};
		else write_cnt <= write_cnt + write_enable;
	end
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)flag_err_limit <= 1'd0;
		else if(mbus_werr_limit_i == {ERR_WIDTH{1'd0}})flag_err_limit <= 1'd0;
		else if(write_cnt >= mbus_werr_limit_i - 1)flag_err_limit <= 1'd0;
		else flag_err_limit <= 1'd0;
	end
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)flag_over <= 1'd0;
		else if(state_current == ST_IDLE)flag_over <= 1'd0;
		else if(flag_err_limit == 1'b1)flag_over <= 1'd1;
		else if(write_enable_buff == 1'b1)flag_over <= 1'd1;
		else flag_over <= flag_over;
	end
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)delta_xy_now <= 2'd0;
		else if(write_enable == 1'b0)delta_xy_now <= 2'd0;
		else if(mbus_wdata_x_i == encode_plus1 && mbus_wdata_y_i == encode_minus1)delta_xy_now <= 2'b01;		
		else if(mbus_wdata_y_i == encode_plus1 && mbus_wdata_x_i == encode_minus1)delta_xy_now <= 2'b11;		
		else delta_xy_now <= 2'd0;
	end
	always@(posedge i_clk or negedge i_rstn)begin
		if(i_rstn == 1'b0)delta_xy_last <= 2'd0;
		else delta_xy_last <= delta_xy_now;
	end
	D_FF #(1,0)D_FF_Inst6(i_clk,i_rstn,1'b0,1'b0,1'b1,write_enable,write_enable_buff);
	D_FF #(1,0)D_FF_Inst0(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wen,mbus_wen_i);
	D_FF #(ERR_WIDTH,0)D_FF_Inst1(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_werr_limit,mbus_werr_limit_i);
	D_FF #(2,0)D_FF_Inst2(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wdata_x,mbus_wdata_x_i);
	D_FF #(2,0)D_FF_Inst3(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wdata_y,mbus_wdata_y_i);
	D_FF #(1,0)D_FF_Inst4(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wvalid,mbus_wvalid_i);
	D_FF #(1,0)D_FF_Inst5(i_clk,i_rstn,1'b0,1'b0,1'b1,i_mbus_wlast,mbus_wlast_i);
endmodule