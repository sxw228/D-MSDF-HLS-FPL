`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/29 20:50:55
// Design Name: 
// Module Name: msdf_dot_group
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

module msdf_dot_group(
    input wire clk,
    input wire rst,

    input wire [3*`NUM_BITS_PER_BANK-1:0] dataInArray_0,
    input wire pValidArray_0,
    output wire readyArray_0,


    output wire [2:0]dataOutArray_0,
    output wire validArray_0,
    input wire nReadyArray_0
    );

    localparam STATE_IDLE = 8'd0;               //复位后进这个状态,下一拍进STARTING
    localparam STATE_STARTING = 8'd1;           //下一个进STATE_EPOCH
    localparam STATE_EPOCH = 8'd2;              //下一个进STATE_EPOCH_SAMPLE
    localparam STATE_EPOCH_SAMPLE = 8'd3;       //下一个进STATE_SAMPLE
    localparam STATE_SAMPLE = 8'd4;             //下一个STATE_A_COMPUTING
    localparam STATE_A_COMPUTING = 8'd5;
    localparam STATE_WORER_CHECH = 8'd6;

    

    reg [7:0]state_group;                      //group主状态机
    reg msdf_ready;                            //下一级的反压
    wire good_input_transfer;                   //指示一次有效传输
    assign good_input_transfer = pValidArray_0 & msdf_ready;    //有效传输的式子

    reg [`WIDTH_BIT_INDEX-1:0]good_transfer_cnt;
    reg [`WIDTH_BIT_INDEX-1:0]a_bit_index;               //串行输入a的bit索引,a的长度是ka-SHF-1
    reg [`WIDTH_BIT_INDEX-1:0]worker_index;
    reg [`WIDTH_BIT_INDEX-1:0]chunk_index;            //一个样本内不同轮次的索引
    reg [`WIDTH_BIT_INDEX-1:0]sample_index;
    reg [`WIDTH_BIT_INDEX-1:0]batch_index;
    reg [`NUM_WORKERS-1:0]worker_select;                //选择把计算交个哪个worker来做


    /* 状态转移 */
    always @(posedge clk) begin
        if(rst)begin
            state_group <= STATE_IDLE;
        end
        else begin
            case (state_group)
                STATE_IDLE  : begin
                state_group <= STATE_A_COMPUTING;
                end
                STATE_A_COMPUTING  : begin
                    // if(good_input_transfer && a_bit_index=='d2 && worker_index=='d1)begin
                    //     state_group <= STATE_WORER_CHECH;
                    // end
                end
                // STATE_WORER_CHECH: begin
                    
                // end
                default: begin
                //<statement>;
                end
            endcase  
        end
    end

    /* 对index的控制 */
    always @(posedge clk) begin
        if(rst)begin
            good_transfer_cnt <= 'd0;
            a_bit_index <= 'd0;
            worker_index <= 'd0;
            
            chunk_index <= 'd0;
            sample_index <= 'd0;
            batch_index <= 'd0;

            worker_select <= 'd1;
        end
        else if(state_group == STATE_A_COMPUTING)begin
            if(good_input_transfer)begin
                good_transfer_cnt <= good_transfer_cnt+1;
                if(a_bit_index == 'd2)begin
                    a_bit_index <= 'd0;
                    if(worker_index == 'd3)begin
                        worker_index <= 'd0;
                        if(chunk_index == 'd1)begin
                            chunk_index <= 'd0;
                            if(sample_index == 'd8)begin
                                sample_index <= 'd0;
                            end
                            else begin
                                sample_index <= sample_index+1;
                            end
                        end
                        else begin
                            chunk_index <= chunk_index+1;
                        end
                    end
                    else begin
                        worker_index <= worker_index+1;
                    end
                    worker_select <= {worker_select[`NUM_WORKERS-2:0],worker_select[`NUM_WORKERS-1]};
                end
                else begin
                    a_bit_index <= a_bit_index+1;
                    worker_index <= worker_index;
                    worker_select <= worker_select;
                end
            end
        end
    end

    /* 把a送进移位寄存器,先进来的放在高Bit */
    reg [`WIDTH_A_BUFFER-1:0]a_buffer_2;
    reg [`WIDTH_A_BUFFER-1:0]a_buffer_1;
    reg [`WIDTH_A_BUFFER-1:0]a_buffer_0;
    wire [`NUM_BITS_PER_BANK-1:0]a_tmp_2;
    wire [`NUM_BITS_PER_BANK-1:0]a_tmp_1;
    wire [`NUM_BITS_PER_BANK-1:0]a_tmp_0;
    genvar index_c;
    generate
        for( index_c = 0; index_c < `NUM_BITS_PER_BANK; index_c = index_c + 1) begin: loop_of_INDEX_C
            assign a_tmp_2[index_c] = dataInArray_0[index_c*3+2];
            assign a_tmp_1[index_c] = dataInArray_0[index_c*3+1];
            assign a_tmp_0[index_c] = dataInArray_0[index_c*3+0];
        end
    endgenerate

    always @(posedge clk) begin
        if(good_input_transfer)begin
            a_buffer_2[`WIDTH_A_BUFFER-1:0] <= {a_buffer_2[`WIDTH_A_BUFFER-`NUM_BITS_PER_BANK-1:0],a_tmp_2};
            a_buffer_1[`WIDTH_A_BUFFER-1:0] <= {a_buffer_1[`WIDTH_A_BUFFER-`NUM_BITS_PER_BANK-1:0],a_tmp_1};
            a_buffer_0[`WIDTH_A_BUFFER-1:0] <= {a_buffer_0[`WIDTH_A_BUFFER-`NUM_BITS_PER_BANK-1:0],a_tmp_0};
        end
    end


    /* worker的控制信号 */
    reg [`NUM_WORKERS-1:0]worker_pValid;
    wire [`NUM_WORKERS-1:0]worker_ready;
    wire [`NUM_WORKERS-1:0]worker_valid;
    wire [`NUM_WORKERS-1:0]worker_nReady;

    /* work的数据信号,包括送进去的数据和出来的结果 */
    wire [`NUM_BITS_PER_BANK*3-1:0]worker_dataInArray_0;
    wire [`NUM_WORKERS*3-1:0]worker_dataOutArray_0;

    /* 把worker求和 */
    wire [`NUM_WORKERS*3-1:0]sum_dataInArray_0;
    wire [`NUM_WORKERS-1:0]sum_pValidArray_0;
    wire [`NUM_WORKERS-1:0]sum_readyArray_0;
    wire [2:0]sum_dataOutArray_0;
    wire sum_validArray_0;
    wire sum_nReadyArray_0;

    /* 调试信号,很关键,现在数据没法看了,就看last信号,和握手信号 */
    wire dbg_dataInArray_0_last = dataInArray_0[3*`NUM_BITS_PER_BANK-1];
    wire dbg_pValidArray_0 = pValidArray_0;
    wire dbg_readyArray_0 = readyArray_0;

    wire dbg_sum_dataInArray_0_last = sum_dataInArray_0[`NUM_WORKERS*3-1];
    wire dbg_sum_pValidArray_0 = sum_pValidArray_0;
    wire dbg_sum_readyArray_0 = sum_readyArray_0;


    wire dbg_dataOutArray_0 = dataOutArray_0[2];
    wire dbg_validArray_0 = validArray_0;
    wire dbg_nReadyArray_0 = nReadyArray_0;

    // wire [2:0]msdf_cst_b_dataInArray_0;
    // wire msdf_cst_b_pValidArray_0;
    // wire msdf_cst_b_readyArray_0;
    // wire [2:0]msdf_cst_b_dataOutArray_0;
    // wire msdf_cst_b_validArray_0;
    // wire msdf_cst_b_nReadyArray_0;

    // wire [2:0]msdf_error_0_dataInArray_0;
    // wire msdf_error_0_pValidArray_0;
    // wire msdf_error_0_readyArray_0;
    // wire [2:0]msdf_error_0_dataInArray_1;
    // wire msdf_error_0_pValidArray_1;
    // wire msdf_error_0_readyArray_1;
    // wire [2:0]msdf_error_0_dataOutArray_0;
    // wire msdf_error_0_validArray_0;
    // wire msdf_error_0_nReadyArray_0;


    // wire [2:0]msdf_gradient_0_dataInArray_0;
    // wire msdf_gradient_0_pValidArray_0;
    // wire msdf_gradient_0_readyArray_0;
    // wire [`NUM_GRADIENT*3-1:0]msdf_gradient_0_dataOutArray_0;
    // wire msdf_gradient_0_validArray_0;
    // wire msdf_gradient_0_nReadyArray_0;

    /* 连线线 */

    assign dataOutArray_0 = sum_dataOutArray_0[2:0];
    assign validArray_0 = sum_validArray_0;
    assign sum_nReadyArray_0 = nReadyArray_0;

    // /* error的输出->gradient的输入 */

    // assign msdf_gradient_0_dataInArray_0 = msdf_error_0_dataOutArray_0;
    // assign msdf_gradient_0_pValidArray_0 = msdf_error_0_validArray_0;
    // assign msdf_error_0_nReadyArray_0 = msdf_gradient_0_readyArray_0;

    // /* sum的输出->error的输入 */
    

    // assign msdf_cst_b_dataInArray_0 = sum_dataOutArray_0;
    // assign msdf_cst_b_pValidArray_0 = sum_validArray_0;

    // assign msdf_error_0_dataInArray_0 = sum_dataOutArray_0;
    // assign msdf_error_0_pValidArray_0 = sum_validArray_0;
    // assign sum_nReadyArray_0 = msdf_error_0_readyArray_0;

    // assign msdf_error_0_dataInArray_1 = msdf_cst_b_dataOutArray_0;
    // assign msdf_error_0_pValidArray_1 = msdf_cst_b_validArray_0;
    // assign msdf_cst_b_nReadyArray_0 = msdf_error_0_readyArray_1;

    /* worker的输出->sum的输入 */
    assign sum_dataInArray_0 = worker_dataOutArray_0;
    assign sum_pValidArray_0 = worker_valid;
    assign worker_nReady = sum_readyArray_0;


    /* worker的输入 */
    assign worker_dataInArray_0 = dataInArray_0;
    always @(worker_select, worker_ready)
    case (worker_select)
        4'b0001: msdf_ready = worker_ready[0];
        4'b0010: msdf_ready = worker_ready[1];
        4'b0100: msdf_ready = worker_ready[2];
        4'b1000: msdf_ready = worker_ready[3];
    endcase
    
    always @(worker_select, pValidArray_0)
    case (worker_select)
        4'b0001: worker_pValid = {3'b000,pValidArray_0};
        4'b0010: worker_pValid = {2'b00,pValidArray_0,1'b0};
        4'b0100: worker_pValid = {1'b0,pValidArray_0,2'b00};
        4'b1000: worker_pValid = {pValidArray_0,3'b000};
    endcase
    assign readyArray_0 = msdf_ready;
    
    genvar d; 
    generate 
        for( d = 0; d < `NUM_WORKERS; d = d + 1) begin: groups 
            wire [`NUM_BITS_PER_BANK*3-1:0]msdf_add_0_dataInArray_0;
            wire msdf_add_0_pValidArray_0;
            wire msdf_add_0_readyArray_0;

            wire [2:0]msdf_add_0_dataOutArray_0;
            wire msdf_add_0_validArray_0;
            wire msdf_add_0_nReadyArray_0;

            assign msdf_add_0_pValidArray_0 = worker_pValid[d];
            assign msdf_add_0_nReadyArray_0 = worker_nReady[d];

            assign worker_ready[d] = msdf_add_0_readyArray_0;
            assign worker_valid[d] = msdf_add_0_validArray_0;


            assign msdf_add_0_dataInArray_0 = worker_dataInArray_0;
            assign worker_dataOutArray_0[3*(d+1)-1:3*(d)] = msdf_add_0_dataOutArray_0;

            msdf_worker
            msdf_worker_inst
            (
                .clk(clk),
                .rst(rst),

                .dataInArray_0(msdf_add_0_dataInArray_0),
                .pValidArray_0(msdf_add_0_pValidArray_0),
                .readyArray_0(msdf_add_0_readyArray_0),

                .dataOutArray_0(msdf_add_0_dataOutArray_0),
                .validArray_0(msdf_add_0_validArray_0),
                .nReadyArray_0(msdf_add_0_nReadyArray_0)
            );
           
        end 
    endgenerate
    


    msdf_adder_tree 
    #(
        .TARGET_PRECISION(32),
        .TREE_DEPTH(2),
        .TREE_WIDTH(4)
    )
    msdf_add_sum
    (
        .clk(clk),
        .rst(rst),

        .dataInArray_0(sum_dataInArray_0),
        .pValidArray_0(sum_pValidArray_0),
        .readyArray_0(sum_readyArray_0),

        .dataOutArray_0(sum_dataOutArray_0),
        .validArray_0(sum_validArray_0),
        .nReadyArray_0(sum_nReadyArray_0)
    );


    /********************************************************************************************

    到这里点积已经做完了!

    ***********************************************************************************/
    
    

    
    
    // msdf_Const
    // #(
    //     .CONST_DATA_PLUS(64'h0000_0000_0000_0000),		//常数值正部分
    //     .CONST_DATA_MINUS(64'h8000_0000_0000_0000)		//常数值负部分
	// )msdf_cst_b
    // (
    //     .clk(clk),
    //     .rst(rst),

    //     .dataInArray_0(msdf_cst_b_dataInArray_0),
    //     .pValidArray_0(msdf_cst_b_pValidArray_0),
    //     .readyArray_0(msdf_cst_b_readyArray_0),

    //     .dataOutArray_0(msdf_cst_b_dataOutArray_0),
    //     .validArray_0(msdf_cst_b_validArray_0),
    //     .nReadyArray_0(msdf_cst_b_nReadyArray_0)
    // );

    
    // /* 点积结果与b作差 */
    

    
    


    // msdf_add_op 
    // #(
    //     .TARGET_PRECISION(32)
    // )
    // msdf_error_0
    // (
    //     .clk(clk),
    //     .rst(rst),

    //     .dataInArray_0(msdf_error_0_dataInArray_0),
    //     .dataInArray_1(msdf_error_0_dataInArray_1),
    //     .pValidArray_0(msdf_error_0_pValidArray_0),
    //     .pValidArray_1(msdf_error_0_pValidArray_1),
    //     .readyArray_0(msdf_error_0_readyArray_0),
    //     .readyArray_1(msdf_error_0_readyArray_1),

    //     .dataOutArray_0(msdf_error_0_dataOutArray_0),
    //     .validArray_0(msdf_error_0_validArray_0),
    //     .nReadyArray_0(msdf_error_0_nReadyArray_0)
    // );

    // msdf_gradient#(
    // .TARGET_PRECISION(35),
    // .LEARNING_RATE(7)
    // )
    // msdf_gradient_0
    // (
    //     .clk(clk),
    //     .rst(rst),
    //     .good_transfer(good_input_transfer),
    //     .a_buffer_2(a_buffer_2),
    //     .a_buffer_1(a_buffer_1),
    //     .a_buffer_0(a_buffer_0),

    //     .dataInArray_0(msdf_gradient_0_dataInArray_0),    
    //     .pValidArray_0(msdf_gradient_0_pValidArray_0),
    //     .readyArray_0(msdf_gradient_0_readyArray_0),

    //     .dataOutArray_0(msdf_gradient_0_dataOutArray_0),
    //     .validArray_0(msdf_gradient_0_validArray_0),
    //     .nReadyArray_0(msdf_gradient_0_nReadyArray_0)
    // );


    // wire local_x_wea;
    // wire [7:0]local_x_addra;
    // wire [`NUM_GRADIENT*3-1:0]local_x_dina;
    // wire [7:0]local_x_addrb;
    // wire [`NUM_GRADIENT*3-1:0]local_x_doutb;

    // msdf_update_local_x#(
    // .TARGET_PRECISION(25)
    // )
    // msdf_update_local_x_inst
    // (
    //     .clk(clk),
    //     .rst(rst),
    //     .dataInArray_0(msdf_gradient_0_dataOutArray_0),
    //     .pValidArray_0(msdf_gradient_0_validArray_0),
    //     .readyArray_0(),

    //     /* ram接口 */
    //     .local_x_wea(local_x_wea),            //写使能,否则默认是读
    //     .local_x_addra(local_x_addra),          //a口读写地址
    //     .local_x_dina(local_x_dina),           //要写到mem的数据

    //     .local_x_addrb(local_x_addrb),          //b口读地址
    //     .local_x_doutb(local_x_doutb)            //b口读出的数据
    // );

    // mem_local_x mem_local_x_inst (
    //     .clka(clk),    // input wire clka
    //     .wea(local_x_wea),      // input wire [0 : 0] wea
    //     .addra(local_x_addra),  // input wire [4 : 0] addra
    //     .dina(local_x_dina),    // input wire [1535 : 0] dina
    //     .clkb(clk),    // input wire clkb
    //     .addrb(local_x_addrb),  // input wire [4 : 0] addrb
    //     .doutb(local_x_doutb)  // output wire [1535 : 0] doutb
    // );

    // /* 计算梯度! */
    // wire [2:0]gradient_dataInArray_0;
    // wire gradient_pValidArray_0;
    // wire gradient_readyArray_0;
    // wire [3:0]gradient_dataInArray_1;
    // wire gradient_pValidArray_1;
    // wire gradient_readyArray_1;
    // wire [2:0]gradient_dataOutArray_0;
    // wire gradient_validArray_0;
    // wire gradient_nReadyArray_0;


    // genvar index_worker, index_feature; 
    // generate 
    //     for( index_worker = 0; index_worker < `NUM_WORKERS; index_worker = index_worker + 1) begin: loop_of_worker
    //         for( index_feature = 0; index_feature < `NUM_BITS_PER_BANK; index_feature = index_feature + 1) begin: loop_of_feature           
                
                
    //             msdf_mult_op 
    //             #(
    //                 .TARGET_PRECISION(40)
    //             )
    //             msdf_mult_op_inst
    //             (
    //                 .clk(clk),
    //                 .rst(rst),

    //                 .dataInArray_0(),
    //                 .dataInArray_1(dataInArray_1[3*(i+1)-1:3*i]),
    //                 .pValidArray_0(pValidArray_0),
    //                 .pValidArray_1(pValidArray_1),
    //                 .readyArray_0(readyArray_0),
    //                 .readyArray_1(readyArray_1),


    //                 .dataOutArray_0(msdf_mult_op_dataOutArray_0[3*(i+1)-1:3*i]),
    //                 .validArray_0(msdf_mult_op_validArray_0[i]),
    //                 .nReadyArray_0(msdf_mult_op_nReadyArray_0[i])
    //             );
                
    //         end
    //     end 
    // endgenerate



    
endmodule
