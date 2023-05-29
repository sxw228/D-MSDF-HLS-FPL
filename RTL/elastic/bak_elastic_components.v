`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/28 11:34:13
// Design Name: 
// Module Name: EB
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


module andN#(
    parameter N	= 32'd4		//number of fan in
)(
    input wire[N-1:0] x,
    output wire res
    );

    wire [N-1:0] dummy;
    genvar i; //genvar i;也可以定义到generate语句里面
    generate
        for(i=0;i<N;i=i+1)
        begin:bit
            assign dummy[i]=1'b1;
        end
    endgenerate
    assign res = (x ==dummy);
endmodule

module nandN#(
    parameter N	= 32'd4		//number of fan in
)(
    input wire[N-1:0] x,
    output wire res
    );

    wire [N-1:0] dummy;
    genvar i; //genvar i;也可以定义到generate语句里面
    generate
        for(i=0;i<N;i=i+1)
        begin:bit
            assign dummy[i]=1'b1;
        end
    endgenerate
    assign res = ~(x ==dummy);
endmodule

module orN#(
    parameter N	= 32'd4		//number of fan in
)(
    input wire[N-1:0] x,
    output wire res
    );

    wire [N-1:0] dummy = 'd0;
    assign res = ~(x ==dummy);
endmodule

module norN#(
    parameter N	= 32'd4		//number of fan in
)(
    input wire[N-1:0] x,
    output wire res
    );

    wire [N-1:0] dummy = 'd0;
    assign res = ~(x ==dummy);
endmodule

module Join#(
    parameter SIZE	= 32'd2		//number of fan in
)(
    input wire [SIZE-1:0]pValidArray,
    output wire valid,
    output wire [SIZE-1:0]readyArray,
    input wire nReady
    );


    wire allPValid;
    
    andN#(.N(SIZE))andN_inst(
        .x(pValidArray),
        .res(allPValid)
    );
    assign valid = allPValid;

    genvar i; //genvar i;也可以定义到generate语句里面
    generate
            for(i=0;i<SIZE;i=i+1)
            begin:bit
                assign readyArray[i]=nReady & pValidArray[i];
            end
    endgenerate
endmodule

module elasticBuffer#(
    parameter DATA_WIDTH	= 8'd1		//数据位宽
)(
    input wire  clk,
    input wire rstn,

    input wire[DATA_WIDTH-1:0] dataInArray,
    input wire pValidArray,
    output wire readyArray,

    output wire [DATA_WIDTH-1:0]dataOutArray,
    output wire validArray,
    input wire nReadyArray
    );

    wire [DATA_WIDTH-1:0]tehb_dataOutArray;
    wire tehb_validArray;
    wire tehb_nReadyArray;




    TEHB#(.DATA_WIDTH(DATA_WIDTH)) tehb_inst(
        .clk(clk),
        .rstn(rstn),
        .dataInArray(dataInArray),
        .pValidArray(pValidArray),
        .readyArray(readyArray),
        .dataOutArray(tehb_dataOutArray),
        .validArray(tehb_validArray),
        .nReadyArray(tehb_nReadyArray)
    );

    OEHB#(.DATA_WIDTH(DATA_WIDTH)) oehb_inst(
        .clk(clk),
        .rstn(rstn),
        .dataInArray(tehb_dataOutArray),
        .pValidArray(tehb_validArray),
        .readyArray(tehb_nReadyArray),
        .dataOutArray(dataOutArray),
        .validArray(validArray),
        .nReadyArray(nReadyArray)
    );


endmodule

module TEHB#(
    parameter DATA_WIDTH	= 8'd1		//数据位宽
)(
    input wire  clk,
    input wire rstn,

    input wire[DATA_WIDTH-1:0] dataInArray,
    input wire pValidArray,
    output wire readyArray,

    output wire [DATA_WIDTH-1:0]dataOutArray,
    output wire validArray,
    input wire nReadyArray
    );


    wire reg_en;
    wire mux_sel;
    wire full_reg;
    wire [DATA_WIDTH-1:0] data_reg;


    assign mux_sel = full_reg;
    assign reg_en = readyArray & (~nReadyArray) & pValidArray;
    assign dataOutArray = mux_sel? data_reg : dataInArray;
    assign validArray = pValidArray | full_reg;
    assign readyArray = ~full_reg;


    D_FF #(1,0)D_FF1_Inst0(clk,rstn,1'b0,1'b0,1'b1,(validArray)&(~nReadyArray),full_reg);
    D_FF #(DATA_WIDTH,0)D_FF1_Inst1(clk,rstn,1'b0,1'b0,reg_en,dataInArray,data_reg);

endmodule


module OEHB#(
    parameter DATA_WIDTH	= 8'd1		//数据位宽
)(
    input wire  clk,
    input wire rstn,

    input wire[DATA_WIDTH-1:0] dataInArray,
    input wire pValidArray,
    output wire readyArray,

    output wire [DATA_WIDTH-1:0]dataOutArray,
    output wire validArray,
    input wire nReadyArray
    );


    wire  reg_en;
    wire [DATA_WIDTH-1:0] data_reg;


    assign readyArray = ~validArray | nReadyArray;
    assign reg_en = readyArray & pValidArray;
    assign dataOutArray = data_reg;


    D_FF #(1,0)D_FF1_Inst0(clk,rstn,1'b0,1'b0,1'b1,(pValidArray)|(~readyArray),validArray);
    D_FF #(DATA_WIDTH,0)D_FF1_Inst1(clk,rstn,1'b0,1'b0,reg_en,dataInArray,data_reg);
       
endmodule

// module end_node#(
//     parameter INPUTS	   = 32'd1,		            //number of fan in
//     parameter OUTPUTS      = 32'd1,                     //number of fan out
//     parameter DATA_SIZE_IN = 32'd8,
//     parameter DATA_SIZE_OUT= 32'd8
//     )(
//         input wire  clk,
//         input wire rstn,

//         input wire[DATA_SIZE_IN-1:0] dataInArray,
//         input wire pValidArray,
//         output wire readyArray,

//         output wire [DATA_SIZE_OUT-1:0]dataOutArray,
//         output wire validArray,
//         input wire nReadyArray
//     )

// endmodule

module branchSimple(
    input wire condition,
    input wire pValid,
    input wire [1:0] nReadyArray,
    output wire [1:0] validArray,
    output ready
);
    assign validArray[1] = (~condition) & pValid;
    assign validArray[0] = condition & pValid;
    assign ready = ((nReadyArray[1])&(~condition)) | ((nReadyArray[0])&(condition));
endmodule

module branch#(
    parameter INPUTS	= 8'd1,		//数据位宽
    parameter DATA_SIZE_IN = 32'd8,
    parameter DATA_SIZE_OUT = 32'd8
)(
    input wire  clk,
    input wire rstn,

    input wire condition,
    input wire[DATA_SIZE_IN-1:0] dataInArray,
    input wire [1:0]pValidArray,
    output wire [1:0]readyArray,

    output wire [DATA_SIZE_OUT-1:0]dataOutArray,
    output wire [1:0]validArray,
    input wire [1:0]nReadyArray
    );


    wire  joinValid,branchReady;

    Join #(.SIZE(2)) Join_inst(
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
    input wire clk,
    input wire rstn,
    input wire p_valid,
    input wire n_stop,
    input wire p_valid_and_fork_stop,
    output wire valid,
    output wire block_stop
);
    reg reg_value;
    wire reg_in,block_stop_internal;

    assign block_stop_internal = n_stop & reg_value;
    assign block_stop = block_stop_internal;
    assign reg_in = block_stop_internal | (~ p_valid_and_fork_stop);
    assign valid = reg_value & p_valid;

    always @(posedge clk) begin
        if(~rstn)
            reg_value <= 1'b1;
        else
            reg_value <= reg_in;        
    end
endmodule

module Fork#(
    parameter INPUTS	= 8'd1,		//数据位宽
    parameter SIZE = 8'd1,
    parameter DATA_SIZE_IN = 32'd8,
    parameter DATA_SIZE_OUT = 32'd8
)(
    input wire  clk,
    input wire rstn,


    input wire[DATA_SIZE_IN-1:0] dataInArray,
    input wire pValidArray,
    output wire readyArray,

    output wire [SIZE*DATA_SIZE_OUT-1:0]dataOutArray,
    output wire [SIZE-1:0]validArray,
    input wire [SIZE:0]nReadyArray
    );


    wire forkStop;
    wire [SIZE-1:0]nStopArray;
    wire [SIZE-1:0]blockStopArray;
    wire anyBlockStop;
    wire pValidAndForkStop;

    assign readyArray = ~forkStop;
    assign nStopArray[SIZE-1:0] = ~nReadyArray[SIZE-1:0];

    orN#(.N(SIZE)) orN_inst(
        .x(blockStopArray),
        .res(anyBlockStop)
    );       
    //internal combinatorial signals
    assign forkStop = anyBlockStop;
    assign pValidAndForkStop = pValidArray & forkStop;
    //generate blocks
    genvar i;
    generate
    for (i = 0; i < SIZE ; i = i + 1) begin: 
        eagerFork_RegisterBlock eagerFork_RegisterBlock_inst(
            .clk(clk),
            .rstn(rstn),
            .pValidArray(pValidArray),
            .nStopArray(nStopArray[i]),
            .pValidAndForkStop(pValidAndForkStop),
            .validArray(validArray[i]),
            .blockStopArray(blockStopArray[i])
        );
        assign dataOutArray[(i+1)*DATA_SIZE_OUT-1:i*DATA_SIZE_OUT] = dataInArray[DATA_SIZE_IN-1:0];
    end
    endgenerate

endmodule

module sink#(
    parameter INPUT_COUNT	= 32'd1,		            //number of fan in
    parameter OUTPUT_COUNT = 32'd1,                     //number of fan out
    parameter DATA_SIZE_IN = 32'd8,
    parameter DATA_SIZE_OUT = 32'd8
)(
    input wire  clk,
    input wire rstn,

    input wire[DATA_SIZE_IN-1:0] dataInArray,
    input wire pValidArray,
    output wire readyArray
    );

    assign readyArray = 1'b1;
       
endmodule
module source#(
    parameter INPUT_COUNT	= 32'd1,		            //number of fan in
    parameter OUTPUT_COUNT = 32'd1,                     //number of fan out
    parameter DATA_SIZE_IN = 32'd8,
    parameter DATA_SIZE_OUT = 32'd8
)(
    input wire  clk,
    input wire rstn,


    output wire [DATA_SIZE_OUT-1:0]dataOutArray,
    output wire validArray,
    input wire nReadyArray
    );

    assign validArray = 1'b1;
       
endmodule

module load_op#(
    parameter INPUTS	= 32'd1,		            //number of fan in
    parameter OUTPUTS = 32'd1,                     //number of fan out
    parameter ADDRESS_SIZE = 32'd8,
    parameter DATA_SIZE = 32'd8
)(
    input wire  clk,
    input wire rstn,

    input wire[DATA_SIZE-1:0] dataInArray,
    input wire pValidArray,
    output wire readyArray,

    output wire [DATA_SIZE-1:0]dataOutArray,
    output reg validArray,
    input wire nReadyArray,

    output wire read_enable,
    output wire [ADDRESS_SIZE-1:0]read_address,
    input wire [32-1:0] data_from_memory
    );

    wire temp,tempen;
    wire q0,q1,enable_internal;
    wire [ADDRESS_SIZE-1:0]read_address_internal;
    wire valid_temp;

    assign read_enable = valid_temp & nReadyArray;
    assign enable_internal = valid_temp & nReadyArray;
    assign dataOutArray = data_from_memory;

    elasticBuffer #(.DATA_WIDTH(ADDRESS_SIZE)
    ) elasticBuffer_inst(
        .clk(clk),
        .rstn(rstn),

        .dataInArray(dataInArray),
        .pValidArray(pValidArray),
        .readyArray(readyArray),

        .dataOutArray(read_address_internal),
        .validArray(valid_temp),
        .nReadyArray(nReadyArray)
    );
    assign read_address = read_address_internal;

    always @(posedge clk) begin
        if(~rstn)
            validArray <= 1'b0;
        else if (enable_internal)
            validArray <= 1'b1;
        else if (nReadyArray)
            validArray <= 1'b0;
    end

endmodule


module write_momory_single_inside#(
    parameter ADDRESS_SIZE = 32'd8,
    parameter DATA_SIZE = 32'd8
)(
    input wire  clk,


    input wire dataValid,
    output wire ready,

    input wire [ADDRESS_SIZE-1:0] input_addr,
    input wire [DATA_SIZE-1:0] data,

    input wire nReady,
    output reg valid,

    output reg write_enable,
    output reg enable,

    output reg [ADDRESS_SIZE-1:0] write_address,
    output reg [DATA_SIZE-1:0] data_to_memory
    );


    always @(posedge clk) begin
        write_address <= input_addr;
        data_to_memory <= data;
        valid <= dataValid;
        write_enable <= dataValid & nReady;
        enable <= dataValid & nReady;
    end

    assign ready = nReady;



endmodule


module store_op#(
    parameter INPUTS	= 32'd1,		            //number of fan in
    parameter OUTPUTS = 32'd1,                     //number of fan out
    parameter ADDRESS_SIZE = 32'd8,
    parameter DATA_SIZE = 32'd8
)(
    input wire  clk,
    input wire rstn,

    wire [ADDRESS_SIZE-1:0] input_addr,
    input wire[DATA_SIZE-1:0] dataInArray,

    input wire pValidArray,
    output wire readyArray,

    output wire [DATA_SIZE-1:0]dataOutArray,
    output reg validArray,
    input wire nReadyArray,

    output wire write_enable,
    output wire enable,
    output wire [ADDRESS_SIZE-1:0]write_address,
    output wire [32-1:0] data_to_memory
    );

    wire single_ready,join_valid;

    Join #(.SIZE(2)) Join_inst(
        .pValidArray(pValidArray),
        .valid(join_valid),
        .readyArray(readyArray),
        .nReady(single_ready)
    );

    write_momory_single_inside #(
        .ADDRESS_SIZE(ADDRESS_SIZE),
        .DATA_SIZE(DATA_SIZE))
        write_momory_single_inside_inst(
            .clk(clk),
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

module start_node#(
    parameter INPUT_COUNT = 32'd1,
    parameter OUTPUT_COUNT = 32'd1,
    parameter DATA_SIZE_IN = 32'd8,
    parameter DATA_SIZE_OUT = 32'd8
)(
    input wire  clk,
    input wire rstn,


    input wire[DATA_SIZE_IN-1:0] dataInArray,
    input wire pValidArray,
    output wire readyArray,

    output wire [DATA_SIZE_OUT-1:0]dataOutArray,
    output wire validArray,
    input wire nReadyArray
);

    reg set;
    reg start_internal;
    wire startBuff_readArray;
    wire startBuff_validArray;
    wire [DATA_SIZE_IN-1:0]startBuff_dataOutArray;

    always @(posedge clk ) begin
        if(~rstn) begin
            start_internal <= 1'b0;
            set <= 1'b0;
        end
        else if(pValidArray & (~set))begin
            start_internal <= 1'b1;
            set <= 1'b1;
        end
        else begin
            start_internal <= 1'b0;
            set <= set;
        end
    end

    elasticBuffer#(
        .DATA_WIDTH(DATA_SIZE_IN)
    )(
        .clk(clk),
        .rstn(rstn),
        .dataInArray(dataInArray),
        .pValidArray(start_internal),
        .readyArray(startBuff_readArray),

        .dataOutArray(startBuff_dataOutArray),
        .validArray(startBuff_validArray),
        .nReadyArray(nReadyArray)
    );
    assign validArray = startBuff_validArray;
    assign dataOutArray = startBuff_dataOutArray;
    assign readyArray = startBuff_readArray;
endmodule

module Const#(
    parameter SIZE = 32'd1,
    parameter INPUTS = 32'd1,
    parameter DATA_SIZE_IN = 32'd8,
    parameter DATA_SIZE_OUT = 32'd8
)(
    input wire  clk,
    input wire rstn,


    input wire[DATA_SIZE_IN-1:0] dataInArray,
    input wire pValidArray,
    output wire readyArray,

    output wire [DATA_SIZE_OUT-1:0]dataOutArray,
    output wire validArray,
    input wire nReadyArray
);

    assign dataOutArray = dataInArray;
    assign readyArray = nReadyArray;
    assign validArray = pValidArray;
endmodule

module merge_notehb#(
    parameter INPUTS = 32'd1,
    parameter OUTPUTS = 32'd1,
    parameter DATA_SIZE_IN = 32'd8,
    parameter DATA_SIZE_OUT = 32'd8
)(
    input wire  clk,
    input wire rstn,


    input wire[INPUTS*DATA_SIZE_IN-1:0] dataInArray,
    input wire [INPUTS-1:0]pValidArray,
    output wire [INPUTS-1:0]readyArray,

    output wire [DATA_SIZE_OUT-1:0]dataOutArray,
    output wire validArray,
    input wire nReadyArray
);



    wire [DATA_SIZE_IN-1:0]tehb_data_in;
    wire tehb_pvalid;
    wire tehb_ready;


    generate if(INPUTS == 2)begin:gen_merge2
        assign tehb_data_in = pValidArray[1]? dataInArray[2*DATA_SIZE_IN-1:DATA_SIZE_IN] : dataInArray[DATA_SIZE_IN-1:0];
        assign tehb_pvalid = pValidArray[1]? pValidArray[1] : pValidArray[0]? pValidArray[0] :1'b0;
        assign readyArray = {tehb_ready,tehb_ready};
    end else if (INPUTS == 3)begin:gen_merge3
        assign tehb_data_in = pValidArray[2]? dataInArray[3*DATA_SIZE_IN-1:2*DATA_SIZE_IN] : pValidArray[1]? dataInArray[2*DATA_SIZE_IN-1:DATA_SIZE_IN] : dataInArray[DATA_SIZE_IN-1:0];
        assign tehb_pvalid = pValidArray[2]? pValidArray[2] : pValidArray[1]? pValidArray[1] : pValidArray[0]? pValidArray[0] : 1'b0;
        assign readyArray = {tehb_ready,tehb_ready,tehb_ready};
    end else begin
        assign tehb_data_in = dataInArray[DATA_SIZE_IN-1:0];
        assign tehb_pvalid = 1'b0;
        assign readyArray = {tehb_ready};
    end
    endgenerate
 
    assign tehb_ready = nReadyArray;
    assign validArray = tehb_pvalid;
    assign dataOutArray = tehb_data_in;



endmodule

module cntrlMerge#(
    parameter INPUTS = 32'd1,
    parameter OUTPUTS = 32'd1,
    parameter DATA_SIZE_IN = 32'd8,
    parameter DATA_SIZE_OUT = 32'd8,
    parameter COND_SIZE = 32'd8
)(
    input wire  clk,
    input wire rstn,


    input wire[INPUTS*DATA_SIZE_IN-1:0] dataInArray,
    input wire [1:0]pValidArray,
    output wire [1:0]readyArray,

    output wire [DATA_SIZE_OUT-1:0]dataOutArray,
    output wire [1:0]validArray,
    input wire [1:0]nReadyArray,

    output wire condition
);

    wire [1:0] phi_C1_readyArray;
    wire phi_C1_validArray;
    wire phi_C1_dataOutArray;
    
    wire fork_C1_readyArray;
    wire [1:0]fork_C1_dataOutArray;
    wire [1:0]fork_C1_validArray;

    wire oehb1_valid,oehb1_ready,index;
    wire [DATA_SIZE_IN-1:0]oehb1_dataOut;

    assign readyArray = phi_C1_readyArray;

    merge_notehb #(
        .INPUTS(2),
        .OUTPUTS(1),
        .DATA_SIZE_IN(1),
        .DATA_SIZE_OUT(1)
    )phiC1(
        .clk(clk),
        .rstn(rstn),
        .pValidArray(pValidArray),
        .dataInArray(2'b11),
        .nReadyArray(oehb1_ready),
        .dataOutArray(phi_C1_dataOutArray),
        .readyArray(phi_C1_readyArray),
        .validArray(phi_C1_validArray)
    );

    assign index = ~pValidArray;

    TEHB#(.DATA_WIDTH(1)) tehb_inst(
        .clk(clk),
        .rstn(rstn),
        .dataInArray(index),
        .pValidArray(phi_C1_validArray),
        .readyArray(oehb1_ready),
        .dataOutArray(oehb1_dataOut),
        .validArray(oehb1_valid),
        .nReadyArray(fork_C1_readyArray)
    );

    Fork #(
        .INPUTS(1),
        .SIZE(2),
        .DATA_SIZE_IN(1), 
        .DATA_SIZE_OUT(1)
    ) fork_inst(
        .clk(clk),
        .rstn(rstn),
        .dataInArray(1'b1),
        .pValidArray(oehb1_valid),
        .readyArray(fork_C1_readyArray),

        .dataOutArray(fork_C1_dataOutArray),
        .validArray(fork_C1_validArray),
        .nReadyArray(nReadyArray)
    );

    assign validArray = fork_C1_validArray;
    assign condition = oehb1_dataOut;
endmodule

module mux_top#(
    parameter INPUTS	= 8'd1,	
    parameter OUTPUTS	= 8'd1,	
    parameter DATA_SIZE_IN = 32'd8,
    parameter DATA_SIZE_OUT = 32'd8,
    parameter COND_SIZE = 32'd8
)(
    input wire  clk,
    input wire rstn,

    input wire [COND_SIZE-1:0]condition,
    input wire[DATA_SIZE_IN*(INPUTS-1)-1:0] dataInArray,
    input wire [INPUTS-1:0]pValidArray,
    output wire [INPUTS-1:0]readyArray,

    output wire [DATA_SIZE_OUT-1:0]dataOutArray,
    output wire validArray,
    input wire nReadyArray
    );

  
endmodule