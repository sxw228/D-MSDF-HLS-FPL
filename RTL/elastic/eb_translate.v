`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/13 15:19:31
// Design Name: 
// Module Name: eb_translate
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


module andN
#(
	parameter n = 32'd4
)
(
	input [n - 1:0]x,
	output res
);
	
	assign res = (x == {n{1'b1}});

endmodule

module nandN
#(
	parameter n = 32'd4
)
(
	input [n - 1:0]x,
	output res
);
	
	assign res = ~(x == {n{1'b1}});

endmodule

module orN
#(
	parameter n = 32'd4
)
(
	input [n - 1:0]x,
	output res
);
	
	assign res = ~(x == {n{1'b0}});

endmodule

module norN
#(
	parameter n = 32'd4
)
(
	input [n - 1:0]x,
	output res
);
	
	assign res = (x == {n{1'b0}});

endmodule

module Join
#(
    parameter SIZE	= 32'd2		//number of fan in
)
(
    input [SIZE - 1:0]pValidArray,
	input nReady,
    output valid,
    output [SIZE - 1:0]readyArray
);


    wire allPValid;
    
    andN #(SIZE)andN_inst(.x(pValidArray),.res(allPValid));
	
    assign valid = allPValid;
	assign readyArray= {SIZE{nReady}} & pValidArray;

endmodule

module TEHB
#(
	parameter DATA_WIDTH = 32'd1
)
(
    input clk,
    input rstn,

    input [DATA_WIDTH  - 1:0]dataInArray,
    input pValidArray,
    output readyArray,

    output [DATA_WIDTH - 1:0]dataOutArray,
    output validArray,
    input nReadyArray
);
	
	wire reg_en;
	reg mux_sel = 0;

	reg [DATA_WIDTH - 1:0]data_reg = 0;

	always@(posedge clk or negedge rstn)begin
		if(rstn == 1'b0)mux_sel <= 1'b0;
		else mux_sel <= validArray & ~nReadyArray;
	end
	
	always@(posedge clk or negedge rstn)begin
		if(rstn == 1'b0)data_reg <= {DATA_WIDTH{1'b0}};
		else if(reg_en == 1'b1)data_reg <= dataInArray;
		else data_reg <= data_reg;
	end
	
	assign reg_en = readyArray & (~nReadyArray) & pValidArray;
    assign dataOutArray = mux_sel ? data_reg:dataInArray;
    assign validArray = pValidArray | mux_sel;
    assign readyArray = ~mux_sel;

endmodule
	
module OEHB
#(
    parameter DATA_WIDTH = 32'd1
)
(
    input clk,
    input rstn,

    input [DATA_WIDTH - 1:0] dataInArray,
    input pValidArray,
    output readyArray,

    output [DATA_WIDTH - 1:0]dataOutArray,
    output reg validArray,
    input nReadyArray
);

    wire reg_en;
    reg [DATA_WIDTH - 1:0]data_reg = 0;


    assign readyArray = ~validArray | nReadyArray;
    assign reg_en = readyArray & pValidArray;
    assign dataOutArray = data_reg;

	always@(posedge clk or negedge rstn)begin
		if(rstn == 1'b0)validArray <= 1'b0;
		else validArray <= pValidArray | ~readyArray;
	end
	
	always@(posedge clk or negedge rstn)begin
		if(rstn == 1'b0)data_reg <= {DATA_WIDTH{1'b0}};
		else if(reg_en == 1'b1)data_reg <= dataInArray;
		else data_reg <= data_reg;
	end
       
endmodule

module elasticBuffer
#(
    parameter DATA_WIDTH = 32'd1
)
(
    input clk,
    input rst,

    input [DATA_WIDTH - 1:0]dataInArray_0,
    input pValidArray_0,
    output readyArray_0,

    output [DATA_WIDTH - 1:0]dataOutArray_0,
    output validArray_0,
    input nReadyArray_0
);

    wire [DATA_WIDTH - 1:0]tehb_dataOutArray;
	wire rstn = ~rst;
    wire tehb_validArray;
    wire tehb_nReadyArray;

    TEHB #(DATA_WIDTH)tehb_inst(
        .clk(clk),
        .rstn(rstn),
		
        .dataInArray(dataInArray_0),
        .pValidArray(pValidArray_0),
        .readyArray(readyArray_0),
		
        .dataOutArray(tehb_dataOutArray),
        .validArray(tehb_validArray),
        .nReadyArray(tehb_nReadyArray)
    );

    OEHB #(DATA_WIDTH)oehb_inst(
        .clk(clk),
        .rstn(rstn),
		
        .dataInArray(tehb_dataOutArray),
        .pValidArray(tehb_validArray),
        .readyArray(tehb_nReadyArray),
		
        .dataOutArray(dataOutArray_0),
        .validArray(validArray_0),
        .nReadyArray(nReadyArray_0)
    );


endmodule

module end_node
#(
	parameter INPUTS = 32'd1,
	parameter MEM_INPUTS = 32'd1,
	parameter DATA_WIDTH = 32'd1
)
(
	input clk,
    input rstn,
	
	input [INPUTS * DATA_WIDTH - 1:0]dataInArray,
    input [INPUTS - 1:0]pValidArray,
    output [INPUTS - 1:0]readyArray,
	
	output [DATA_WIDTH - 1:0]dataOutArray,
    output validArray,
    input nReadyArray,
	
	output [MEM_INPUTS - 1:0]eReadyArray,
	input [MEM_INPUTS - 1:0]eValidArray
);
	
	wire [DATA_WIDTH - 1:0]DataIn[INPUTS - 1:0];
	
	wire pvalid;
	wire [1:0]joinReady;
	
	reg [DATA_WIDTH - 1:0]dataOut = 0;
	assign dataOutArray = dataOut;
	
	integer i;
	
	assign pvalid = |pValidArray;
	assign readyArray = {INPUTS{joinReady[1]}};
	assign eReadyArray = {MEM_INPUTS{joinReady[0]}};
	
	always@(*)begin
		dataOut <= 0;
		for(i = 0;i < INPUTS;i = i + 1)begin
			if(pValidArray[i] == 1'b1)dataOut <= DataIn[i];
		end
	end
	
	generate begin
		genvar k;
		
		for(k = 0;k < INPUTS;k = k + 1)begin
			assign DataIn[k] = dataInArray[(k + 1) * DATA_WIDTH - 1:k * DATA_WIDTH];
		end
	end endgenerate
	
	wire mem_valid;
	
	andN #(MEM_INPUTS)andN_Inst(
		.x(eValidArray),
		.res(mem_valid)
	);

    Join #(2)Join_Inst(
		.pValidArray({pvalid,mem_valid}),
		.nReady(0),
		.valid(validArray),
		.readyArray(joinReady)
	);
	
endmodule

module branchSimple(
    input condition,
    input pValid,
    input [1:0]nReadyArray,
    output [1:0]validArray,
    output ready
);
    assign validArray[1] = ~condition & pValid;
    assign validArray[0] = condition & pValid;
    assign ready = (nReadyArray[1] & ~condition) | (nReadyArray[0] & condition);
	
endmodule

module branch
#(
    parameter DATA_WIDTH = 32'd1
)(
    input clk,
    input rstn,

    input condition,
    input [DATA_WIDTH - 1:0]dataInArray,
    input [1:0]pValidArray,
    output [1:0]readyArray,

    output [DATA_WIDTH - 1:0]dataOutArray,
    output [1:0]validArray,
    input [1:0]nReadyArray
    );


    wire joinValid;
	wire branchReady;
	
	assign dataOutArray = dataInArray;
	
    Join #(2)Join_inst(
        .pValidArray(pValidArray),
        .valid(joinValid),
		
        .readyArray(readyArray),
        .nReady(branchReady)
    );
	
    branchSimple branchSimple_inst(
        .condition(condition),
		
        .pValid(joinValid),
        .nReadyArray(branchReady),
		
        .validArray(validArray),
        .ready(branchReady)
    );
	
endmodule

module eagerFork_RegisterBlock(
    input clk,
    input rstn,
	
    input pValidArray,
    input nStopArray,
	
    input pValidAndForkStop,
    output validArray,
	
    output blockStopArray
);
    reg reg_value;
    wire reg_in;
	wire block_stop_internal;

    assign block_stop_internal = nStopArray & reg_value;
	
    assign blockStopArray = block_stop_internal;
	
    assign reg_in = block_stop_internal | (~pValidAndForkStop);
	
    assign validArray = reg_value & pValidArray;

    always@(posedge clk or negedge rstn)begin
		if(rstn == 1'b0)reg_value <= 1'b1;
        else reg_value <= reg_in;        
    end
	
endmodule

module Fork
#(
    parameter SIZE = 8'd1,
    parameter DATA_WIDTH = 32'd1
)
(
    input clk,
    input rst,

    input [DATA_WIDTH - 1:0]dataInArray_0,
    input pValidArray_0,
    output readyArray_0,

    output [SIZE * DATA_WIDTH - 1:0]dataOutArray_0,
    output [SIZE - 1:0]validArray_0,
    input [SIZE - 1:0]nReadyArray_0
);

	wire rstn = ~rst;
    wire forkStop;
    wire [SIZE - 1:0]nStopArray;
    wire [SIZE - 1:0]blockStopArray;
    wire anyBlockStop;
    wire pValidAndForkStop;

    assign readyArray_0 = ~forkStop;
    assign nStopArray[SIZE - 1:0] = ~nReadyArray_0[SIZE - 1:0];

    orN #(SIZE)orN_inst(
        .x(blockStopArray),
        .res(anyBlockStop)
    );
	

    assign forkStop = anyBlockStop;
    assign pValidAndForkStop = pValidArray_0 & forkStop;
	
    generate begin
		genvar i;
		
		for(i = 0;i < SIZE;i = i + 1)begin 
			eagerFork_RegisterBlock eagerFork_RegisterBlock_inst(
				.clk(clk),
				.rstn(rstn),
				
				.pValidArray(pValidArray_0),
				.nStopArray(nStopArray[i]),
				
				.pValidAndForkStop(pValidAndForkStop),
				.validArray(validArray_0[i]),
				
				.blockStopArray(blockStopArray[i])
			);
			assign dataOutArray_0[(i + 1) * DATA_WIDTH - 1:i * DATA_WIDTH] = dataInArray_0[DATA_WIDTH - 1:0];
		end
		
    end endgenerate

endmodule

module merge
#(
	parameter INPUTS = 32'd1,
	parameter OUTPUTS = 32'd1,
	parameter DW = 32'd1,
	parameter DATA_WIDTH = 32'd1
)
(
	input clk,
    input rst,
	
	input [INPUTS * DATA_WIDTH - 1:0]dataInArray_0,
    input [INPUTS - 1:0]pValidArray_0,
    output [INPUTS - 1:0]readyArray_0,
	
	output [DATA_WIDTH - 1:0]dataOutArray_0,
    output validArray_0,
    input nReadyArray_0
);
	wire rstn = ~rst;	
	wire [DATA_WIDTH - 1:0]DataIn[INPUTS - 1:0];
	
	wire tehb_pvalid;
	wire tehb_ready;
	
	reg [DATA_WIDTH - 1:0]tehb_data_in = 0;
	
	integer i;
	
	assign tehb_pvalid = |pValidArray_0;
	assign readyArray_0 = {INPUTS{tehb_ready}};
	
	always@(*)begin
		tehb_data_in <= 0;
		for(i = 0;i < INPUTS;i = i + 1)begin
			if(pValidArray_0[i] == 1'b1)tehb_data_in <= DataIn[i];
		end
	end
	
	generate begin
		genvar k;
		
		for(k = 0;k < INPUTS;k = k + 1)begin
			assign DataIn[k] = dataInArray_0[(k + 1) * DATA_WIDTH - 1:k * DATA_WIDTH];
		end
	end endgenerate
	
    TEHB #(DATA_WIDTH)tehb_inst(
        .clk(clk),
        .rstn(rstn),
		
        .dataInArray(tehb_data_in),
        .pValidArray(tehb_pvalid),
        .readyArray(tehb_ready),
		
        .dataOutArray(dataOutArray_0),
        .validArray(validArray_0),
        .nReadyArray(nReadyArray_0)
    );
	
endmodule

module merge_notehb
#(
	parameter INPUTS = 32'd1,
	parameter DATA_WIDTH = 32'd1
)
(
	input clk,
    input rstn,
	
	input [INPUTS * DATA_WIDTH - 1:0]dataInArray,
    input [INPUTS - 1:0]pValidArray,
    output [INPUTS - 1:0]readyArray,
	
	output [DATA_WIDTH - 1:0]dataOutArray,
    output validArray,
    input nReadyArray
);
	wire [DATA_WIDTH - 1:0]DataIn[INPUTS - 1:0];
	
	wire pvalid;
	
	reg [DATA_WIDTH - 1:0]data_in = 0;
	
	integer i;
	
	assign pvalid = |pValidArray;
	assign readyArray = {INPUTS{nReadyArray}};
	assign dataOutArray = data_in;
	
	always@(*)begin
		data_in <= 0;
		for(i = 0;i < INPUTS;i = i + 1)begin
			if(pValidArray[i] == 1'b1)data_in <= DataIn[i];
		end
	end
	
	generate begin
		genvar k;
		
		for(k = 0;k < INPUTS;k = k + 1)begin
			assign DataIn[k] = dataInArray[(k + 1) * DATA_WIDTH - 1:k * DATA_WIDTH];
		end
	end endgenerate

endmodule


module start_node
#(
	parameter DATA_WIDTH = 32'd1
)
(
	input clk,
    input rstn,
	
	input [DATA_WIDTH - 1:0]dataInArray,
    input pValidArray,
    output readyArray,
	
	output [DATA_WIDTH - 1:0]dataOutArray,
    output validArray,
    input nReadyArray
);
	
	reg flag_set = 0;
	reg start_internal = 0;
	
	always@(posedge clk or negedge rstn)begin
		if(rstn == 1'b0)flag_set <= 1'b0;
        else if(pValidArray == 1'b1)flag_set <= 1'b1;
		else flag_set <= flag_set;
    end
	
	always@(posedge clk or negedge rstn)begin
		if(rstn == 1'b0)start_internal <= 1'b0;
        else if(pValidArray == 1'b1 && flag_set == 1'b0)start_internal <= 1'b1;
		else start_internal <= 1'b0;
    end
	
	elasticBuffer #(DATA_WIDTH)elasticBuffer_Inst(
		.clk(clk),
		.rstn(rstn),

		.dataInArray_0(dataInArray),
		.pValidArray_0(start_internal),
		.readyArray_0(readyArray),

		.dataOutArray_0(dataOutArray),
		.validArray_0(validArray),
		.nReadyArray_0(nReadyArray)
	);

endmodule

module sink
#(
    parameter DATA_WIDTH = 32'd1
)
(
    input clk,
    input rstn,

    input [DATA_WIDTH - 1:0]dataInArray,
    input pValidArray,
    output readyArray
);

    assign readyArray = 1'b1;
       
endmodule

module source
#(
    parameter DATA_WIDTH = 32'd1
)
(
    input clk,
    input rstn,

    output [DATA_WIDTH - 1:0]dataOutArray,
    output validArray,
    input nReadyArray
);

    assign validArray = 1'b1;
endmodule

module elasticFifoInner
#(
	parameter DATA_WIDTH = 32'd1,
	parameter FIFO_DEPTH = 32'd1
)
(
	input clk,
    input rstn,
	
	input [DATA_WIDTH - 1:0]dataInArray,
    input pValidArray,
    output readyArray,
	
	output [DATA_WIDTH - 1:0]dataOutArray,
    output validArray,
    input nReadyArray
);
	wire ReadEn;
	wire WriteEn;
	
	reg Empty = 0;
	reg Full = 0;
	
	reg [FIFO_DEPTH:0]Tail = 0;
	reg [FIFO_DEPTH:0]Head = 0;
	
	reg [DATA_WIDTH - 1:0]FIFO_Memory[FIFO_DEPTH - 1:0];
	
	integer i;

	assign ReadEn = nReadyArray & ~Empty;
	assign WriteEn = pValidArray & (~Full | nReadyArray);
	
	assign readyArray = ~Full | nReadyArray;
	assign validArray = ~Empty;
	assign dataOutArray = FIFO_Memory[Head];
	
	//写FIFO
	always@(posedge clk or negedge rstn)begin
		if(rstn == 1'b0)begin
			for(i = 0;i < FIFO_DEPTH;i = i + 1)FIFO_Memory[i] <= {DATA_WIDTH{1'b0}};
		end else if(WriteEn == 1'b1)FIFO_Memory[Tail] <= dataInArray;
    end
	
	//写指针
	always@(posedge clk or negedge rstn)begin
		if(rstn == 1'b0)Tail <= {FIFO_DEPTH{1'b0}};
		else if(WriteEn == 1'b1)Tail <= Tail + 1;
		else Tail <= Tail;
	end
	
	//读指针
	always@(posedge clk or negedge rstn)begin
		if(rstn == 1'b0)Head <= {FIFO_DEPTH{1'b0}};
		else if(ReadEn == 1'b1)Head <= Head + 1;
		else Head <= Head;
	end
	
	//写满
	always@(posedge clk or negedge rstn)begin
		if(rstn == 1'b0)Full <= 1'b0;
		else if(WriteEn == 1'b1 && ReadEn == 1'b0 && Tail == {~Head[FIFO_DEPTH],Head[FIFO_DEPTH - 1:0]})begin
			Full <= 1'b1;
		end else if(WriteEn == 1'b0 && ReadEn == 1'b1)Full <= 1'b0;
		else Full <= Full;
	end
	
	//读空
	always@(posedge clk or negedge rstn)begin
		if(rstn == 1'b0)Empty <= 1'b1;
		else if(WriteEn == 1'b0 && ReadEn == 1'b1 && Tail == Head)begin
			Empty <= 1'b1;
		end else if(WriteEn == 1'b1 && ReadEn == 1'b0)Empty <= 1'b0;
		else Empty <= Empty;
	end
	
endmodule


module nontranspFifo
#(
	parameter DATA_WIDTH = 32'd1,
	parameter FIFO_DEPTH = 32'd1
)
(
	input clk,
    input rstn,
	
	input [DATA_WIDTH - 1:0]dataInArray,
    input pValidArray,
    output readyArray,
	
	output [DATA_WIDTH - 1:0]dataOutArray,
    output validArray,
    input nReadyArray
);
	
	wire [DATA_WIDTH - 1:0]tehb_dataOut;
	wire tehb_ready;
	wire tehb_valid;
	
	wire [DATA_WIDTH - 1:0]fifo_dataOut;
	wire fifo_ready;
	wire fifo_valid;
	
	TEHB #(DATA_WIDTH)TEHB_Inst(
		.clk(clk),
		.rstn(rstn),

		.dataInArray(dataInArray),
		.pValidArray(pValidArray),
		.readyArray(tehb_ready),

		.dataOutArray(tehb_dataOut),
		.validArray(tehb_valid),
		.nReadyArray(fifo_ready)
	);
	
	elasticFifoInner #(DATA_WIDTH,FIFO_DEPTH)elasticFifoInner_Inst(
		.clk(clk),
		.rstn(rstn),
		
		.dataInArray(tehb_dataOut),
		.pValidArray(tehb_valid),
		.readyArray(fifo_ready),
		
		.dataOutArray(fifo_dataOut),
		.validArray(fifo_valid),
		.nReadyArray(nReadyArray)
	);

endmodule

module transpFIFO
#(
	parameter DATA_WIDTH = 32'd1,
	parameter FIFO_DEPTH = 32'd1
)
(
	input clk,
    input rstn,
	
	input [DATA_WIDTH - 1:0]dataInArray,
    input pValidArray,
    output readyArray,
	
	output [DATA_WIDTH - 1:0]dataOutArray,
    output validArray,
    input nReadyArray
);
	
	wire fifo_pvalid;
	wire fifo_valid;
	wire fifo_ready;
	
	wire [DATA_WIDTH - 1:0]fifo_out;
	
	assign dataOutArray = fifo_valid ? fifo_out:dataInArray;
	assign validArray = pValidArray | fifo_valid;
	assign readyArray = fifo_ready | nReadyArray;
	
	assign fifo_pvalid = pValidArray & (~nReadyArray | fifo_valid);
	
	elasticFifoInner #(DATA_WIDTH,FIFO_DEPTH)elasticFifoInner_Inst(
		.clk(clk),
		.rstn(rstn),
		
		.dataInArray(dataInArray),
		.pValidArray(fifo_pvalid),
		.readyArray(fifo_ready),
		
		.dataOutArray(fifo_out),
		.validArray(fifo_valid),
		.nReadyArray(nReadyArray)
	);
	
endmodule

module load_op
#(
    parameter ADDRESS_SIZE = 32'd8,
    parameter DATA_SIZE = 32'd8
)
(
    input clk,
    input rstn,

    input [DATA_SIZE - 1:0] dataInArray,
    input pValidArray,
    output readyArray,

    output [DATA_SIZE - 1:0]dataOutArray,
    output validArray,
    input nReadyArray,

    output read_enable,
    output [ADDRESS_SIZE - 1:0]read_address,
    input [31:0]data_from_memory
);

    wire enable_internal;
    wire [ADDRESS_SIZE - 1:0]read_address_internal;
    wire valid_temp;
	
    assign read_enable = valid_temp & nReadyArray;
    assign enable_internal = valid_temp & nReadyArray;
    assign dataOutArray = data_from_memory;

    elasticBuffer #(ADDRESS_SIZE)elasticBuffer_inst(
        .clk(clk),
        .rstn(rstn),

        .dataInArray_0(dataInArray),
        .pValidArray_0(pValidArray),
        .readyArray_0(readyArray),

        .dataOutArray_0(read_address_internal),
        .validArray_0(valid_temp),
        .nReadyArray_0(nReadyArray)
    );
	
    assign read_address = read_address_internal;

	reg pvalid = 0;
	
	assign validArray = pvalid;
	
    always@(posedge clk or negedge rstn)begin
        if(rstn == 1'b0)pvalid <= 1'b0;
        else if(enable_internal == 1'b1)pvalid <= 1'b1;
        else if (nReadyArray == 1'b1)pvalid <= 1'b0;
		else pvalid <= pvalid;
    end

endmodule

module Const
#(
	parameter DATA_WIDTH = 32'd1
)
(
	input clk,
    input rstn,
	
	input [DATA_WIDTH - 1:0]dataInArray,
    input pValidArray,
    output readyArray,
	
	output [DATA_WIDTH - 1:0]dataOutArray,
    output validArray,
    input nReadyArray
);
	
	assign dataOutArray = dataInArray;
	assign validArray = pValidArray;
	assign readyArray = nReadyArray;
	
endmodule

module write_momory_single_inside
#(
    parameter ADDRESS_SIZE = 32'd8,
    parameter DATA_SIZE = 32'd8
)
(
    input clk,
	input rstn,

    input dataValid,
    output ready,

    input [ADDRESS_SIZE - 1:0]input_addr,
    input [DATA_SIZE - 1:0]data,

    input nReady,
    output reg valid,

    output reg write_enable,
    output reg enable,

    output reg [ADDRESS_SIZE - 1:0]write_address,
    output reg [DATA_SIZE -1 :0]data_to_memory
);


    always@(posedge clk or negedge rstn)begin
		if(rstn == 1'b0)begin
			write_address <= 0;
			data_to_memory <= 0;
			valid <= 0;
			write_enable <= 0;
			enable <= 0;
		end else begin
			write_address <= input_addr;
			data_to_memory <= data;
			valid <= dataValid;
			write_enable <= dataValid & nReady;
			enable <= dataValid & nReady;
		end
    end

    assign ready = nReady;

endmodule

module store_op
#(
    parameter ADDRESS_SIZE = 32'd8,
    parameter DATA_SIZE = 32'd8
)
(
    input clk,
    input rstn,

    input [ADDRESS_SIZE - 1:0]input_addr,
    input [DATA_SIZE - 1:0]dataInArray,

    input pValidArray,
    output readyArray,

    output [DATA_SIZE - 1:0]dataOutArray,
    output reg validArray,
    input nReadyArray,

    output write_enable,
    output enable,
    output [ADDRESS_SIZE - 1:0]write_address,
    output [31:0]data_to_memory
);

    wire single_ready;
	wire join_valid;

    Join #(2)Join_inst(
        .pValidArray(pValidArray),
        .valid(join_valid),
        .readyArray(readyArray),
        .nReady(single_ready)
    );

    write_momory_single_inside #(ADDRESS_SIZE,DATA_SIZE)write_momory_single_inside_inst(
		.clk(clk),
		.rstn(rstn),
		
		.dataValid(join_valid),
		.ready(single_ready),
		
		.input_addr(input_addr),
		
		.data(dataInArray),
		.nReady(nReadyArray),
		.valid(validArray),
		
		.write_enable(write_enable),
		.enable(enable),
		.write_address(write_address),
		.data_to_memory(data_to_memory)
	);

endmodule

module mux
#(
	parameter INPUTS = 32'd1,
	parameter DATA_WIDTH = 32'd1,
	parameter COND_SIZE = 32'd1
)
(
	input clk,
    input rstn,
	
	input [COND_SIZE - 1:0]condition,
	
	input [(INPUTS - 1)* DATA_WIDTH - 1:0]dataInArray,
    input [INPUTS - 1:0]pValidArray,
    output reg [INPUTS - 1:0]readyArray,
	
	output [DATA_WIDTH - 1:0]dataOutArray,
    output validArray,
    input nReadyArray
);

	wire [DATA_WIDTH - 1:0]tehb_data_in;
	wire tehb_pvalid;
	wire tehb_ready;
	
	integer i;
	
	assign tehb_pvalid = pValidArray[0] & pValidArray[condition + 1];
	assign tehb_data_in = pValidArray[condition];
	
	always@(*)begin
		readyArray[0] = pValidArray[0] | (tehb_pvalid & tehb_ready);
		
		for(i = 1;i < INPUTS - 1;i = i + 1)begin
			readyArray[i] = ((condition == i) & pValidArray[0] & tehb_ready & pValidArray[i + 1]) | ~pValidArray[i + 1];
		end
	end
	
	TEHB #(DATA_WIDTH)TEHB_Inst(
		.clk(clk),
		.rstn(rstn),

		.dataInArray(tehb_data_in),
		.pValidArray(tehb_pvalid),
		.readyArray(tehb_ready),

		.dataOutArray(dataOutArray),
		.validArray(validArray),
		.nReadyArray(nReadyArray)
	);
	
endmodule

module cntrlMerge
#(
    parameter INPUTS = 32'd1,
    parameter DATA_WIDTH = 32'd8
)
(
    input clk,
    input rstn,


    input [INPUTS * DATA_WIDTH - 1:0]dataInArray,
    input [1:0]pValidArray,
    output [1:0]readyArray,

    output [DATA_WIDTH - 1:0]dataOutArray,
    output [1:0]validArray,
    input [1:0]nReadyArray,

    output condition
);

    wire phi_C1_validArray;
    
    wire fork_C1_readyArray;

    wire oehb1_valid;
	wire oehb1_ready;

    merge_notehb #(2,1)phiC1(
        .clk(clk),
        .rstn(rstn),
		
        .pValidArray(pValidArray),
        .dataInArray(2'b11),
        .nReadyArray(oehb1_ready),
		
        .dataOutArray(),
        .readyArray(readyArray),
        .validArray(phi_C1_validArray)
    );

    TEHB #(1)tehb_inst(
        .clk(clk),
        .rstn(rstn),
		
        .dataInArray(~pValidArray[0]),
        .pValidArray(phi_C1_validArray),
        .readyArray(oehb1_ready),
		
        .dataOutArray(condition),
        .validArray(oehb1_valid),
        .nReadyArray(fork_C1_readyArray)
    );

    Fork #(2,1)fork_inst(
        .clk(clk),
        .rstn(rstn),
		
        .dataInArray_0(1'b1),
        .pValidArray_0(oehb1_valid),
        .readyArray_0(fork_C1_readyArray),

        .dataOutArray_0(),
        .validArray_0(validArray),
        .nReadyArray_0(nReadyArray)
    );
endmodule

module lsq_load_op
#(
	parameter INPUTS = 32'd1,
	parameter OUTPUTS = 32'd1,
	parameter DATA_WIDTH = 32'd1,
	parameter ADDRESS_SIZE = 32'd1
)
(
	input clk,
    input rstn,
	
	input [DATA_WIDTH - 1:0]dataInArray,
    input [INPUTS - 1:0]pValidArray,
    output [INPUTS - 1:0]readyArray,
	input [ADDRESS_SIZE - 1:0]input_addr,
	
	output [DATA_WIDTH - 1:0]dataOutArray,
    output [OUTPUTS - 1:0]validArray,
    input [OUTPUTS - 1:0]nReadyArray,
	output [ADDRESS_SIZE - 1:0]output_addr
);
	
	assign output_addr = input_addr;
	assign validArray = pValidArray;
	assign readyArray = nReadyArray;
	assign dataOutArray = dataInArray;
	
endmodule

module lsq_store_op
#(
	parameter INPUTS = 32'd1,
	parameter OUTPUTS = 32'd1,
	parameter DATA_WIDTH = 32'd1,
	parameter ADDRESS_SIZE = 32'd1
)
(
	input clk,
    input rstn,
	
	input [DATA_WIDTH - 1:0]dataInArray,
    input [INPUTS - 1:0]pValidArray,
    output [INPUTS - 1:0]readyArray,
	input [ADDRESS_SIZE - 1:0]input_addr,
	
	output [DATA_WIDTH - 1:0]dataOutArray,
    output [OUTPUTS - 1:0]validArray,
    input [OUTPUTS - 1:0]nReadyArray,
	output [ADDRESS_SIZE - 1:0]output_addr
);
	
	assign output_addr = input_addr;
	assign validArray = pValidArray;
	assign readyArray = nReadyArray;
	assign dataOutArray = dataInArray;
	
endmodule

