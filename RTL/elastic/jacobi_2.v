`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/07 17:31:03
// Design Name: 
// Module Name: example_msdf
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


module jacobi_2(
    input clk,
    input rstn,
    input [2:0]start_in_0,
    input start_valid_0,
    output start_ready_0,
    output [2:0]end_out_0,
    output end_valid_0,
    input end_ready_0,

    input [2:0]start_in_1,
    input start_valid_1,
    output start_ready_1,
    output [2:0]end_out_1,
    output end_valid_1,
    input end_ready_1
    );

	wire rst = ~rstn;

	wire [2:0]cst_a10_dataInArray_0;
	wire cst_a10_pValidArray_0;
	wire cst_a10_readyArray_0;
	wire cst_a10_nReadyArray_0;
	wire cst_a10_validArray_0;
	wire [2:0]cst_a10_dataOutArray_0;

	wire [2:0]cst_a01_dataInArray_0;
	wire cst_a01_pValidArray_0;
	wire cst_a01_readyArray_0;
	wire cst_a01_nReadyArray_0;
	wire cst_a01_validArray_0;
	wire [2:0]cst_a01_dataOutArray_0;

	wire [2:0]cst_y0_dataInArray_0;
	wire cst_y0_pValidArray_0;
	wire cst_y0_readyArray_0;
	wire cst_y0_nReadyArray_0;
	wire cst_y0_validArray_0;
	wire [2:0]cst_y0_dataOutArray_0;

	wire [2:0]cst_y1_dataInArray_0;
	wire cst_y1_pValidArray_0;
	wire cst_y1_readyArray_0;
	wire cst_y1_nReadyArray_0;
	wire cst_y1_validArray_0;
	wire [2:0]cst_y1_dataOutArray_0;

	wire [2:0]mul_0_dataInArray_0;
	wire [2:0]mul_0_dataInArray_1;
	wire mul_0_pValidArray_0;
	wire mul_0_pValidArray_1;
	wire mul_0_readyArray_0;
	wire mul_0_readyArray_1;
	wire mul_0_nReadyArray_0;
	wire mul_0_validArray_0;
	wire [2:0]mul_0_dataOutArray_0;

	wire [2:0]mul_1_dataInArray_0;
	wire [2:0]mul_1_dataInArray_1;
	wire mul_1_pValidArray_0;
	wire mul_1_pValidArray_1;
	wire mul_1_readyArray_0;
	wire mul_1_readyArray_1;
	wire mul_1_nReadyArray_0;
	wire mul_1_validArray_0;
	wire [2:0]mul_1_dataOutArray_0;

	wire [2:0]add_0_dataInArray_0;
	wire [2:0]add_0_dataInArray_1;
	wire add_0_pValidArray_0;
	wire add_0_pValidArray_1;
	wire add_0_readyArray_0;
	wire add_0_readyArray_1;
	wire add_0_nReadyArray_0;
	wire add_0_validArray_0;
	wire [2:0]add_0_dataOutArray_0;

	wire [2:0]add_1_dataInArray_0;
	wire [2:0]add_1_dataInArray_1;
	wire add_1_pValidArray_0;
	wire add_1_pValidArray_1;
	wire add_1_readyArray_0;
	wire add_1_readyArray_1;
	wire add_1_nReadyArray_0;
	wire add_1_validArray_0;
	wire [2:0]add_1_dataOutArray_0;

	wire [2:0]buffI_0_dataInArray_0;
	wire buffI_0_pValidArray_0;
	wire buffI_0_readyArray_0;
	wire buffI_0_nReadyArray_0;
	wire buffI_0_validArray_0;
	wire [2:0]buffI_0_dataOutArray_0;

	wire [2:0]buffI_1_dataInArray_0;
	wire buffI_1_pValidArray_0;
	wire buffI_1_readyArray_0;
	wire buffI_1_nReadyArray_0;
	wire buffI_1_validArray_0;
	wire [2:0]buffI_1_dataOutArray_0;

    assign start_ready_0 = buffI_0_readyArray_0;
	assign start_ready_1 = buffI_1_readyArray_0;
	
	assign cst_a10_pValidArray_0 = buffI_1_validArray_0;
	assign cst_a10_dataInArray_0 = buffI_1_dataOutArray_0;
	assign cst_a10_nReadyArray_0 = mul_1_readyArray_0;

	assign cst_a01_pValidArray_0 = buffI_0_validArray_0;
	assign cst_a01_dataInArray_0 = buffI_0_dataOutArray_0;
	assign cst_a01_nReadyArray_0 = mul_0_readyArray_0;

	assign cst_y0_pValidArray_0 = mul_0_validArray_0;
	assign cst_y0_dataInArray_0 = mul_0_dataOutArray_0;
	assign cst_y0_nReadyArray_0 = add_0_readyArray_1;

	assign cst_y1_pValidArray_0 = mul_1_validArray_0;
	assign cst_y1_dataInArray_0 = mul_1_dataOutArray_0;
	assign cst_y1_nReadyArray_0 = add_1_readyArray_1;

	assign mul_0_pValidArray_0 = cst_a01_validArray_0;
	assign mul_0_dataInArray_0 = cst_a01_dataOutArray_0;
	assign mul_0_pValidArray_1 = buffI_1_validArray_0;
	assign mul_0_dataInArray_1 = buffI_1_dataOutArray_0;
	assign mul_0_nReadyArray_0 = cst_y0_readyArray_0;

	assign mul_1_pValidArray_0 = cst_a10_validArray_0;
	assign mul_1_dataInArray_0 = cst_a10_dataOutArray_0;
	assign mul_1_pValidArray_1 = buffI_0_validArray_0;
	assign mul_1_dataInArray_1 = buffI_0_dataOutArray_0;
	assign mul_1_nReadyArray_0 = cst_y1_readyArray_0;

	assign add_0_pValidArray_0 = mul_0_validArray_0;
	assign add_0_dataInArray_0 = mul_0_dataOutArray_0;
	assign add_0_pValidArray_1 = cst_y0_validArray_0;
	assign add_0_dataInArray_1 = cst_y0_dataOutArray_0;
	assign add_0_nReadyArray_0 = buffI_1_readyArray_0;

	assign add_1_pValidArray_0 = mul_1_validArray_0;
	assign add_1_dataInArray_0 = mul_1_dataOutArray_0;
	assign add_1_pValidArray_1 = cst_y1_validArray_0;
	assign add_1_dataInArray_1 = cst_y1_dataOutArray_0;
	assign add_1_nReadyArray_0 = buffI_0_readyArray_0;

	assign buffI_0_pValidArray_0 = start_valid_0;
	assign buffI_0_dataInArray_0 = start_in_0;
	assign buffI_0_nReadyArray_0 = mul_1_readyArray_1;

	assign buffI_1_pValidArray_0 = start_valid_1;
	assign buffI_1_dataInArray_0 = start_in_1;
	assign buffI_1_nReadyArray_0 = mul_0_readyArray_1;
	
	assign end_out_0 = add_0_dataOutArray_0;
    assign end_valid_0 = add_0_validArray_0;
	
	assign end_out_1 = add_1_dataOutArray_0;
    assign end_valid_1 = add_1_validArray_0;
//-0000_1010_000000000
msdf_Const
#(.CONST_DATA_PLUS(64'h0000_0000_0000_0000), .CONST_DATA_MINUS(64'h0a00_0000_0000_0000))
cst_a10(
	.clk(clk),
	.rst(rst),
	.dataInArray_0(cst_a10_dataInArray_0),
	.pValidArray_0(cst_a10_pValidArray_0),
	.readyArray_0(cst_a10_readyArray_0),
	.nReadyArray_0(cst_a10_nReadyArray_0),
	.validArray_0(cst_a10_validArray_0),
	.dataOutArray_0(cst_a10_dataOutArray_0)
);
//-0000_1100
msdf_Const
#(.CONST_DATA_PLUS(64'h0000_0000_0000_0000), .CONST_DATA_MINUS(64'h0c00_0000_0000_0000))
cst_a01(
	.clk(clk),
	.rst(rst),
	.dataInArray_0(cst_a01_dataInArray_0),
	.pValidArray_0(cst_a01_pValidArray_0),
	.readyArray_0(cst_a01_readyArray_0),
	.nReadyArray_0(cst_a01_nReadyArray_0),
	.validArray_0(cst_a01_validArray_0),
	.dataOutArray_0(cst_a01_dataOutArray_0)
);
//0.011_1000
msdf_Const
#(.CONST_DATA_PLUS(64'h3800_0000_0000_0000), .CONST_DATA_MINUS(64'h0000_0000_0000_0000))
cst_y0(
	.clk(clk),
	.rst(rst),
	.dataInArray_0(cst_y0_dataInArray_0),
	.pValidArray_0(cst_y0_pValidArray_0),
	.readyArray_0(cst_y0_readyArray_0),
	.nReadyArray_0(cst_y0_nReadyArray_0),
	.validArray_0(cst_y0_validArray_0),
	.dataOutArray_0(cst_y0_dataOutArray_0)
);
//0.100_1010
msdf_Const
#(.CONST_DATA_PLUS(64'h4A00_0000_0000_0000), .CONST_DATA_MINUS(64'h0000_0000_0000_0000))
cst_y1(
	.clk(clk),
	.rst(rst),
	.dataInArray_0(cst_y1_dataInArray_0),
	.pValidArray_0(cst_y1_pValidArray_0),
	.readyArray_0(cst_y1_readyArray_0),
	.nReadyArray_0(cst_y1_nReadyArray_0),
	.validArray_0(cst_y1_validArray_0),
	.dataOutArray_0(cst_y1_dataOutArray_0)
);

msdf_mult_op
#(.TARGET_PRECISION(16))
mul_0(
	.clk(clk),
	.rst(rst),
	.dataInArray_0(mul_0_dataInArray_0),
	.dataInArray_1(mul_0_dataInArray_1),
	.pValidArray_0(mul_0_pValidArray_0),
	.pValidArray_1(mul_0_pValidArray_1),
	.readyArray_0(mul_0_readyArray_0),
	.readyArray_1(mul_0_readyArray_1),
	.nReadyArray_0(mul_0_nReadyArray_0),
	.validArray_0(mul_0_validArray_0),
	.dataOutArray_0(mul_0_dataOutArray_0)
);

msdf_mult_op
#(.TARGET_PRECISION(16))
mul_1(
	.clk(clk),
	.rst(rst),
	.dataInArray_0(mul_1_dataInArray_0),
	.dataInArray_1(mul_1_dataInArray_1),
	.pValidArray_0(mul_1_pValidArray_0),
	.pValidArray_1(mul_1_pValidArray_1),
	.readyArray_0(mul_1_readyArray_0),
	.readyArray_1(mul_1_readyArray_1),
	.nReadyArray_0(mul_1_nReadyArray_0),
	.validArray_0(mul_1_validArray_0),
	.dataOutArray_0(mul_1_dataOutArray_0)
);

msdf_add_op
#(.TARGET_PRECISION(16))
add_0(
	.clk(clk),
	.rst(rst),
	.dataInArray_0(add_0_dataInArray_0),
	.dataInArray_1(add_0_dataInArray_1),
	.pValidArray_0(add_0_pValidArray_0),
	.pValidArray_1(add_0_pValidArray_1),
	.readyArray_0(add_0_readyArray_0),
	.readyArray_1(add_0_readyArray_1),
	.nReadyArray_0(add_0_nReadyArray_0),
	.validArray_0(add_0_validArray_0),
	.dataOutArray_0(add_0_dataOutArray_0)
);

msdf_add_op
#(.TARGET_PRECISION(16))
add_1(
	.clk(clk),
	.rst(rst),
	.dataInArray_0(add_1_dataInArray_0),
	.dataInArray_1(add_1_dataInArray_1),
	.pValidArray_0(add_1_pValidArray_0),
	.pValidArray_1(add_1_pValidArray_1),
	.readyArray_0(add_1_readyArray_0),
	.readyArray_1(add_1_readyArray_1),
	.nReadyArray_0(add_1_nReadyArray_0),
	.validArray_0(add_1_validArray_0),
	.dataOutArray_0(add_1_dataOutArray_0)
);

elasticBuffer
#(.DATA_WIDTH(3))
buffI_0(
	.clk(clk),
	.rstn(rstn),
	.dataInArray(buffI_0_dataInArray_0),
	.pValidArray(buffI_0_pValidArray_0),
	.readyArray(buffI_0_readyArray_0),
	.nReadyArray(buffI_0_nReadyArray_0),
	.validArray(buffI_0_validArray_0),
	.dataOutArray(buffI_0_dataOutArray_0)
);

elasticBuffer
#(.DATA_WIDTH(3))
buffI_1(
	.clk(clk),
	.rstn(rstn),
	.dataInArray(buffI_1_dataInArray_0),
	.pValidArray(buffI_1_pValidArray_0),
	.readyArray(buffI_1_readyArray_0),
	.nReadyArray(buffI_1_nReadyArray_0),
	.validArray(buffI_1_validArray_0),
	.dataOutArray(buffI_1_dataOutArray_0)
);
endmodule