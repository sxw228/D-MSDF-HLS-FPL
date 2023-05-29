`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/01 18:10:36
// Design Name: 
// Module Name: msdf_worker
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
`include "define.vh"

module msdf_worker
(
    input wire clk,
    input wire rst,


    input wire [`NUM_BITS_PER_BANK*3-1:0]dataInArray_0,
    input wire pValidArray_0,
    output wire readyArray_0,

    output wire [2:0]dataOutArray_0,
    output wire validArray_0,
    input wire nReadyArray_0
    );

    localparam STATE_IDLE = 0;
    localparam STATE_PRE_READ = 1;
    localparam STATE_WAIT_A =2;
    localparam STATE_FILL_X = 3;
    localparam STATE_FINISH = 4;

    reg[7:0]worker_state;   //模块状态
    reg [`WIDTH_BIT_INDEX-1:0]a_index;       //对有效输入的计数
    

    /* 输出接个fifo */
    wire [2:0]transpFifo_0_dataInArray;
    wire transpFifo_0_pValidArray;
    wire transpFifo_0_readyArray;
    wire [2:0]transpFifo_0_dataOutArray;
    wire transpFifo_0_validArray;
    wire transpFifo_0_nReadyArray;

    /* 读写bram */
    wire mem_x_wea;
    wire [8:0]mem_x_addra;
    wire [191:0]mem_x_dina;
    wire [191:0]mem_x_douta;
    reg [191:0]mem_x_douta_delay;

    /* worker的计算电路 */
    wire [`NUM_BITS_PER_BANK*3-1:0]dot_dataInArray_0;
    wire [`NUM_BITS_PER_BANK*3-1:0]dot_dataInArray_1;
    wire dot_pValidArray_0;
    wire dot_pValidArray_1;
    wire dot_readyArray_0;
    wire dot_readyArray_1;

    wire [2:0]dot_dataOutArray_0;
    wire dot_validArray_0;
    wire dot_nReadyArray_0;

    /* 一个EHB */
    reg [`NUM_BITS_PER_BANK*3-1:0]EHB_dataInArray;
    reg EHB_pValidArray;
    wire EHB_readyArray;
    wire [`NUM_BITS_PER_BANK*3-1:0]EHB_dataOutArray;
    wire EHB_validArray;
    wire EHB_nReadyArray;


    /* 调试信号,很关键,现在数据没法看了,就看last信号,和握手信号 */
    wire dbg_dataInArray_0_last = dataInArray_0[3*`NUM_BITS_PER_BANK-1];
    wire dbg_pValidArray_0 = pValidArray_0;
    wire dbg_readyArray_0 = readyArray_0;

    wire dbg_EHB_dataInArray_last = EHB_dataInArray[`NUM_BITS_PER_BANK*3-1];
    wire dbg_EHB_pValidArray = EHB_pValidArray;
    wire dbg_EHB_readyArray = EHB_readyArray;

    wire dbg_dot_dataInArray_0_last = dot_dataInArray_0[`NUM_BITS_PER_BANK*3-1];
    wire dbg_dot_pValidArray_0 = dot_pValidArray_0;
    wire dbg_dot_readyArray_0 = dot_readyArray_0;

    wire dbg_dot_dataInArray_1_last = dot_dataInArray_1[`NUM_BITS_PER_BANK*3-1];
    wire dbg_dot_pValidArray_1 = dot_pValidArray_1;
    wire dbg_dot_readyArray_1 = dot_readyArray_1;

    wire dbg_dot_dataOutArray_0_last = dot_dataOutArray_0[2];
    wire dbg_dot_validArray_0 = dot_validArray_0;
    wire dbg_dot_nReadyArray_0 = dot_nReadyArray_0;

    wire dbg_transpFifo_0_dataInArray_last = transpFifo_0_dataInArray[2];
    wire dbg_transpFifo_0_pValidArray = transpFifo_0_pValidArray;
    wire dbg_transpFifo_0_readyArray = transpFifo_0_readyArray;

    wire dbg_dataOutArray_0 = dataOutArray_0[2];
    wire dbg_validArray_0 = validArray_0;
    wire dbg_nReadyArray_0 = nReadyArray_0;

    /* 连线线 */
    
    wire good_transfer = pValidArray_0 & EHB_readyArray;

    /* fifo输出 */
    assign dataOutArray_0 = transpFifo_0_dataOutArray;
    assign validArray_0 = transpFifo_0_validArray;
    assign transpFifo_0_nReadyArray = nReadyArray_0;

    /* dot输出 */
    assign transpFifo_0_dataInArray = dot_dataOutArray_0;
    assign transpFifo_0_pValidArray = dot_validArray_0;
    assign dot_nReadyArray_0 = transpFifo_0_readyArray;

    /* dot输入,操作数0,也是EHB的输出 */
    assign dot_dataInArray_0 = EHB_dataOutArray;
    assign dot_pValidArray_0 = EHB_validArray;
    assign EHB_nReadyArray = dot_readyArray_0;

    
    /* EHB的输入 */

    always @(posedge clk) begin
        if(rst)begin
            EHB_pValidArray <= 'd0;
            EHB_dataInArray <= 'd0;
        end
        else begin
            case (worker_state)
                STATE_PRE_READ  : begin
                    if(EHB_readyArray)begin
                        EHB_pValidArray <= 'd1;
                        EHB_dataInArray <= 'd0;
                    end
                    else begin
                        EHB_pValidArray <= 'd0;
                        EHB_dataInArray <= 'd0;
                    end
                end
                STATE_WAIT_A  : begin
                    if(good_transfer)begin
                        EHB_pValidArray <= 'd1;
                        EHB_dataInArray <= dataInArray_0;
                    end
                    else begin
                        EHB_pValidArray <= 'd0;
                        EHB_dataInArray <= EHB_dataInArray;
                    end
                end
                STATE_FILL_X: begin
                    if(EHB_readyArray)begin
                        EHB_pValidArray <= 'd1;
                        if(a_index == 'd24)begin
                            EHB_dataInArray <= 'd4;
                        end
                        else begin
                            EHB_dataInArray <= 'd0;
                        end         
                    end
                    else begin
                        EHB_pValidArray <= 'd0;
                    end
                             
                end
                STATE_FINISH: begin
                    EHB_pValidArray <= 'd0;
                    EHB_dataInArray <= 'd0;
                end
                STATE_IDLE: begin
                    EHB_pValidArray <= 'd0;
                    EHB_dataInArray <= 'd0;
                end
                default: begin
                end
            endcase  
        end
    end
    /* dot输入,操作数1 */
    assign dot_dataInArray_1 = mem_x_douta_delay[191:0];
    assign dot_pValidArray_1 = dot_pValidArray_0;
    
    /* bram读写 */
    assign mem_x_addra = a_index;
    assign mem_x_wea = 'b0;
    assign mem_x_dina = 'd0;

    /* 模块输入 */
    assign readyArray_0 = worker_state == STATE_WAIT_A & EHB_readyArray;
    
    /* 状态转移 */
    always @(posedge clk) begin
        if(rst)begin
            worker_state <= STATE_IDLE;
        end
        else begin
            case (worker_state)
                 STATE_IDLE  : begin
                        worker_state <= STATE_PRE_READ;
                end
                STATE_PRE_READ  : begin
                    if(a_index=='d4)begin
                        worker_state <= STATE_WAIT_A;
                    end
                end
                STATE_WAIT_A  : begin
                    if(a_index=='d7)begin
                        worker_state <= STATE_FILL_X;
                    end
                end
                STATE_FILL_X: begin
                    if(a_index=='d24)begin
                        worker_state <= STATE_FINISH;
                    end
                end
                STATE_FINISH: begin
                    worker_state <= STATE_PRE_READ;
                end
                default: begin
                
                end
            endcase  
        end
    end

    /* 输入计数 */
    always @(posedge clk) begin
        if(rst)begin
            a_index <= 'd0;
        end
        else begin
            case (worker_state)
                STATE_PRE_READ  : begin
                    if(EHB_readyArray)begin
                        a_index <= a_index+1;
                    end
                end
                STATE_WAIT_A  : begin
                    if(good_transfer)begin
                        a_index <= a_index+1;
                    end
                end
                STATE_FILL_X: begin
                    if(EHB_readyArray)begin
                        a_index <= a_index+1;
                    end
                end
                STATE_FINISH: begin
                    a_index <= 'd0;
                end
                default: begin
            
                end
            endcase  
        end
    end

    /* 要有一个bram */
    blk_mem_gen_0 mem_x_inst (
        .clka(clk),    // input wire clka
        .wea(mem_x_wea),      // input wire [0 : 0] wea
        .addra(mem_x_addra),  // input wire [8 : 0] addra
        .dina(mem_x_dina),    // input wire [191 : 0] dina
        .douta(mem_x_douta)  // output wire [191 : 0] douta
    );

    always @(posedge clk) begin
        mem_x_douta_delay <= mem_x_douta;
    end

    OEHB#(.DATA_WIDTH(3*`NUM_BITS_PER_BANK))
	OEHB_inst(
        .clk(clk),
        .rstn(~rst),
        .dataInArray(EHB_dataInArray),
        .pValidArray(EHB_pValidArray),
        .readyArray(EHB_readyArray),
        .dataOutArray(EHB_dataOutArray),
        .validArray(EHB_validArray),
        .nReadyArray(EHB_nReadyArray)
    );
    
    msdf_dot
    #(
        .TARGET_PRECISION(32),
        .TREE_DEPTH(6),
        .TREE_WIDTH(2**6)
    )
    msdf_dot_0
    (
        .clk(clk),
        .rst(rst),

        .dataInArray_0(dot_dataInArray_0),
        .dataInArray_1(dot_dataInArray_1),
        .pValidArray_0(dot_pValidArray_0),
        .pValidArray_1(dot_pValidArray_1),
        .readyArray_0(dot_readyArray_0),
        .readyArray_1(dot_readyArray_1),

        .dataOutArray_0(dot_dataOutArray_0),
        .validArray_0(dot_validArray_0),
        .nReadyArray_0(dot_nReadyArray_0)
    );

    transpFIFO#(.DATA_WIDTH(3),.FIFO_DEPTH(15))
    transpFifo_0(
        .clk(clk),
        .rstn(~rst),

        .dataInArray(transpFifo_0_dataInArray),
        .pValidArray(transpFifo_0_pValidArray),
        .readyArray(transpFifo_0_readyArray),

        .dataOutArray(transpFifo_0_dataOutArray),
        .validArray(transpFifo_0_validArray),
        .nReadyArray(transpFifo_0_nReadyArray)

    );

endmodule
