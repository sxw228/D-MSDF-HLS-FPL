`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/28 19:01:26
// Design Name: 
// Module Name: arithmetic_units
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
module ret_op#(
    parameter DATA_SIZE_IN	= 32'd4,		
    parameter DATA_SIZE_OUT	= 32'd4
)(
    input wire clk,
    input wire rstn,

    input wire [DATA_SIZE_IN-1:0] dataInArray,
    input wire pValidArray,
    output wire readyArray,


    output wire [DATA_SIZE_OUT-1:0] dataOutArray,
    output wire validArray,
    input wire nReadyArray
);

 TEHB#(
 .INPUTS(1),
 .OUTPUTS(1),
 .DATA_SIZE_IN(DATA_SIZE_IN),
 .DATA_SIZE_OUT(DATA_SIZE_IN))
  tehb_inst(
        .clk(clk),
        .rst(~rstn),
        .dataInArray(dataInArray),
        .pValidArray(pValidArray),
        .readyArray(readyArray),
        .dataOutArray(dataOutArray),
        .validArray(validArray),
        .nReadyArray(nReadyArray)
    );
    
endmodule

module add_op#(
    parameter DATA_SIZE_IN	= 32'd4,		
    parameter DATA_SIZE_OUT	= 32'd4
)(
    input wire clk,
    input wire rstn,

    input wire [DATA_SIZE_IN-1:0] dataInArray_0,
    input wire [DATA_SIZE_IN-1:0] dataInArray_1,
    input wire [1:0]pValidArray,
    output wire [1:0]readyArray,


    output wire [DATA_SIZE_OUT-1:0] dataOutArray,
    output wire validArray,
    input wire nReadyArray
);

    wire join_valid;
    Join #(.N(2)) Join_int(
        .pValidArray(pValidArray),
        .valid(join_valid),
        .readyArray(readyArray),
        .nReady(nReadyArray)
    );
    assign dataOutArray = dataInArray_0 + dataInArray_1;
    assign validArray = join_valid;
endmodule

module mul_op#(
    parameter DATA_SIZE_IN	= 32'd4,		
    parameter DATA_SIZE_OUT	= 32'd8
)(
    input wire clk,
    input wire rstn,

    input wire [DATA_SIZE_IN-1:0] dataInArray_0,
    input wire [DATA_SIZE_IN-1:0] dataInArray_1,
    input wire [1:0]pValidArray,
    output wire [1:0]readyArray,


    output wire [DATA_SIZE_OUT-1:0] dataOutArray,
    output wire validArray,
    input wire nReadyArray
);

    localparam LATENCY = 4;

    wire join_valid;
    wire buff_valid,oehb_valid,oehb_ready;
    wire oehb_dataOut,oehb_datain;

    Join #(.SIZE(2)) Join_int(
        .pValidArray(pValidArray),
        .valid(join_valid),
        .readyArray(readyArray),
        .nReady(oehb_ready)
    );
    mul_4_stage #(.DATA_SIZE_IN(DATA_SIZE_IN),.DATA_SIZE_OUT(DATA_SIZE_OUT))
    mul_4_state_inst(
        .clk(clk),
        .ce(oehb_ready),
        .a(dataInArray_0),
        .b(dataInArray_1),
        .p(dataOutArray)
    );
    delay_buffer#(.SIZE(LATENCY-1))
    delay_buffer_inst(
        .clk(clk),
        .rstn(rstn),
        .valid_in(join_valid),
        .ready_in(oehb_ready),
        .valid_out(buff_valid)
    );
    OEHB#(.DATA_WIDTH(1)) OEHB_inst(
        .clk(clk),
        .rstn(rstn),

        .dataInArray(oehb_datain),
        .pValidArray(buff_valid),
        .readyArray(oehb_ready),

        .dataOutArray(oehb_dataOut),
        .validArray(validArray),
        .nReadyArray(nReadyArray)
    );

endmodule

module delay_buffer#(
    parameter SIZE	= 32'd4
)(
    input wire clk,
    input wire rstn,


    input wire valid_in,
    input wire ready_in,

    output wire valid_out
);

    reg [SIZE-1:0] regs;

    always@(posedge clk)begin
        if(~rstn)begin
            regs <= 'd0;
        end
        else if(ready_in)begin
            regs[SIZE-1:0] <= {regs[SIZE-2:0],valid_in};
        end
        else begin
            regs[SIZE-1:0] <= regs[SIZE-1:0];
        end
    end
    
    assign valid_out = regs[SIZE-1];
endmodule

module mul_4_stage#(
    parameter DATA_SIZE_IN	= 32'd8,
    parameter DATA_SIZE_OUT	= 32'd16
)(
    input wire clk,
    input wire ce,


    input wire [DATA_SIZE_IN-1:0]a,
    input wire [DATA_SIZE_IN-1:0]b,

    output wire [DATA_SIZE_OUT-1:0]p
);

    wire [DATA_SIZE_OUT-1:0]mul;
    reg [DATA_SIZE_IN-1:0] a_reg;
    reg [DATA_SIZE_IN-1:0] b_reg;
    reg [DATA_SIZE_OUT-1:0]q0,q1,q2;
    always@(posedge clk)begin
        if(ce)begin
            a_reg <= a;
            b_reg <= b;
            q0 <= mul;
            q1 <= q0;
            q2 <= q1;
        end
        else begin
            a_reg <= a_reg;
            b_reg <= b_reg;
            q0 <= q0;
            q1 <= q1;
            q2 <= q2;
        end
    end
    assign mul = a_reg * b_reg;
    assign p = q2;
endmodule

