module sxw_generate_CA_reg_v2#(
    parameter unrolling  = 72,
    parameter ADDR_WIDTH=8
) (
input enable,
input refresh,
input rst,
input clk,
input[1:0] x_in,
input[1:0] y_in,
output[unrolling -1 :0] x_plus_delay,
output[unrolling -1 :0] x_minus_delay,
output[unrolling -1 :0] y_plus_rd,
output[unrolling -1 :0] y_minus_rd,
input[(ADDR_WIDTH -1):0] accum
);


wire [unrolling-1:0] x_plus_rd, x_minus_rd;
reg [unrolling -1 :0] x_plus_wr, x_minus_wr, y_plus_wr, y_minus_wr;
reg [unrolling -1 :0] x_plus_wr_rev, x_minus_wr_rev, y_plus_wr_rev, y_minus_wr_rev;
reg [1:0] x_value, y_value;

wire wr_enable;
wire [(ADDR_WIDTH-1):0] addr;

assign addr = accum;
assign wr_enable = enable;

reg [10:0]shift_cnt;


always @ (posedge clk) begin
	if (rst) begin
		x_value <= 0;
		y_value <= 0;
        shift_cnt <= 'd0;
	end
	else begin
		if (enable) begin
			x_value <= x_in;
			y_value <= y_in;
            if(shift_cnt == 'd63)shift_cnt <= 'd0;
            else shift_cnt <= shift_cnt+1;
		end
	end
end

initial begin
	x_plus_wr <= 0;
	x_minus_wr <= 0;
	y_plus_wr <= 0;
	y_minus_wr <= 0;
	x_plus_wr_rev <= 0;
	x_minus_wr_rev <= 0;
	y_plus_wr_rev <= 0;
	y_minus_wr_rev <= 0;
end

always @ (posedge clk) begin
	if (rst) begin
		x_plus_wr <= 0;
		x_minus_wr <= 0;
		y_plus_wr <= 0;
		y_minus_wr <= 0;
	end
	else begin
		if (enable) begin
			if (refresh) begin
				x_plus_wr[unrolling-2:0] <= 0;
				x_minus_wr[unrolling-2:0] <= 0;
				y_plus_wr[unrolling-2:0]<= 0;
				y_minus_wr[unrolling-2:0]<= 0;
				x_plus_wr[unrolling -1] <= x_value[1];
				x_minus_wr[unrolling -1] <= x_value[0];
				y_plus_wr[unrolling -1]<= y_value[1];
				y_minus_wr[unrolling -1]<= y_value[0];
			end
			else begin
				x_plus_wr <= {x_plus_wr[unrolling - 2:0],x_value[1]};
				x_minus_wr <= {x_minus_wr[unrolling - 2:0],x_value[0]};
				y_plus_wr <= {y_plus_wr[unrolling - 2:0],y_value[1]};
		        y_minus_wr <= {y_minus_wr[unrolling - 2:0],y_value [0]};
				x_plus_wr_rev <= x_plus_wr << shift_cnt;
				x_minus_wr_rev <= x_minus_wr << shift_cnt;
				y_plus_wr_rev <= y_plus_wr << shift_cnt;
				y_minus_wr_rev <= y_minus_wr << shift_cnt;
			end	
		end
	end
end

sxw_single_clk_ram_72bits ram1(
    .clk(clk),
	.rst(rst),
	.we(wr_enable),
	.data(x_plus_wr_rev),
	.write_addr(addr),
	.read_addr(addr),
    .q(x_plus_rd)
);

sxw_D_FF #(
    .delay(1),.width(unrolling)
)D_x_plus(
    .clk(clk),
	.rst(rst),
	.enable(enable),
    .in(x_plus_rd),
    .out(x_plus_delay)
);


sxw_single_clk_ram_72bits ram2(
    .clk(clk),
	.rst(rst),
	.we(wr_enable),
	.data(x_minus_wr_rev),
	.write_addr(addr),
	.read_addr(addr),
    .q(x_minus_rd)
);

sxw_D_FF #(
    .delay(1),.width(unrolling)
)D_x_minus(
    .clk(clk),
	.rst(rst),
	.enable(enable),
    .in(x_minus_rd),
    .out(x_minus_delay)
);

sxw_single_clk_ram_72bits ram3(
    .clk(clk),
	.rst(rst),
	.we(wr_enable),
	.data(y_plus_wr_rev),
	.write_addr(addr),
	.read_addr(addr),
    .q(y_plus_rd)
);

sxw_single_clk_ram_72bits ram4(
    .clk(clk),
	.rst(rst),
	.we(wr_enable),
	.data(y_minus_wr_rev),
	.write_addr(addr),
	.read_addr(addr),
    .q(y_minus_rd)
);

endmodule
