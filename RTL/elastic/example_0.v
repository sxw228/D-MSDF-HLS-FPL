`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/31 19:58:52
// Design Name: 
// Module Name: example_0
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


module example_0(
    input wire clk,
    input wire rstn,
    input wire start_in,
    input wire start_valid,
    output wire start_ready,
    output wire end_out,
    output wire end_valid,
    input wire end_ready,

	output wire [31:0]a_address0,
	output wire a_ce0 ,
	output wire a_we0,
	output wire [31:0]a_dout0,
	input wire [31:0]a_din0,
	output wire [31:0]a_address1,
	output wire a_ce1,
	output wire a_we1,
	output wire [31:0]a_dout1,
	input wire [31:0]a_din1
    );
    


    wire rst = ~rstn;

    wire start_0_clk;
	wire start_0_rst;
	wire start_0_dataInArray_0;
	wire start_0_pValidArray_0;
	wire start_0_readyArray_0;
	wire start_0_nReadyArray_0;
	wire start_0_validArray_0;
	wire start_0_dataOutArray_0;



	wire forkC_1_clk;
	wire forkC_1_rst;
	wire forkC_1_dataInArray_0;
	wire forkC_1_pValidArray_0;
	wire forkC_1_readyArray_0;
	wire forkC_1_nReadyArray_0;
	wire forkC_1_validArray_0;
	wire forkC_1_dataOutArray_0;
	wire forkC_1_nReadyArray_1;
	wire forkC_1_validArray_1;
	wire forkC_1_dataOutArray_1;
	wire forkC_1_nReadyArray_2;
	wire forkC_1_validArray_2;
	wire forkC_1_dataOutArray_2;
	wire forkC_1_nReadyArray_3;
	wire forkC_1_validArray_3;
	wire forkC_1_dataOutArray_3;
	




    wire cst_0_clk; 
	wire cst_0_rst;
	wire [1:0]cst_0_dataInArray_0;
	wire cst_0_pValidArray_0;
	wire cst_0_readyArray_0;
	wire cst_0_nReadyArray_0;
	wire cst_0_validArray_0;
	wire [1:0]cst_0_dataOutArray_0;

	wire cst_1_clk;
	wire cst_1_rst;
	wire cst_1_dataInArray_0;
	wire cst_1_pValidArray_0;
	wire cst_1_readyArray_0;
	wire cst_1_nReadyArray_0;
	wire cst_1_validArray_0;
	wire cst_1_dataOutArray_0;

	

	wire cst_2_clk;
	wire cst_2_rst;
	wire cst_2_dataInArray_0;
	wire cst_2_pValidArray_0;
	wire cst_2_readyArray_0;
	wire cst_2_nReadyArray_0;
	wire cst_2_validArray_0;
	wire cst_2_dataOutArray_0;


	wire ret_0_clk;
	wire ret_0_rst;
	wire ret_0_dataInArray_0;
	wire ret_0_pValidArray_0;
	wire ret_0_readyArray_0;
	wire ret_0_nReadyArray_0;
	wire ret_0_validArray_0;
	wire ret_0_dataOutArray_0;

	

	

	
    wire store_0_clk;
	wire store_0_rst;
	wire [1:0]store_0_dataInArray_0;
	wire store_0_dataInArray_1;
	wire store_0_pValidArray_0;
	wire store_0_pValidArray_1;
	wire store_0_readyArray_0;
	wire store_0_readyArray_1;
	wire store_0_nReadyArray_0;
	wire store_0_validArray_0;
	wire [1:0]store_0_dataOutArray_0;
	wire store_0_nReadyArray_1;
	wire store_0_validArray_1;
	wire store_0_dataOutArray_1;

	wire end_0_clk;
	wire end_0_rst;
	wire end_0_dataInArray_0;
	wire end_0_dataInArray_1;
	wire end_0_pValidArray_0;
	wire end_0_pValidArray_1;
	wire end_0_readyArray_0;
	wire end_0_readyArray_1;
	wire end_0_nReadyArray_0;
	wire end_0_validArray_0;
	wire end_0_dataOutArray_0;
	wire end_0_validArray_1;
	wire [31:0]end_0_dataOutArray_1;
	wire end_0_nReadyArray_1;

	wire MC_a_clk;
	wire MC_a_rst;
	wire [31:0]MC_a_dataInArray_0;
	wire MC_a_dataInArray_1;
	wire [1:0]MC_a_dataInArray_2;
	wire MC_a_dataInArray_3;
	wire MC_a_pValidArray_0;
	wire MC_a_pValidArray_1;
	wire MC_a_pValidArray_2;
	wire MC_a_pValidArray_3;
	wire MC_a_readyArray_0;
	wire MC_a_readyArray_1;
	wire MC_a_readyArray_2;
	wire MC_a_readyArray_3;
	wire MC_a_nReadyArray_0;
	wire MC_a_validArray_0;
	wire MC_a_dataOutArray_0;
	wire MC_a_nReadyArray_1;
	wire MC_a_validArray_1;
	wire [1:0]MC_a_dataOutArray_1;
	wire MC_a_we0_ce0;

    
    assign cst_0_clk = clk;
	assign cst_0_rst = rst;
	assign store_0_pValidArray_0 = cst_0_validArray_0;
	assign cst_0_nReadyArray_0 = store_0_readyArray_0;
	assign store_0_dataInArray_0 = cst_0_dataOutArray_0;

	assign store_0_clk = clk;
	assign store_0_rst = rst;
	assign MC_a_pValidArray_2 = store_0_validArray_0;
	assign store_0_nReadyArray_0 = MC_a_readyArray_2;
	assign MC_a_dataInArray_2 = store_0_dataOutArray_0;
	assign MC_a_pValidArray_1 = store_0_validArray_1;
	assign store_0_nReadyArray_1 = MC_a_readyArray_1;
	assign MC_a_dataInArray_1 = store_0_dataOutArray_1;

	assign ret_0_clk = clk;
	assign ret_0_rst = rst;
	assign end_0_pValidArray_1 = ret_0_validArray_0;
	assign ret_0_nReadyArray_0 = end_0_readyArray_1;
	assign end_0_dataInArray_1 = ret_0_dataOutArray_0;

	assign cst_1_clk = clk;
	assign cst_1_rst = rst;
	assign store_0_pValidArray_1 = cst_1_validArray_0;
	assign cst_1_nReadyArray_0 = store_0_readyArray_1;
	assign store_0_dataInArray_1 = cst_1_dataOutArray_0;

	assign MC_a_clk = clk;
	assign MC_a_rst = rst;
	assign a_ce0 = MC_a_we0_ce0;
	assign a_we0 = MC_a_we0_ce0;
	assign end_0_pValidArray_0 = MC_a_validArray_0;
	assign MC_a_nReadyArray_0 = end_0_readyArray_0;
	assign end_0_dataInArray_0 = MC_a_dataOutArray_0;

	assign cst_2_clk = clk;
	assign cst_2_rst = rst;
	assign MC_a_pValidArray_0 = cst_2_validArray_0;
	assign cst_2_nReadyArray_0 = MC_a_readyArray_0;
	assign MC_a_dataInArray_0 = cst_2_dataOutArray_0;

	assign end_0_clk = clk;
	assign end_0_rst = rst;
	assign end_valid = end_0_validArray_0;
	assign end_out = end_0_dataOutArray_0;
	assign end_0_nReadyArray_0 = end_ready;

	assign start_0_clk = clk;
	assign start_0_rst = rst;
	assign start_0_pValidArray_0 = start_valid;
	assign start_ready = start_0_readyArray_0;
	assign forkC_1_pValidArray_0 = start_0_validArray_0;
	assign start_0_nReadyArray_0 = forkC_1_readyArray_0;
	assign forkC_1_dataInArray_0 = start_0_dataOutArray_0;

	assign forkC_1_clk = clk;
	assign forkC_1_rst = rst;
	assign cst_0_pValidArray_0 = forkC_1_validArray_0;
	assign forkC_1_nReadyArray_0 = cst_0_readyArray_0;
	assign cst_0_dataInArray_0 = 2'b10;
	assign cst_1_pValidArray_0 = forkC_1_validArray_1;
	assign forkC_1_nReadyArray_1 = cst_1_readyArray_0;
	assign cst_1_dataInArray_0 = 1'b0;
	assign cst_2_pValidArray_0 = forkC_1_validArray_2;
	assign forkC_1_nReadyArray_2 = cst_2_readyArray_0;
	assign cst_2_dataInArray_0 = 1'b1;
	assign ret_0_pValidArray_0 = forkC_1_validArray_3;
	assign forkC_1_nReadyArray_3 = ret_0_readyArray_0;
	assign ret_0_dataInArray_0 = forkC_1_dataOutArray_3;


 start_node#(
    .INPUT_COUNT(1),
    .OUTPUT_COUNT(1),
    .DATA_SIZE_IN(1),
    .DATA_SIZE_OUT(1))
 start_0
(
	.clk(start_0_clk),
	.rst(start_0_rst),
	.dataInArray(start_0_dataInArray_0),
	.pValidArray(start_0_pValidArray_0),
	.readyArray(start_0_readyArray_0),
	.nReadyArray(start_0_nReadyArray_0),
	.validArray(start_0_validArray_0),
	.dataOutArray(start_0_dataOutArray_0)
);


Fork_top #(.INPUTS(1),
	.SIZE(4),
	.DATA_SIZE_IN(1),
	.DATA_SIZE_OUT(1)
	) 
	forkC_1
(
	.clk(forkC_1_clk),
	.rstn(rstn),
	.dataInArray(forkC_1_dataInArray_0),
	.pValidArray(forkC_1_pValidArray_0),
	.readyArray(forkC_1_readyArray_0),
	.nReadyArray({forkC_1_nReadyArray_3,forkC_1_nReadyArray_2,forkC_1_nReadyArray_1,forkC_1_nReadyArray_0}),
	.validArray({forkC_1_validArray_3,forkC_1_validArray_2,forkC_1_validArray_1,forkC_1_validArray_0}),
	.dataOutArray({forkC_1_dataOutArray_3,forkC_1_dataOutArray_2,forkC_1_dataOutArray_1,forkC_1_dataOutArray_0})
);



     Const #(
        .SIZE(1),
        .INPUTS(1),
        .DATA_SIZE_IN(2),
        .DATA_SIZE_OUT(2)
        )cst_0  
    (
        .clk(cst_0_clk),
        .rst(cst_0_rst),
        .dataInArray(cst_0_dataInArray_0),
        .pValidArray(cst_0_pValidArray_0),
        .readyArray(cst_0_readyArray_0),
        .nReadyArray(cst_0_nReadyArray_0),
        .validArray(cst_0_validArray_0),
        .dataOutArray(cst_0_dataOutArray_0)
    );
 Const #(
        .SIZE(1),
        .INPUTS(1),
        .DATA_SIZE_IN(1),
        .DATA_SIZE_OUT(1)
        )
        cst_1
 (
	.clk(cst_1_clk),
	.rst(cst_1_rst),
	.dataInArray(cst_1_dataInArray_0),
	.pValidArray(cst_1_pValidArray_0),
	.readyArray(cst_1_readyArray_0),
	.nReadyArray(cst_1_nReadyArray_0),
	.validArray(cst_1_validArray_0),
	.dataOutArray(cst_1_dataOutArray_0)
);




ret_op #(
    .DATA_SIZE_IN(1),
    .DATA_SIZE_OUT(1))
ret_0
(
	.clk(ret_0_clk),
	.rstn(rstn),
	.dataInArray(ret_0_dataInArray_0),
	.pValidArray(ret_0_pValidArray_0),
	.readyArray(ret_0_readyArray_0),
	.nReadyArray(ret_0_nReadyArray_0),
	.validArray(ret_0_validArray_0),
	.dataOutArray(ret_0_dataOutArray_0)
);


Const #(
        .SIZE(1),
        .INPUTS(1),
        .DATA_SIZE_IN(1),
        .DATA_SIZE_OUT(1)
        ) cst_2
(
	.clk(cst_2_clk),
	.rst(cst_2_rst),
	.dataInArray(cst_2_dataInArray_0),
	.pValidArray(cst_2_pValidArray_0),
	.readyArray(cst_2_readyArray_0),
	.nReadyArray(cst_2_nReadyArray_0),
	.validArray(cst_2_validArray_0),
	.dataOutArray(cst_2_dataOutArray_0)
);


mc_store_op#(
    .INPUTS(2),
    .OUTPUTS(2),
    .ADDRESS_SIZE(1),
    .DATA_SIZE(2)) 
    store_0
(
	.clk(store_0_clk),
	.rst(store_0_rst),
	.dataInArray(store_0_dataInArray_0),
	.input_addr(store_0_dataInArray_1),
	.pValidArray({store_0_pValidArray_1,store_0_pValidArray_0}),
	.readyArray({store_0_readyArray_1,store_0_readyArray_0}),
	.nReadyArray({store_0_nReadyArray_1,store_0_nReadyArray_0}),
	.validArray({store_0_validArray_1,store_0_validArray_0}),
	.dataOutArray(store_0_dataOutArray_0),
	.output_addr(store_0_dataOutArray_1)
);
end_node#(
    .INPUTS(1),
    .MEM_INPUTS(1),
    .OUTPUTS(1),
    .DATA_SIZE_IN(1),
    .DATA_SIZE_OUT(1)) 
end_0(
	.clk(end_0_clk),
	.rst(end_0_rst),
	.dataInArray(end_0_dataInArray_1),
	.eValidArray(end_0_pValidArray_0),
	.pValidArray(end_0_pValidArray_1),
	.eReadyArray(end_0_readyArray_0),
	.readyArray(end_0_readyArray_1),
	.dataOutArray(end_0_dataOutArray_0),
	.validArray(end_0_validArray_0),
	.nReadyArray(end_0_nReadyArray_0)
);
MemCont #(
    .DATA_SIZE(2),
    .ADDRESS_SIZE(1),
    .BB_COUNT(1),
    .LOAD_COUNT(1),
    .STORE_COUNT(1)
    )MC_a
(
	.clk(MC_a_clk),
	.rst(MC_a_rst),
	.io_storeDataOut(a_dout0),
	.io_storeAddrOut(a_address0),
	.io_storeEnable(MC_a_we0_ce0),
	.io_loadDataIn(a_din1),
	.io_loadAddrOut(a_address1),
	.io_loadEnable(a_ce1),
	.io_bbReadyToPrevs(MC_a_readyArray_0),
	.io_bbpValids(MC_a_pValidArray_0),
	.io_bb_stCountArray(MC_a_dataInArray_0),
	.io_rdPortsPrev_ready(MC_a_readyArray_3),
	.io_rdPortsPrev_valid(MC_a_pValidArray_3),
	.io_rdPortsPrev_bits(MC_a_dataInArray_3),
	.io_wrAddrPorts_ready(MC_a_readyArray_1),
	.io_wrAddrPorts_valid(MC_a_pValidArray_1),
	.io_wrAddrPorts_bits(MC_a_dataInArray_1),
	.io_wrDataPorts_ready(MC_a_readyArray_2),
	.io_wrDataPorts_valid(MC_a_pValidArray_2),
	.io_wrDataPorts_bits(MC_a_dataInArray_2),
	.io_rdPortsNext_ready(MC_a_nReadyArray_1),
	.io_rdPortsNext_valid(MC_a_validArray_1),
	.io_rdPortsNext_bits(MC_a_dataOutArray_1),
	.io_Empty_Valid(MC_a_validArray_0),
	.io_Empty_Ready(MC_a_nReadyArray_0)

);







endmodule
