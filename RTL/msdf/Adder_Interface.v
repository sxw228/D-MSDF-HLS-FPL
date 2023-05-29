`timescale 1ns / 1ps

////////////////////////////////////English///////////////////////////////////////
// Company:			Disp301 Experiment in SouthEast University
// Engineer:		Erie
// 
// Create Date: 	2019/12/13 08:40:35
// Design Name: 	Adder Arithmetic
// Module Name: 	Adder_Interface
// Description: 	None
// 
// Dependencies: 	None
//
// Dependent modules:
// 	 Module Name				    Version
// 		None					 	 None
//
// Version:			V2.4
// Revision Date:	2022/04/15 14:14:36
// History:		
//    Time			   Version	   Revised by			Contents
// 2019/12/13			V1.0		 Erie		Create File and Adder_Arithmetic module.
// 2019/12/15			V1.1		 Erie		Write single-bit half adders and single-bit full adders.
// 2019/12/16			V1.2		 Erie		Optimize the XOR calculation in the full adder and change it to an OR operation to reduce resource usage.
// 2019/12/20			V1.3		 Erie		Add ripple carry adder RCA/carry lookahead adder LCA.
// 2019/12/23			V1.4		 Erie		Add carry skip adder CSA/carry select adder CSA.
// 2019/12/25			V1.5		 Erie		Unified name, RCA->CRA; LCA->CLA; carry select adder name adjusted to CSA->CCA:select->choose.
// 2020/01/05			V1.6		 Erie		Added Kogge Stone tree adder, referred to as KST.
// 2022/03/07			V2.0		 Erie		Renamed Adder_Interface, added parameterization options.
// 2022/03/10			V2.1		 Erie		Added BrentKung tree adder, referred to as BKT.
// 2022/03/11			V2.2		 Erie		Adjust the use of CRA interface parameters, and all module parameter definitions: ADDR_WIDTH->DATA_WIDTH.
// 2022/03/24			V2.3		 Erie		Increase the default parameter DEFAULT.
// 2022/04/15			V2.4		 Erie		Add compression adder interface, support 3-2/4-2/5-2 compressor.
///////////////////////////////////Chinese////////////////////////////////////////
// 版权归属:		东南大学显示中心301实验室
// 开发人员:		Erie
// 
// 创建日期: 		2019年12月13日
// 设计名称: 		Adder Arithmetic
// 模块名称: 		Adder_Interface
// 相关名称: 		None
// 
// 依赖资料: 		None
//
// 依赖模块:
// 	  模块名称						 版本
// 		None					 	 None
//
// 当前版本:		V2.4
// 修订日期:		2022年04月15日
// 修订历史:
//		时间			版本		修订人				修订内容	
// 2019年12月13日		V1.0		 Erie		创建文件,编写加法驱动模块(Adder_Arithmetic)
// 2019年12月15日		V1.1		 Erie		编写单比特半加器和单比特全加器
// 2019年12月16日		V1.2		 Erie		优化全加器中的异或计算,变为或运算减少资源使用
// 2019年12月20日		V1.3		 Erie		增加行波进位加法器RCA/超前进位加法器LCA
// 2019年12月23日		V1.4		 Erie		增加进位旁路加法器CSA/进位选择加法器CSA
// 2019年12月25日		V1.5		 Erie		统一名称,RCA->CRA;LCA->CLA;进位选择加法器名称调整为CSA->CCA:select->choose
// 2020年01月05日		V1.6		 Erie		增加Kogge Stone树型加法器,简称KST
// 2022年03月07日		V2.0		 Erie		更名为Adder_Interface,增加参数化选择
// 2022年03月10日		V2.1		 Erie		增加BrentKung树型加法器,简称BKT
// 2022年03月11日		V2.2		 Erie		调整CRA接口参数使用,以及所有模块参数定义:ADDR_WIDTH->DATA_WIDTH
// 2022年03月24日		V2.3		 Erie		增加默认参数DEFAULT
// 2022年04月15日		V2.4		 Erie		增加压缩加法器接口,支持3-2/4-2/5-2压缩器

//加法器接口
module Adder_Interface
#(
	parameter DATA_WIDTH_4Bit	= 8'd1,								//4Bit位宽指数
	parameter ADDER_MODE		= "DEFAULT",						//加法器模式,DEFAULT/HA/FA/CRA/CLA/CSA/CCA/KST/BKT
	parameter DATA_WIDTH 		= 4 << (DATA_WIDTH_4Bit - 1)		//加法计算位宽
)
(
	input [DATA_WIDTH - 1:0]i_A,			//加数A
	input [DATA_WIDTH - 1:0]i_B,			//加数B
	input i_Ci,								//上一级进位Cin,无进位则给0
	output [DATA_WIDTH - 1:0]o_Sum,			//和数Sum
	output o_Co								//进位Cout
);
	
	//根据加法器模式,判断
	generate if(ADDER_MODE == "DEFAULT")begin:gen_default_adder
		//------------输出信号连线----------//
		assign {o_Co,o_Sum} = i_A + i_B + i_Ci;
	end
	
	//如果是半加器
	if(ADDER_MODE == "HA")begin:gen_half_adder
		//半加器实例化
		Half_Adder_Interface Half_Adder_Interface_Inst(
			.i_A(i_A),					//加数A
			.i_B(i_B),					//加数B
			.o_Sum(o_Sum),				//和数Sum
			.o_Co(o_Co)					//进位Cout
		);
	end
	
	//如果是全加器
	else if(ADDER_MODE == "FA")begin:gen_full_adder
		//实例化全加器
		Full_Adder_Interface Full_Adder_Interface_Inst(
			.i_A(i_A),					//加数A
			.i_B(i_B),					//加数B
			.i_Ci(i_Ci),				//上一级进位Cin,无进位则给0
			.o_Sum(o_Sum),				//和数Sum
			.o_Co(o_Co)					//进位Cout
		);
	end
	
	//如果是行波进位加法器
	else if(ADDER_MODE == "CRA")begin:gen_carryripple_adder
		//实例化行波进位加法器
		CarryRipple_Adder_Interface #( .DATA_WIDTH(DATA_WIDTH))CarryRipple_Adder_Interface_Inst(
			.i_A(i_A),					//加数A
			.i_B(i_B),					//加数B
			.i_Ci(i_Ci),				//上一级进位Cin,无进位则给0
			.o_Sum(o_Sum),				//和数Sum
			.o_Co(o_Co)					//进位Cout
		);
	end
	
	//如果是超前进位加法器
	else if(ADDER_MODE == "CLA")begin:gen_carrylookahead_adder
		//实例化超前进位加法器
		CarryLookahead_Adder_Interface #( .DATA_WIDTH_4Bit(DATA_WIDTH_4Bit))CarryLookahead_Adder_Interface_Inst(
			.i_A(i_A),					//加数A
			.i_B(i_B),					//加数B
			.i_Ci(i_Ci),				//上一级进位Cin,无进位则给0
			.o_Sum(o_Sum),				//和数Sum
			.o_Co(o_Co)					//进位Cout
		);
	end
	
	//如果是进位旁路加法器
	else if(ADDER_MODE == "CSA")begin:gen_carryskip_adder
		//实例化进位旁路加法器
		CarrySkip_Adder_Interface #( .DATA_WIDTH_4Bit(DATA_WIDTH_4Bit))CarrySkip_Adder_Interface_Inst(
			.i_A(i_A),					//加数A
			.i_B(i_B),					//加数B
			.i_Ci(i_Ci),				//上一级进位Cin,无进位则给0
			.o_Sum(o_Sum),				//和数Sum
			.o_Co(o_Co)					//进位Cout
		);
	end
	
	//如果是进位选择加法器
	else if(ADDER_MODE == "CCA")begin:gen_carrychoose_adder
		//实例化进位选择加法器
		CarryChoose_Adder_Interface #( .DATA_WIDTH_4Bit(DATA_WIDTH_4Bit))CarryChoose_Adder_Interface_Inst(
			.i_A(i_A),					//加数A
			.i_B(i_B),					//加数B
			.i_Ci(i_Ci),				//上一级进位Cin,无进位则给0
			.o_Sum(o_Sum),				//和数Sum
			.o_Co(o_Co)					//进位Cout
		);
	end
	
	//如果是KoggeStone树型加法器
	else if(ADDER_MODE == "KST")begin:gen_koggestone_adder
		//实例化brentKung树型加法器
		KoggeStone_Adder_Interface #( .DATA_WIDTH_4Bit(DATA_WIDTH_4Bit))KoggeStone_Adder_Interface_Inst(
			.i_A(i_A),					//加数A
			.i_B(i_B),					//加数B
			.i_Ci(i_Ci),				//上一级进位Cin,无进位则给0
			.o_Sum(o_Sum),				//和数Sum
			.o_Co(o_Co)					//进位Cout
		);
	end
	
	//如果是BrentKung树型加法器
	else if(ADDER_MODE == "BKT")begin:gen_brentkung_adder
		//实例化brentKung树型加法器
		BrentKung_Adder_Interface #( .DATA_WIDTH_4Bit(DATA_WIDTH_4Bit))BrentKung_Adder_Interface_Inst(
			.i_A(i_A),					//加数A
			.i_B(i_B),					//加数B
			.i_Ci(i_Ci),				//上一级进位Cin,无进位则给0
			.o_Sum(o_Sum),				//和数Sum
			.o_Co(o_Co)					//进位Cout
		);
	end

	endgenerate
endmodule

//压缩加法器接口
module Compressed_Adder_Interface
#(
	parameter COMPRESSED_MODE	= "3-2",	//压缩加法器模式,3-2/4-2/5-2
	parameter DATA_WIDTH_0 		= 3,		//数据位宽0,与模式有关,"-"前面的数据
	parameter DATA_WIDTH_1		= 2			//数据位宽1,与模式有关,进位宽度
)
(
	input [DATA_WIDTH_0 - 1:0]i_X,			//加数,X[0]~X[DATA_WIDTH_0 - 1]
	input [DATA_WIDTH_1 - 1:0]i_Ci,			//上一级进位Cin
	output o_Sum,							//伪和
	output o_Carry,							//进位
	output [DATA_WIDTH_1 - 1:0]o_Co			//输出,如果是3-2压缩器,则此位不生效
);
	
	//如果是3-2压缩加法器
	generate if(COMPRESSED_MODE == "3-2")begin:gen_3_2_compressed_adder
		//3-2压缩加法器接口实例化
		Compressed32_Adder_Interface Compressed32_Adder_Interface_Inst(
			.i_X(i_X),						//加数,X[0]~X[2]
			.o_Sum(o_Sum),					//伪和
			.o_Carry(o_Carry)				//进位
		);
		
		//------------输出信号连线----------//
		assign o_Co = 0;
	end
	
	//如果是4-2压缩加法器
	else if(COMPRESSED_MODE == "4-2")begin:gen_4_2_compressed_adder
		//4-2压缩加法器接口实例化
		Compressed42_Adder_Interface Compressed42_Adder_Interface_Inst(
			.i_X(i_X),						//加数,X[0]~X[3]
			.i_Ci(i_Ci),					//上一级进位Cin
			.o_Sum(o_Sum),					//伪和
			.o_Carry(o_Carry),				//进位
			.o_Co(o_Co)						//进位Cout
		);
	end
	
	//如果是5-2压缩加法器
	else if(COMPRESSED_MODE == "5-2")begin:gen_5_2_compressed_adder
		//5-2压缩加法器接口实例化
		Compressed52_Adder_Interface Compressed52_Adder_Interface_Inst(
			.i_X(i_X),						//加数,X[0]~X[4]
			.i_Ci(i_Ci),					//上一级进位Cin
			.o_Sum(o_Sum),					//伪和
			.o_Carry(o_Carry),				//进位
			.o_Co(o_Co)	
		);
	end
	
	//未知模式
	else begin:gen_unkown_compressed_adder
		//------------输出信号连线----------//
		assign o_Co = 0;
		assign o_Carry = 0;
		assign o_Sum = 0;
		
	end endgenerate
	
endmodule

//真值表
//	A	B	Co	S
//	0	0	0	0
//	0	1	0	1
//	1	0	0	1
//	1	1	1	0
//半加器
module Half_Adder_Interface
(
	input i_A,				//加数A
	input i_B,				//加数B
	output o_Sum,			//和数Sum
	output o_Co				//进位Cout
);
	//计算
	assign o_Co = i_A & i_B;
	assign o_Sum = i_A ^ i_B;
endmodule

//真值表
//	A	B	Ci	Co	S
//	0	0	0	0	0
//	0	0	1	0	1
//	0	1	0	0	1
//	0	1	1	1	0
//	1	0	0	0	1
//	1	0	1	1	0
//	1	1	0	1	0
//	1	1	1	1	1
//全加器
module Full_Adder_Interface(
	input i_A,				//加数A
	input i_B,				//加数B
	input i_Ci,				//上一级进位Cin,无进位则给0
	output o_Sum,			//和数Sum
	output o_Co				//进位Cout
);
	//计算
	assign o_Co = (i_A & i_B) | (i_Ci & i_A) | (i_Ci & i_B);//(i_A & i_B) | (i_Ci & (i_A ^ i_B));优化结果,不用异或门
	assign o_Sum = i_A ^ i_B ^ i_Ci;
endmodule

//行波进位加法器:由N个全加器组成,CRA/RCA
module CarryRipple_Adder_Interface
#(
	parameter DATA_WIDTH	= 8'd4
)
(
	input [DATA_WIDTH - 1:0]i_A,			//加数A
	input [DATA_WIDTH - 1:0]i_B,			//加数B
	input i_Ci,								//上一级进位Cin,无进位则给0
	output [DATA_WIDTH - 1:0]o_Sum,		//和数Sum
	output o_Co								//进位Cout
);
	//进位数据
	wire [DATA_WIDTH:0]CarrayData;
	
	//--------------数据连线------------//
	assign CarrayData[0] = i_Ci;
	
	//------------输出信号连线----------//
	assign o_Co = CarrayData[DATA_WIDTH];
	
	//产生全加器
	generate begin
		genvar i;
		//遍历位宽
		for(i = 0;i < DATA_WIDTH;i = i + 1)begin
			//实例化全加器
			Full_Adder_Interface Full_Adder_Interface_Inst(
				.i_A(i_A[i]),					//加数A
				.i_B(i_B[i]),					//加数B
				.i_Ci(CarrayData[i]),			//上一级进位Cin,无进位则给0
				.o_Sum(o_Sum[i]),				//和数Sum
				.o_Co(CarrayData[i + 1])		//进位Cout
			);
		end
	end endgenerate
	
endmodule

//超前进位加法器:LCA,默认4bit,其他位宽可由4bit生成
module CarryLookahead_Adder4bit_Interface(
	input [3:0]i_A,				//加数A
	input [3:0]i_B,				//加数B
	input i_Ci,					//上一级进位Cin,无进位则给0
	output [3:0]o_Sum,			//和数Sum
	output o_Co					//进位Cout
);
	//定义中间进位信号
	wire [3:0]P;			//Pi = Ai ^ Bi
	wire [3:0]G;			//Gi = Ai & Bi
	wire [4:0]CarrayData;	//Carry[i] = G[i-1] + (Carry[i-1] & P[i-1])
	
	//--------------数据连线------------//
	assign CarrayData[0] = i_Ci;
	assign CarrayData[1] = G[0] + ( CarrayData[0] & P[0] );
	assign CarrayData[2] = G[1] + ( (G[0] + ( CarrayData[0] & P[0]) ) & P[1] );
	assign CarrayData[3] = G[2] + ( (G[1] + ( (G[0] + (CarrayData[0] & P[0]) ) & P[1])) & P[2] );
	assign CarrayData[4] = G[3] + ( (G[2] + ( (G[1] + ( (G[0] + (CarrayData[0] & P[0]) ) & P[1])) & P[2] )) & P[3]);

	//------------输出信号连线----------//
	assign o_Co = CarrayData[4];

	//生成每次的进位信号
	generate begin
		genvar i;
		//遍历4个bit
		for(i = 0;i < 4;i = i + 1)begin
			//实例化半加器
			Half_Adder_Interface Half_Adder_Interface_Inst(
				.i_A(i_A[i]),				//加数A
				.i_B(i_B[i]),				//加数B
				.o_Sum(P[i]),				//和数Sum
				.o_Co(G[i])					//进位Cout
			);
		end
	end endgenerate
	
	//求和
	generate begin
		genvar k;
		
		//遍历4个bit求和
		for(k = 0;k < 4;k = k + 1)begin
			assign o_Sum[k] = P[k] ^ CarrayData[k];
		end
	end endgenerate

endmodule

//超前进位加法器:LCA/CLA
module CarryLookahead_Adder_Interface
#(
	parameter DATA_WIDTH_4Bit	= 8'd1,
	parameter DATA_WIDTH = 4 << (DATA_WIDTH_4Bit - 1)
)
(
	input [DATA_WIDTH - 1:0]i_A,			//加数A
	input [DATA_WIDTH - 1:0]i_B,			//加数B
	input i_Ci,								//上一级进位Cin,无进位则给0
	output [DATA_WIDTH - 1:0]o_Sum,		//和数Sum
	output o_Co								//进位Cout
);

	//定义进位数据
	wire [DATA_WIDTH >> 2:0]CarrayData;
	
	//--------------数据连线------------//
	assign CarrayData[0] = i_Ci;
	
	//------------输出信号连线----------//
	assign o_Co = CarrayData[DATA_WIDTH >> 2];
	
	generate begin
		genvar i;
		
		//遍历
		for(i = 0;i < DATA_WIDTH >> 2;i = i + 1)begin
			//4bit LCA实例化
			CarryLookahead_Adder4bit_Interface CarryLookahead_Adder4bit_Interface_Inst(
				.i_A(i_A[i * 4 + 3:i * 4]),				//加数A
				.i_B(i_B[i * 4 + 3:i * 4]),				//加数B
				.i_Ci(CarrayData[i]),					//上一级进位Cin,无进位则给0
				.o_Sum(o_Sum[i * 4 + 3:i * 4]),			//和数Sum
				.o_Co(CarrayData[i + 1])				//进位Cout
			);
		end
	end endgenerate
	
endmodule

//进位旁路加法器:CSA,默认4bit,其他位宽可由4bit生成
module CarrySkip_Adder4bit_Interface(
	input [3:0]i_A,				//加数A
	input [3:0]i_B,				//加数B
	input i_Ci,					//上一级进位Cin,无进位则给0
	output [3:0]o_Sum,			//和数Sum
	output o_Co					//进位Cout
);
	
	//定义中间进位信号
	wire [3:0]P;			//Pi = Ai ^ Bi
	wire [4:0]CarrayData;
	
	//旁路选择信号
	wire sel_bypass;
	
	//--------------数据连线------------//
	//进位数据信号
	assign CarrayData[0] = i_Ci;
	
	//旁路选择信号
	assign sel_bypass = P[0] & P[1] & P[2] & P[3];
	
	//------------输出信号连线----------//
	assign o_Co = (sel_bypass & i_Ci) | ((~sel_bypass) & CarrayData[4]);

	//生成每次的进位信号
	generate begin
		genvar i;
		//遍历4个bit
		for(i = 0;i < 4;i = i + 1)begin
			//实例化半加器
			Half_Adder_Interface Half_Adder_Interface_Inst(
				.i_A(i_A[i]),				//加数A
				.i_B(i_B[i]),				//加数B
				.o_Sum(P[i]),				//和数Sum
				.o_Co()						//进位Cout
			);
			
			//实例化全加器
			Full_Adder_Interface Full_Adder_Interface_Inst(
				.i_A(i_A[i]),					//加数A
				.i_B(i_B[i]),					//加数B
				.i_Ci(CarrayData[i]),			//上一级进位Cin,无进位则给0
				.o_Sum(o_Sum[i]),				//和数Sum
				.o_Co(CarrayData[i + 1])		//进位Cout
			);
		end
	end endgenerate
	
endmodule

//进位旁路加法器:CSA
module CarrySkip_Adder_Interface
#(
	parameter DATA_WIDTH_4Bit	= 8'd1,
	parameter DATA_WIDTH = 4 << (DATA_WIDTH_4Bit - 1)
)
(
	input [DATA_WIDTH - 1:0]i_A,			//加数A
	input [DATA_WIDTH - 1:0]i_B,			//加数B
	input i_Ci,								//上一级进位Cin,无进位则给0
	output [DATA_WIDTH - 1:0]o_Sum,		//和数Sum
	output o_Co								//进位Cout
);
	//定义进位数据
	wire [DATA_WIDTH >> 2:0]CarrayData;
	
	//--------------数据连线------------//
	assign CarrayData[0] = i_Ci;
	
	//------------输出信号连线----------//
	assign o_Co = CarrayData[DATA_WIDTH >> 2];
	
	generate begin
		genvar i;
		
		//遍历
		for(i = 0;i < DATA_WIDTH >> 2;i = i + 1)begin
			//4bit CSA实例化
			CarrySkip_Adder4bit_Interface CarrySkip_Adder4bit_Interface_Inst(
				.i_A(i_A[i * 4 + 3:i * 4]),				//加数A
				.i_B(i_B[i * 4 + 3:i * 4]),				//加数B
				.i_Ci(CarrayData[i]),					//上一级进位Cin,无进位则给0
				.o_Sum(o_Sum[i * 4 + 3:i * 4]),			//和数Sum
				.o_Co(CarrayData[i + 1])				//进位Cout
			);
		end
	end endgenerate

endmodule

//进位选择加法器:CCA/CSA
module CarryChoose_Adder_Interface
#(
	parameter DATA_WIDTH_4Bit	= 8'd1,
	parameter DATA_WIDTH = 4 << (DATA_WIDTH_4Bit - 1)
)
(
	input [DATA_WIDTH - 1:0]i_A,			//加数A
	input [DATA_WIDTH - 1:0]i_B,			//加数B
	input i_Ci,								//上一级进位Cin,无进位则给0
	output [DATA_WIDTH - 1:0]o_Sum,		//和数Sum
	output o_Co								//进位Cout
);
	//定义进位数据
	wire [DATA_WIDTH >> 2:0]CarrayData;
	wire [DATA_WIDTH >> 2:0]CarrayData_zero;
	wire [DATA_WIDTH >> 2:0]CarrayData_one;
	
	//加法选择信号
	wire [DATA_WIDTH - 1:0]sum_zero;
	wire [DATA_WIDTH - 1:0]sum_one;
	
	//--------------数据连线------------//
	assign CarrayData[0] = i_Ci;
	
	//------------输出信号连线----------//
	assign o_Co = CarrayData[DATA_WIDTH >> 2];
	
	generate begin
		genvar i;

		//遍历
		for(i = 0;i < DATA_WIDTH >> 2;i = i + 1)begin
			if(i == 0) begin
				//4bit RCA/CRA
				CarryRipple_Adder_Interface #( .DATA_WIDTH(8'd4))CarryRipple_Adder_Interface_Inst(
					.i_A(i_A[i * 4 + 3:i * 4]),			//加数A
					.i_B(i_B[i * 4 + 3:i * 4]),			//加数B
					.i_Ci(CarrayData[i]),				//上一级进位Cin,无进位则给0
					.o_Sum(o_Sum[i * 4 + 3:i * 4]),		//和数Sum
					.o_Co(CarrayData[i + 1])			//进位Cout
				);
			end else begin
				//4bit RCA/CRA,初始进位为0
				CarryRipple_Adder_Interface #( .DATA_WIDTH(8'd4))CarryRipple_Adder_Interface_Inst0(
					.i_A(i_A[i * 4 + 3:i * 4]),			//加数A
					.i_B(i_B[i * 4 + 3:i * 4]),			//加数B
					.i_Ci(1'b0),						//上一级进位Cin,无进位则给0
					.o_Sum(sum_zero[i * 4 + 3:i * 4]),	//和数Sum
					.o_Co(CarrayData_zero[i + 1])		//进位Cout
				);
				//4bit RCA/CRA,初始进位为1
				CarryRipple_Adder_Interface #( .DATA_WIDTH(8'd4))CarryRipple_Adder_Interface_Inst1(
					.i_A(i_A[i * 4 + 3:i * 4]),			//加数A
					.i_B(i_B[i * 4 + 3:i * 4]),			//加数B
					.i_Ci(1'b1),						//上一级进位Cin,无进位则给0
					.o_Sum(sum_one[i * 4 + 3:i * 4]),	//和数Sum
					.o_Co(CarrayData_one[i + 1])		//进位Cout
				);
				
				//--------------数据连线------------//
				assign CarrayData[i + 1] = (CarrayData[i] & CarrayData_one[i+1]) | (~CarrayData[i] & CarrayData_zero[i + 1]);
				
				//------------输出信号连线----------//
				assign o_Sum[i * 4 + 3:i * 4] = CarrayData[i] ? sum_one[i * 4 + 3:i * 4] : sum_zero[i * 4 + 3:i * 4];
			end
		end
	end endgenerate

endmodule

//Brent Kung树型加法器运算符:
module BrentKung_LevelTree(
	input [1:0]i_G,
    input [1:0]i_P,
    output o_G,
    output o_P
);
	//------------输出信号连线----------//
	assign o_G = i_G[1] | (i_G[0] & i_P[1]);
	assign o_P = i_P[1] & i_P[0];

endmodule

//Kogge Stone树型加法器:KS
module KoggeStone_Adder_Interface
#(
	parameter DATA_WIDTH_4Bit	= 8'd1,
	parameter DATA_WIDTH = 4 << (DATA_WIDTH_4Bit - 1)
)
(
	input [DATA_WIDTH - 1:0]i_A,			//加数A
	input [DATA_WIDTH - 1:0]i_B,			//加数B
	input i_Ci,								//上一级进位Cin,无进位则给0
	output [DATA_WIDTH - 1:0]o_Sum,		//和数Sum
	output o_Co								//进位Cout
);

	//定义中间进位信号
	wire [DATA_WIDTH - 1:0]P;			//Pi = Ai | Bi
	wire [DATA_WIDTH - 1:0]G;			//Gi = Ai & Bi
	wire [DATA_WIDTH:0]CarrayData;		
	
	//--------------数据连线------------//
	assign P = i_A | i_B;
	assign G = i_A & i_B;
	
	//------------输出信号连线----------//
	assign o_Co = CarrayData[DATA_WIDTH];
	assign o_Sum = i_A ^ i_B ^ CarrayData[DATA_WIDTH - 1:0];
	
	//生成连线
	generate
		genvar i;
		
		//--------------数据连线------------//
		//进位数据初始连线
		assign CarrayData[0] = i_Ci;
		assign CarrayData[1] = G[0] | (P[0] & CarrayData[0]);
	
		//遍历剩余进位连线
		for(i = 2;i <= DATA_WIDTH;i = i + 1)begin
			assign CarrayData[i] = G[i - 1] | (P[i - 1] & G[i - 2]) | (P[i - 1] & P[i - 2] & CarrayData[i - 2]);
		end
		
	endgenerate
endmodule

//Brent Kung树型加法器:位宽必须是4的倍数,4,8,16,32;最大支持32位
module BrentKung_Adder_Interface
#(
	parameter DATA_WIDTH_4Bit	= 8'd1,
	parameter DATA_WIDTH = 4 << (DATA_WIDTH_4Bit - 1)
)
(
	input [DATA_WIDTH - 1:0]i_A,			//加数A
	input [DATA_WIDTH - 1:0]i_B,			//加数B
	input i_Ci,								//上一级进位Cin,无进位则给0
	output [DATA_WIDTH - 1:0]o_Sum,			//和数Sum
	output o_Co								//进位Cout
);

	//定义中间数据信号
	wire [DATA_WIDTH - 1:0]P;				//Pi = Ai | Bi
	wire [DATA_WIDTH - 1:0]G;				//Gi = Ai & Bi
	
	//定义中间树形计算数据信号
	wire [DATA_WIDTH / 2 - 1:0]Level_P[DATA_WIDTH_4Bit:0];
	wire [DATA_WIDTH / 2 - 1:0]Level_G[DATA_WIDTH_4Bit:0];
		
	//--------------数据连线------------//
	assign P = {i_A[DATA_WIDTH - 1:1] | i_B[DATA_WIDTH - 1:1],(i_A[0] | i_B[0]) & i_Ci};
	assign G = i_A & i_B;
	
	//------------输出信号连线----------//
	assign o_Co = Level_P[DATA_WIDTH_4Bit][DATA_WIDTH / 2 - 1] | Level_G[DATA_WIDTH_4Bit][DATA_WIDTH / 2 - 1];
		
	//批量实例化
	generate
		genvar i,j,k;	
		
		//第1级
		for(i = 0;i < DATA_WIDTH / 2;i = i + 1)begin
			//运算树实例化
			BrentKung_LevelTree BrentKung_LevelTree_Inst00(
				.i_G(G[2 * i + 1:2 * i]),
				.i_P(P[2 * i + 1:2 * i]),
				.o_G(Level_G[0][i]),
				.o_P(Level_P[0][i])
			);
		end
		
		//第2级
		for(i = 0;i < DATA_WIDTH / 4;i = i + 1)begin
			//运算树实例化
			BrentKung_LevelTree BrentKung_LevelTree_Inst10(
				.i_G({G[4 * i + 2],Level_G[0][2 * i]}),
				.i_P({P[4 * i + 2],Level_P[0][2 * i]}),
				.o_G(Level_G[1][2 * i]),
				.o_P(Level_P[1][2 * i])
			);
			
			//运算树实例化
			BrentKung_LevelTree BrentKung_LevelTree_Inst11(
				.i_G(Level_G[0][2 * i + 1:2 * i]),
				.i_P(Level_P[0][2 * i + 1:2 * i]),
				.o_G(Level_G[1][2 * i + 1]),
				.o_P(Level_P[1][2 * i + 1])
			);
		end
		
		//------------输出信号连线----------//
		assign o_Sum[3:0] = i_A[3:0] ^ i_B[3:0] ^ {Level_P[1][0] | Level_G[1][0], Level_P[0][0] | Level_G[0][0],P[0] | G[0], i_Ci};
		
		//如果总数大于等于8
		if(DATA_WIDTH >= 8)begin
			//第3级
			for(i = 0;i < DATA_WIDTH / 8;i = i + 1)begin
				//运算树实例化
				BrentKung_LevelTree BrentKung_LevelTree_Inst20(
					.i_G({G[8 * i + 4],Level_G[1][4 * i + 1]}),
					.i_P({P[8 * i + 4],Level_P[1][4 * i + 1]}),
					.o_G(Level_G[2][4 * i]),
					.o_P(Level_P[2][4 * i])
				);
				
				//运算树实例化
				BrentKung_LevelTree BrentKung_LevelTree_Inst21(
					.i_G({Level_G[0][4 * i + 2],Level_G[1][4 * i + 1]}),
					.i_P({Level_P[0][4 * i + 2],Level_P[1][4 * i + 1]}),
					.o_G(Level_G[2][4 * i + 1]),
					.o_P(Level_P[2][4 * i + 1])
				);
				
				//同样计算
				for(j = 0;j < 2;j = j + 1)begin
					//运算树实例化
					BrentKung_LevelTree BrentKung_LevelTree_Inst22(
						.i_G({Level_G[1][4 * i + 2 + j],Level_G[1][4 * i + 1]}),
						.i_P({Level_P[1][4 * i + 2 + j],Level_P[1][4 * i + 1]}),
						.o_G(Level_G[2][4 * i + 2 + j]),
						.o_P(Level_P[2][4 * i + 2 + j])
					);
				end
			end
			
			//------------输出信号连线----------//
			assign o_Sum[7:4] = i_A[7:4] ^ i_B[7:4] ^ {Level_P[2][2] | Level_G[2][2], Level_P[2][1] | Level_G[2][1], Level_P[2][0] | Level_G[2][0], Level_P[1][1] | Level_G[1][1]};
		end
		
		//如果总数大于等于16
		if(DATA_WIDTH >= 16)begin
			//第4级
			for(i = 0;i < DATA_WIDTH / 16;i = i + 1)begin
				//运算树实例化
				BrentKung_LevelTree BrentKung_LevelTree_Inst30(
					.i_G({G[16 * i + 8],Level_G[2][8 * i + 3]}),
					.i_P({P[16 * i + 8],Level_P[2][8 * i + 3]}),
					.o_G(Level_G[3][8 * i]),
					.o_P(Level_P[3][8 * i])
				);
				
				//同样计算
				for(j = 0;j < 2;j = j + 1)begin
					//运算树实例化
					BrentKung_LevelTree BrentKung_LevelTree_Inst31(
						.i_G({Level_G[j][8 * i + 4],Level_G[2][8 * i + 3]}),
						.i_P({Level_P[j][8 * i + 4],Level_P[2][8 * i + 3]}),
						.o_G(Level_G[3][8 * i + j + 1]),
						.o_P(Level_P[3][8 * i + j + 1])
					);
				end
				
				//运算树实例化
				BrentKung_LevelTree BrentKung_LevelTree_Inst32(
					.i_G({Level_G[1][8 * i + 5],Level_G[2][8 * i + 3]}),
					.i_P({Level_P[1][8 * i + 5],Level_P[2][8 * i + 3]}),
					.o_G(Level_G[3][8 * i + 3]),
					.o_P(Level_P[3][8 * i + 3])
				);
				
				//同样计算
				for(j = 0;j < 4;j = j + 1)begin
					//运算树实例化
					BrentKung_LevelTree BrentKung_LevelTree_Inst33(
						.i_G({Level_G[2][8 * i + j + 4],Level_G[2][8 * i + 3]}),
						.i_P({Level_P[2][8 * i + j + 4],Level_P[2][8 * i + 3]}),
						.o_G(Level_G[3][8 * i + j + 4]),
						.o_P(Level_P[3][8 * i + j + 4])
					);
				end
			end
			
			//定义高低位数据
			wire [3:0]L_Sum16;
			wire [3:0]H_Sum16;
			
			assign L_Sum16 = i_A[11:8] ^ i_B[11:8] ^ {Level_P[3][2] | Level_G[3][2], Level_P[3][1] | Level_G[3][1], Level_P[3][0] | Level_G[3][0], Level_P[2][3] | Level_G[2][3]};
			assign H_Sum16 = i_A[15:12] ^ i_B[15:12] ^ {Level_P[3][6] | Level_G[3][6], Level_P[3][5] | Level_G[3][5], Level_P[3][4] | Level_G[3][4], Level_P[3][3] | Level_G[3][3]};
			
			//------------输出信号连线----------//
			assign o_Sum[15:8] = {H_Sum16, L_Sum16};
		end
		
		//如果总数大于等于32
		if(DATA_WIDTH >= 32)begin
			//第5级
			for(i = 0;i < DATA_WIDTH / 32;i = i + 1)begin
				
				//运算树实例化
				BrentKung_LevelTree BrentKung_LevelTree_Inst40(
					.i_G({G[32 * i + 16],Level_G[3][16 * i + 7]}),
					.i_P({P[32 * i + 16],Level_P[3][16 * i + 7]}),
					.o_G(Level_G[4][16 * i]),
					.o_P(Level_P[4][16 * i])
				);
				
				//同样计算
				for(j = 0;j < 2;j = j + 1)begin
					//运算树实例化
					BrentKung_LevelTree BrentKung_LevelTree_Inst41(
						.i_G({Level_G[j][16 * i + 8],Level_G[3][16 * i + 7]}),
						.i_P({Level_P[j][16 * i + 8],Level_P[3][16 * i + 7]}),
						.o_G(Level_G[4][16 * i + j + 1]),
						.o_P(Level_P[4][16 * i + j + 1])
					);
				end
				
				//运算树实例化
				BrentKung_LevelTree BrentKung_LevelTree_Inst42(
					.i_G({Level_G[1][16 * i + 9],Level_G[3][16 * i + 7]}),
					.i_P({Level_P[1][16 * i + 9],Level_P[3][16 * i + 7]}),
					.o_G(Level_G[4][16 * i + 3]),
					.o_P(Level_P[4][16 * i + 3])
				);
				
				//同样计算
				for(j = 0;j < 4;j = j + 1)begin
					//运算树实例化
					BrentKung_LevelTree BrentKung_LevelTree_Inst43(
						.i_G({Level_G[2][16 * i + j + 8],Level_G[3][16 * i + 7]}),
						.i_P({Level_P[2][16 * i + j + 8],Level_P[3][16 * i + 7]}),
						.o_G(Level_G[4][16 * i + j + 4]),
						.o_P(Level_P[4][16 * i + j + 4])
					);
				end
				
				//计算
				for(j = 0;j < 8;j = j + 1)begin
					//运算树实例化
					BrentKung_LevelTree BrentKung_LevelTree_Inst44(
						.i_G({Level_G[3][16 * i + j + 8],Level_G[3][16 * i + 7]}),
						.i_P({Level_P[3][16 * i + j + 8],Level_P[3][16 * i + 7]}),
						.o_G(Level_G[4][16 * i + j + 8]),
						.o_P(Level_P[4][16 * i + j + 8])
					);
				end
			end
			
			//------------输出信号连线----------//
			//初值
			assign o_Sum[16] = i_A[16] ^ i_B[16] ^ (Level_P[3][7] | Level_G[3][7]);
			
			//15位连线方式一致
			for(i = 1;i < 16;i = i + 1)begin
				assign o_Sum[i + 16] = i_A[i + 16] ^ i_B[i + 16] ^ (Level_P[4][i - 1] | Level_G[4][i - 1]);
			end
			
		end
	endgenerate

endmodule


//3-2压缩加法器接口
module Compressed32_Adder_Interface
(
	input [2:0]i_X,						//加数,X[0]~X[2]
	output o_Sum,						//伪和
	output o_Carry						//进位
);
	//--------------计数数据------------//
	wire Xor_01;
	
	//------------其他信号连线----------//
	assign Xor_01 = i_X[0] ^ i_X[1];
	
	//------------输出信号连线----------//
	assign o_Sum = Xor_01 ^ i_X[2];
	assign o_Carry = Xor_01 ? i_X[2]:i_X[0];
	
endmodule

//4-2压缩加法器接口
module Compressed42_Adder_Interface
(
	input [3:0]i_X,						//加数,X[0]~X[3]
	input i_Ci,							//上一级进位Cin
	output o_Sum,						//伪和
	output o_Carry,						//进位
	output o_Co							//进位Cout
);
	//--------------计数数据------------//
	wire Xor_01;
	wire Xor_23;
	wire Xor_0123;
	
	//------------其他信号连线----------//
	assign Xor_01 = i_X[0] ^ i_X[1];
	assign Xor_23 = i_X[2] ^ i_X[3];
	assign Xor_0123 = Xor_01 ^ Xor_23;
	
	//------------输出信号连线----------//
	assign o_Sum = Xor_0123 ^ i_Ci;
	assign o_Co = Xor_01 ? i_X[2]:i_X[0];
	assign o_Carry = Xor_0123 ? i_Ci:i_X[3]; 
	
endmodule

//5-2压缩加法器接口
module Compressed52_Adder_Interface
(
	input [4:0]i_X,						//加数,X[0]~X[4]
	input [1:0]i_Ci,					//上一级进位Cin
	output o_Sum,						//伪和
	output o_Carry,						//进位
	output [1:0]o_Co					//进位Cout
);
	//--------------计数数据------------//
	wire Xor_01;
	wire Xor_34;
	wire Xor_012;
	wire Xor_34in;
	wire Xor_01234in;
	
	//------------其他信号连线----------//
	assign Xor_01 = i_X[0] ^ i_X[1];
	assign Xor_34 = i_X[3] ^ i_X[4];
	assign Xor_012 = Xor_01 ^ i_X[2];
	assign Xor_34in = Xor_34 ^ i_Ci[0];
	assign Xor_01234in = Xor_012 ^ Xor_34in;
	
	//------------输出信号连线----------//
	assign o_Sum = Xor_01234in ^ i_Ci[1];
	assign o_Co[0] = Xor_01 ? i_X[2]:i_X[0];
	assign o_Co[1] = Xor_34 ? i_Ci[0]:i_X[3];
	assign o_Carry = Xor_01234in ? i_Ci[1]:Xor_012; 
	
endmodule
