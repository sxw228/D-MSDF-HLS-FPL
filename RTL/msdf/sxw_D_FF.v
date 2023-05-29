module sxw_D_FF#(
	parameter width = 2,
	parameter delay = 1
)(
	input clk,
	input rst,
	input enable,
	input[width-1 :0] in,
	output[width-1 :0] out
);

reg [width-1:0] d_reg [delay:0];
genvar i;
genvar j;

always @ (*) begin
	d_reg[0] = in;
end

assign out = d_reg[delay];


generate 
	for (i = 0; i < delay; i = i+1) begin: D_FF_CHAIN
		initial begin
			d_reg[i] <= 0;
			d_reg[delay] <= 0;
		end

		always @ (posedge clk or posedge rst) begin
			if (rst) begin
			end
			else begin
				if (enable) begin
					d_reg[i+1] <= d_reg[i];
				end
			end
		end
	end	
endgenerate

endmodule






