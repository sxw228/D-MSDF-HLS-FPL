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

module msdf_dot_no_group(
    input wire clk,
    input wire rst,

    input wire [3*`NUM_BITS_PER_BANK-1:0] dataInArray_0,
    input wire pValidArray_0,
    output wire readyArray_0,


    output wire [13*64*3-1:0]dataOutArray_0,
    output wire validArray_0,
    input wire nReadyArray_0,

    output wire [13*64*3-1:0]dbg_x_new_data,
    output wire dbg_x_new_valid
    );




    localparam STATE_IDLE = 8'd0;               //复位后进这个状态,下一拍进STARTING
    localparam STATE_STARTING = 8'd1;           //下一个进STATE_EPOCH
    localparam STATE_EPOCH = 8'd2;              //下一个进STATE_EPOCH_SAMPLE
    localparam STATE_EPOCH_SAMPLE = 8'd3;       //下一个进STATE_SAMPLE
    localparam STATE_SAMPLE = 8'd4;             //下一个STATE_A_COMPUTING
    localparam STATE_A_COMPUTING = 8'd5;
    localparam STATE_WORER_CHECH = 8'd6;

    /* 读写bram */
    wire mem_x_wea;
    wire [8:0]mem_x_addra;
    wire [191:0]mem_x_dina;
    wire [191:0]mem_x_douta;
    reg [191:0]mem_x_douta_delay;    

    reg [7:0]state_group;                      //group主状态机
    wire good_input_transfer;                   //指示一次有效传输
    
    reg [`WIDTH_BIT_INDEX-1:0]a_index;

    reg [`WIDTH_BIT_INDEX-1:0]good_transfer_cnt;
    reg [`WIDTH_BIT_INDEX-1:0]a_bit_index;               //串行输入a的bit索引,a的长度是ka-SHF-1
    reg [`WIDTH_BIT_INDEX-1:0]chunk_index;            //一个样本内不同轮次的索引
    reg [`WIDTH_BIT_INDEX-1:0]sample_index;
    reg [`WIDTH_BIT_INDEX-1:0]batch_index;

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
                end
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
            chunk_index <= 'd0;
            sample_index <= 'd0;
            batch_index <= 'd0;
            a_index <= 'd0;
        end
        else if(state_group == STATE_A_COMPUTING)begin
            if(good_input_transfer)begin
                good_transfer_cnt <= good_transfer_cnt+1;
                a_index <= a_index+1;
                if(a_bit_index == 'd24)begin
                    a_bit_index <= 'd0;
                    if(chunk_index == 'd13)begin
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
                    a_bit_index <= a_bit_index+1;
                end
            end
        end
    end


    /* 点积模块信号 */
    wire [`NUM_BITS_PER_BANK*3-1:0]dot_dataInArray_0;
    wire [`NUM_BITS_PER_BANK*3-1:0]dot_dataInArray_1;
    wire dot_pValidArray_0;
    wire dot_pValidArray_1;
    wire dot_readyArray_0;
    wire dot_readyArray_1;
    wire [2:0]dot_dataOutArray_0;
    wire dot_validArray_0;
    wire dot_nReadyArray_0;

    /* 累加器模块信号 */
    wire [2:0]incr_dataInArray_0;
    wire incr_pValidArray_0;
    wire incr_readyArray_0;
    wire [2:0]incr_dataOutArray_0;
    wire incr_validArray_0;
    wire incr_nReadyArray_0;

    reg [7:0]last_cnt;

    /* 累加器后的EHB */
    wire [`NUM_BITS_PER_BANK*3-1:0]incr_EHB_dataInArray;
    wire incr_EHB_pValidArray;
    wire incr_EHB_readyArray;
    wire [`NUM_BITS_PER_BANK*3-1:0]incr_EHB_dataOutArray;
    wire incr_EHB_validArray;
    wire incr_EHB_nReadyArray;

    /* 计算误差 */
    wire [2:0]msdf_cst_b_dataInArray_0;
    wire msdf_cst_b_pValidArray_0;
    wire msdf_cst_b_readyArray_0;
    wire [2:0]msdf_cst_b_dataOutArray_0;
    wire msdf_cst_b_validArray_0;
    wire msdf_cst_b_nReadyArray_0;

    wire [2:0]msdf_error_0_dataInArray_0;
    wire msdf_error_0_pValidArray_0;
    wire msdf_error_0_readyArray_0;
    wire [2:0]msdf_error_0_dataInArray_1;
    wire msdf_error_0_pValidArray_1;
    wire msdf_error_0_readyArray_1;
    wire [2:0]msdf_error_0_dataOutArray_0;
    wire msdf_error_0_validArray_0;
    wire msdf_error_0_nReadyArray_0;


    wire [2:0]msdf_gradient_0_dataInArray_0;
    wire msdf_gradient_0_pValidArray_0;
    wire msdf_gradient_0_readyArray_0;
    wire [`NUM_GRADIENT*3-1:0]msdf_gradient_0_dataOutArray_0;
    wire msdf_gradient_0_validArray_0;
    wire msdf_gradient_0_nReadyArray_0;

    /* 模块输入侧的EHB */
    wire [`NUM_BITS_PER_BANK*3-1:0]EHB_dataInArray;
    wire EHB_pValidArray;
    wire EHB_readyArray;
    wire [`NUM_BITS_PER_BANK*3-1:0]EHB_dataOutArray;
    wire EHB_validArray;
    wire EHB_nReadyArray;


    /* 常数 */
    wire [2:0]msdf_cst_one_minus_dataInArray_0;
    wire msdf_cst_one_minus_pValidArray_0;
    wire msdf_cst_one_minus_readyArray_0;
    wire [2:0]msdf_cst_one_minus_dataOutArray_0;
    wire msdf_cst_one_minus_validArray_0;
    wire msdf_cst_one_minus_nReadyArray_0;


    /* 连线线 */

    assign good_input_transfer = pValidArray_0 & readyArray_0;    //有效传输的式子
    //assign good_input_transfer = EHB_validArray& EHB_nReadyArray;

    /* 累加器后面连个比较器 */
    assign msdf_cst_one_minus_dataInArray_0 = incr_dataOutArray_0[2:0];
    assign msdf_cst_one_minus_pValidArray_0 = incr_validArray_0;
    assign msdf_cst_one_minus_nReadyArray_0 = 1'b1;

    /* gradient连输出 */
    assign dataOutArray_0 = msdf_gradient_0_dataOutArray_0;
    assign validArray_0 = msdf_gradient_0_validArray_0;
    assign msdf_gradient_0_nReadyArray_0 = nReadyArray_0;
    /* error的输出连gradient */
    assign msdf_gradient_0_dataInArray_0 = msdf_error_0_dataOutArray_0;
    assign msdf_gradient_0_pValidArray_0 = msdf_error_0_validArray_0;
    assign msdf_error_0_nReadyArray_0 = msdf_gradient_0_readyArray_0;

    /* OEHB的输出->error的输入 */
    assign msdf_cst_b_dataInArray_0 = incr_EHB_dataOutArray;
    assign msdf_cst_b_pValidArray_0 = incr_EHB_validArray;

    assign msdf_error_0_dataInArray_0 = incr_EHB_dataOutArray;
    assign msdf_error_0_pValidArray_0 = incr_EHB_validArray;
    assign incr_EHB_nReadyArray = msdf_error_0_readyArray_0;

    assign msdf_error_0_dataInArray_1 = msdf_cst_b_dataOutArray_0;
    assign msdf_error_0_pValidArray_1 = msdf_cst_b_validArray_0;
    assign msdf_cst_b_nReadyArray_0 = msdf_error_0_readyArray_1;

    /* 累加器连OEHB */
    assign incr_EHB_dataInArray = incr_dataOutArray_0[2:0];
    assign incr_EHB_pValidArray = (last_cnt == `NUM_CHUNKS-1) ? incr_validArray_0 : 1'b0;
    assign incr_nReadyArray_0 = incr_EHB_readyArray;

    /* 点积连累加器 */
    assign incr_dataInArray_0 = dot_dataOutArray_0;
    assign incr_pValidArray_0 = dot_validArray_0;
    assign dot_nReadyArray_0 = incr_readyArray_0;

    /* 点积输入0端连EHB输出 */
    assign dot_dataInArray_0 = EHB_dataOutArray;
    assign dot_pValidArray_0 = EHB_validArray;
    assign EHB_nReadyArray = dot_readyArray_0;

    /* 点积输入1端连global_x */
    assign dot_dataInArray_1 = mem_x_douta;
    assign dot_pValidArray_1 = EHB_validArray;

    /* EHB输入连模块输入 */
    assign EHB_dataInArray = dataInArray_0;
    assign EHB_pValidArray = pValidArray_0;
    assign readyArray_0 = EHB_readyArray;

    /* global_x控制 */
    assign mem_x_wea = 1'b0;
    assign mem_x_dina = 'd0;
    assign mem_x_addra = a_index[8:0];

    /* 要有一个bram */
    blk_mem_gen_0 global_x (
        .clka(clk),    // input wire clka
        .wea(mem_x_wea),      // input wire [0 : 0] wea
        .addra(mem_x_addra),  // input wire [8 : 0] addra
        .dina(mem_x_dina),    // input wire [191 : 0] dina
        .douta(mem_x_douta)  // output wire [191 : 0] douta
    );

    always @(posedge clk) begin
        mem_x_douta_delay <= mem_x_douta;
    end

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
    
    msdf_incr 
    #(
        .TARGET_PRECISION(32),
        .NUM_CHUNKS(`NUM_CHUNKS)
    )
    msdf_incr_inst(
    .clk(clk),
    .rst(rst),

    .dataInArray_0(incr_dataInArray_0),
    .pValidArray_0(incr_pValidArray_0),
    .readyArray_0(incr_readyArray_0),


    .dataOutArray_0(incr_dataOutArray_0),
    .validArray_0(incr_validArray_0),
    .nReadyArray_0(incr_nReadyArray_0)
    );

    

    always @(posedge clk) begin
        if(rst)begin
            last_cnt <= 'd0;
        end
        else if(incr_validArray_0 & incr_dataOutArray_0[2])begin  //加法器输出一个last
            if(last_cnt == `NUM_CHUNKS-1)begin
                last_cnt <= 'd0;
            end
            else begin
                last_cnt <= last_cnt+1;
            end
        end
    end

    OEHB#(.DATA_WIDTH(3))
	incr_OEHB_inst(
        .clk(clk),
        .rstn(~rst),
        .dataInArray(incr_EHB_dataInArray),
        .pValidArray(incr_EHB_pValidArray),
        .readyArray(incr_EHB_readyArray),
        .dataOutArray(incr_EHB_dataOutArray),
        .validArray(incr_EHB_validArray),
        .nReadyArray(incr_EHB_nReadyArray)
    );

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

    /* 济源的比较器 */

    msdf_Const
    #(
        .CONST_DATA_PLUS(64'h0200_0000_0000_0000),		//常数值正部分
        .CONST_DATA_MINUS(64'h0000_0000_0000_0000)		//常数值负部分
    )msdf_cst_one_minus
    (
        .clk(clk),
        .rst(rst),

        .dataInArray_0(msdf_cst_one_minus_dataInArray_0),
        .pValidArray_0(msdf_cst_one_minus_pValidArray_0),
        .readyArray_0(msdf_cst_one_minus_readyArray_0),

        .dataOutArray_0(msdf_cst_one_minus_dataOutArray_0),
        .validArray_0(msdf_cst_one_minus_validArray_0),
        .nReadyArray_0(msdf_cst_one_minus_nReadyArray_0)
    );



    wire [2:0]cmp_rdata;
    wire cmp_rvalid;


    OnTheFly_CMP_Interface
    #(			
        .ENCODING_MODE("signed-digit"),				
        .ERR_WIDTH(8'd8)			
    )OnTheFly_CMP_Interface_inst
    (
        .i_clk(clk),
        .i_rstn(~rst),
        .i_mbus_wen(incr_validArray_0),							
        .i_mbus_werr_limit(8'd0),	
        .i_mbus_wdata_x(incr_dataOutArray_0[1:0]),		
        .i_mbus_wdata_y(msdf_cst_one_minus_dataOutArray_0[1:0]),		
        .i_mbus_wvalid(incr_validArray_0),						
        .i_mbus_wlast(1'b0),							
        .o_mbus_rdata(cmp_rdata),					
        .o_mbus_rvalid(cmp_rvalid)						
    );

    msdf_Const
    #(
        .CONST_DATA_PLUS(64'h0000_0000_0000_0000),		//常数值正部分
        .CONST_DATA_MINUS(64'h0200_0000_0000_0000)		//常数值负部分
	)msdf_cst_b
    (
        .clk(clk),
        .rst(rst),

        .dataInArray_0(msdf_cst_b_dataInArray_0),
        .pValidArray_0(msdf_cst_b_pValidArray_0),
        .readyArray_0(msdf_cst_b_readyArray_0),

        .dataOutArray_0(msdf_cst_b_dataOutArray_0),
        .validArray_0(msdf_cst_b_validArray_0),
        .nReadyArray_0(msdf_cst_b_nReadyArray_0)
    );

    /* 点积结果与b作差 */
    msdf_add_op 
    #(
        .TARGET_PRECISION(32)
    )
    msdf_error_0
    (
        .clk(clk),
        .rst(rst),

        .dataInArray_0(msdf_error_0_dataInArray_0),
        .dataInArray_1(msdf_error_0_dataInArray_1),
        .pValidArray_0(msdf_error_0_pValidArray_0),
        .pValidArray_1(msdf_error_0_pValidArray_1),
        .readyArray_0(msdf_error_0_readyArray_0),
        .readyArray_1(msdf_error_0_readyArray_1),

        .dataOutArray_0(msdf_error_0_dataOutArray_0),
        .validArray_0(msdf_error_0_validArray_0),
        .nReadyArray_0(msdf_error_0_nReadyArray_0)
    );

 
   

    

    wire msdf_gradient_good_transfer;
    assign msdf_gradient_good_transfer = msdf_error_0_validArray_0 & msdf_error_0_nReadyArray_0;

    wire [64*3*13-1:0]a_buffer_data;
    wire [8:0] a_buffer_addr;

    msdf_gradient#(
    .TARGET_PRECISION(32),
    .LEARNING_RATE(7)
    )
    msdf_gradient_0
    (
        .clk(clk),
        .rst(rst),
        .good_transfer(msdf_gradient_good_transfer),
        .a_buffer_addrb(a_buffer_addr),
        .a_buffer(a_buffer_data),

        .dataInArray_0(msdf_gradient_0_dataInArray_0),    
        .pValidArray_0(msdf_gradient_0_pValidArray_0),
        .readyArray_0(msdf_gradient_0_readyArray_0),

        .dataOutArray_0(msdf_gradient_0_dataOutArray_0),
        .validArray_0(msdf_gradient_0_validArray_0),
        .nReadyArray_0(msdf_gradient_0_nReadyArray_0)
    );


    wire global_local_x_wea;
    wire [8:0]global_local_x_addra;
    wire [192*13-1:0]global_local_x_dina;
    wire [8:0]global_local_x_addrb;
    wire [192*13-1:0]global_local_x_doutb;

    assign dbg_x_new_data = global_local_x_dina;
    assign dbg_x_new_valid = global_local_x_wea;

    msdf_update_local_x#(
    .TARGET_PRECISION(32)
    )
    msdf_update_local_x_inst
    (
        .clk(clk),
        .rst(rst),
        .dataInArray_0(msdf_gradient_0_dataOutArray_0),
        .pValidArray_0(msdf_gradient_0_validArray_0),
        .readyArray_0(),

        /* ram接口 */
        .local_x_wea(global_local_x_wea),            //写使能,否则默认是读
        .local_x_addra(global_local_x_addra),          //a口读写地址
        .local_x_dina(global_local_x_dina),           //要写到mem的数据

        .local_x_addrb(global_local_x_addrb),          //b口读地址
        .local_x_doutb(global_local_x_doutb)            //b口读出的数据
    );


    

    /* 生成选择信号 */
    reg [`NUM_CHUNKS-1:0]a_buffer_select;
    always @(posedge clk) begin
        if(rst)begin
            a_buffer_select <= 'd0;
        end
        else if(chunk_index == 8'd0)a_buffer_select <= 13'b0000000000001;
        else if(chunk_index == 8'd1)a_buffer_select <= 13'b0000000000010;
        else if(chunk_index == 8'd2)a_buffer_select <= 13'b0000000000100;
        else if(chunk_index == 8'd3)a_buffer_select <= 13'b0000000001000;
        else if(chunk_index == 8'd4)a_buffer_select <= 13'b0000000010000;
        else if(chunk_index == 8'd5)a_buffer_select <= 13'b0000000100000;
        else if(chunk_index == 8'd6)a_buffer_select <= 13'b0000001000000;
        else if(chunk_index == 8'd7)a_buffer_select <= 13'b0000010000000;
        else if(chunk_index == 8'd8)a_buffer_select <= 13'b0000100000000;
        else if(chunk_index == 8'd9)a_buffer_select <= 13'b0001000000000;
        else if(chunk_index == 8'd10)a_buffer_select <= 13'b0010000000000;
        else if(chunk_index == 8'd11)a_buffer_select <= 13'b0100000000000;
        else if(chunk_index == 8'd12)a_buffer_select <= 13'b1000000000000;
        else a_buffer_select <= 'd0;
    end

    genvar index_gen; 
    generate 
        for( index_gen = 0; index_gen < `NUM_CHUNKS; index_gen = index_gen + 1) begin: loop_of_INDEX
            wire select;
            wire a_buffer_wea;
            reg [8:0]a_buffer_addra;
            wire [191:0]a_buffer_dina;
            wire [8:0]a_buffer_addrb;
            wire [191:0]a_buffer_doutb;

            /* 写a_buffer */
            always @(posedge clk) begin
                if(rst)begin
                    a_buffer_addra <= 'd0;
                end
                else if(a_buffer_wea)begin
                    a_buffer_addra <= a_buffer_addra+1;
                end
            end
            assign select = a_buffer_select[index_gen];
            assign a_buffer_wea = EHB_validArray& EHB_nReadyArray& select;
            assign a_buffer_dina = EHB_dataOutArray;
            assign a_buffer_addrb = a_buffer_addr;

            assign a_buffer_data[192*(index_gen+1)-1:192*index_gen] = a_buffer_doutb;

            a_buffer a_buffer_inst (
                .clka(clk),    // input wire clka
                .wea(a_buffer_wea),      // input wire [0 : 0] wea
                .addra(a_buffer_addra),  // input wire [8 : 0] addra
                .dina(a_buffer_dina),    // input wire [191 : 0] dina
                .clkb(clk),    // input wire clkb
                .addrb(a_buffer_addrb),  // input wire [8 : 0] addrb
                .doutb(a_buffer_doutb)  // output wire [191 : 0] doutb
            );

            wire local_x_wea;
            wire [8:0]local_x_addra;
            wire [191:0]local_x_dina;
            wire [8:0]local_x_addrb;
            wire [191:0]local_x_doutb;

            assign local_x_wea = a_buffer_wea | global_local_x_wea;
            //assign local_x_wea = a_buffer_wea ;
            assign local_x_addra = a_buffer_wea ? a_buffer_addra : global_local_x_addra;
            assign local_x_dina = a_buffer_wea ? mem_x_douta : global_local_x_dina[192*(index_gen+1)-1:192*index_gen];
            assign local_x_addrb = global_local_x_addrb;
            assign global_local_x_doutb[192*(index_gen+1)-1:192*index_gen] = local_x_doutb;

            blk_mem_gen_1 mem_local_x_inst (
                .clka(clk),    // input wire clka
                .wea(local_x_wea),      // input wire [0 : 0] wea
                .addra(local_x_addra),  // input wire [8 : 0] addra
                .dina(local_x_dina),    // input wire [191 : 0] dina
                .clkb(clk),    // input wire clkb
                .addrb(local_x_addrb),  // input wire [8 : 0] addrb
                .doutb(local_x_doutb)  // output wire [191 : 0] doutb
            );
        
    end 
    endgenerate

endmodule
