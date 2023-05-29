`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/28 19:32:30
// Design Name: 
// Module Name: msdf_dot
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

module msdf_dot#(
    parameter TARGET_PRECISION    = 25,
    parameter TREE_DEPTH          = 3,
    parameter TREE_WIDTH          = 2**TREE_DEPTH//8//TREE_DEPTH**2 //
)(
    input wire clk,
    input wire rst,

    input wire [3*`NUM_BITS_PER_BANK-1:0] dataInArray_0,
    input wire pValidArray_0,
    output wire readyArray_0,

    input wire [3*`NUM_BITS_PER_BANK-1:0] dataInArray_1,
    input wire pValidArray_1,
    output wire readyArray_1,


    output wire [2:0] dataOutArray_0,
    output wire validArray_0,
    input wire nReadyArray_0
    );

    wire [3*`NUM_BITS_PER_BANK-1:0] msdf_mult_op_dataOutArray_0;
    wire [`NUM_BITS_PER_BANK-1:0]msdf_mult_op_validArray_0;
    wire [`NUM_BITS_PER_BANK-1:0]msdf_mult_op_nReadyArray_0;
    
    wire [2:0]msdf_adder_tree_dataOutArray_0;
    wire msdf_adder_tree_validArray_0;
    wire msdf_adder_tree_nReadyArray_0;

    wire [2:0]msdf_incr_end_out;
    wire msdf_incr_end_valid;
    wire msdf_incr_end_ready;


    // assign msdf_mult_op_nReadyArray_0 = {64{nReadyArray_0}};
    // assign dataOutArray_0 = msdf_mult_op_dataOutArray_0[2:0];
    // assign validArray_0 = msdf_mult_op_validArray_0[0];
    assign msdf_adder_tree_nReadyArray_0 = nReadyArray_0;
    assign dataOutArray_0 = msdf_adder_tree_dataOutArray_0;
    assign validArray_0 = msdf_adder_tree_validArray_0;
    // assign msdf_incr_end_ready = nReadyArray_0;
    // assign dataOutArray_0 = msdf_incr_end_out;
    // assign validArray_0 = msdf_incr_end_valid;
    
    wire dbg_msdf_mult_op_dataOutArray_0_last = msdf_mult_op_dataOutArray_0[2];
    wire dbg_msdf_mult_op_validArray_0 = msdf_mult_op_validArray_0;
    wire dbg_msdf_mult_op_nReadyArray_0 = msdf_mult_op_nReadyArray_0;

    wire dbg_msdf_adder_tree_dataOutArray_0_last = msdf_adder_tree_dataOutArray_0[2];
    wire dbg_msdf_adder_tree_validArray_0 = msdf_adder_tree_validArray_0;
    wire dbg_msdf_adder_tree_nReadyArray_0 = msdf_adder_tree_nReadyArray_0;


    genvar i;
    generate for( i = 0; i < `NUM_BITS_PER_BANK; i = i + 1) begin: gen_multiplier 
        if(i==0)begin
            msdf_mult_op 
            #(
                .TARGET_PRECISION(TARGET_PRECISION)
            )
            msdf_mult_op_inst
            (
                .clk(clk),
                .rst(rst),

                .dataInArray_0({dataInArray_1[3*(i+1)-1],dataInArray_0[3*(i+1)-2:3*i]}),
                .dataInArray_1(dataInArray_1[3*(i+1)-1:3*i]),
                .pValidArray_0(pValidArray_0),
                .pValidArray_1(pValidArray_1),
                .readyArray_0(readyArray_0),
                .readyArray_1(readyArray_1),


                .dataOutArray_0(msdf_mult_op_dataOutArray_0[3*(i+1)-1:3*i]),
                .validArray_0(msdf_mult_op_validArray_0[i]),
                .nReadyArray_0(msdf_mult_op_nReadyArray_0[i])
            );
        end
        else begin
            msdf_mult_op 
            #(
                .TARGET_PRECISION(TARGET_PRECISION)
            )
            msdf_mult_op_inst
            (
                .clk(clk),
                .rst(rst),

                .dataInArray_0({dataInArray_1[3*(i+1)-1],dataInArray_0[3*(i+1)-2:3*i]}),
                .dataInArray_1(dataInArray_1[3*(i+1)-1:3*i]),
                .pValidArray_0(pValidArray_0),
                .pValidArray_1(pValidArray_1),
                .readyArray_0(),
                .readyArray_1(),


                .dataOutArray_0(msdf_mult_op_dataOutArray_0[3*(i+1)-1:3*i]),
                .validArray_0(msdf_mult_op_validArray_0[i]),
                .nReadyArray_0(msdf_mult_op_nReadyArray_0[i])
            );
        end
    end
    endgenerate

    msdf_adder_tree#(
    .TARGET_PRECISION(TARGET_PRECISION),
    .TREE_DEPTH(TREE_DEPTH),
    .TREE_WIDTH(TREE_WIDTH)
    )
    msdf_adder_tree_inst
    (
    .clk(clk),
    .rst(rst),

    .dataInArray_0(msdf_mult_op_dataOutArray_0),
    .pValidArray_0(msdf_mult_op_validArray_0),
    .readyArray_0(msdf_mult_op_nReadyArray_0),

    .dataOutArray_0(msdf_adder_tree_dataOutArray_0),
    .validArray_0(msdf_adder_tree_validArray_0),
    .nReadyArray_0(msdf_adder_tree_nReadyArray_0)
    );

    // msdf_incr 
    // #(
    //     .TARGET_PRECISION(TARGET_PRECISION),
    //     .NUM_CHUNKS(`NUM_CHUNKS)
    // )
    // msdf_incr_inst(
    // .clk(clk),
    // .rst(rst),

    // .dataInArray_0(msdf_adder_tree_dataOutArray_0),
    // .pValidArray_0(msdf_adder_tree_validArray_0),
    // .readyArray_0(msdf_adder_tree_nReadyArray_0),


    // .dataOutArray_0(msdf_incr_end_out),
    // .validArray_0(msdf_incr_end_valid),
    // .nReadyArray_0(msdf_incr_end_ready)
    // );


endmodule
