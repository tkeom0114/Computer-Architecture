`timescale 1ns/1ns
`include "control.v" 
`include "ALU.v"
`include "Data_Hazard_Unit.v"

module cpu(Clk, Reset_N, readM1, address1, data1, readM2, writeM2, address2, data2, num_inst, output_port, is_halted);
	input Clk;
	wire Clk;
	input Reset_N;
	wire Reset_N;
	output readM1;
	output [`WORD_SIZE-1:0] address1;//using to load instruction
	wire [`WORD_SIZE-1:0] address1;
	output readM2;
	output writeM2;
	output [`WORD_SIZE-1:0] address2;//using to load data
	input [`WORD_SIZE-1:0] data1;//it will be instruction
	wire [`WORD_SIZE-1:0] data1;
	inout [`WORD_SIZE-1:0] data2;//it will be data from memory
	wire [`WORD_SIZE-1:0] data2;
	output [`WORD_SIZE-1:0] num_inst;
	output [`WORD_SIZE-1:0] output_port;
	output is_halted;
	// TODO : Implement your pipelined CPU!(copied from Lab4, so we need to modify)

	reg [`WORD_SIZE-1:0] num_inst;
	reg [`WORD_SIZE-1:0] output_port;
	wire [`WORD_SIZE-1:0] data;
	reg [`WORD_SIZE-1:0] instruction;
	reg [`WORD_SIZE-1:0] pc;
	reg [`WORD_SIZE-1:0] regFile[`NUM_REGS-1:0];
	reg [`WORD_SIZE-1:0] A;
	reg [`WORD_SIZE-1:0] B;
	reg [`WORD_SIZE-1:0] address2;
	reg readM1;						
	reg readM2;						
	reg writeM2;
	reg readData2;
	reg is_halted;
	//IF_ID
	reg isInst_IF_ID;
	reg [`WORD_SIZE-1:0] expPC_IF_ID;
	//ID_EX
	reg [84:0] reg_EX;
	//EX_MEM
	reg [84:0] reg_MEM;
	//HALT
	reg is_halted_MEM_WB;
	//wires
	wire [`WORD_SIZE-1:0] Imm_next_pc;
	wire [`WORD_SIZE-1:0] Next_pc;
	wire [20:0] signal;
	wire [1:0] ForwardA;
	wire [1:0] ForwardB;
	wire [`WORD_SIZE-1:0] ALUResult;
	wire [`WORD_SIZE-1:0] Immediate; 
	wire [`WORD_SIZE-1:0] wireA;
	wire [`WORD_SIZE-1:0] wireB;
	wire Flush;
	wire Stall;
	//tristate of data
	wire data_write;
	wire [`WORD_SIZE-1:0] WriteData;

	assign address1 = pc;
	assign Imm_next_pc = pc + 16'b1;
	control cont (.instruction(instruction), .signal(signal));
	Immediate_Generator imm (.instruction(instruction), .Immediate(Immediate));
	ALU alu (.A(A), .B(B), .FuncCode(reg_EX[`ALUOp+3:`ALUOp]), .C(ALUResult));
	condition cond (.a(reg_EX[`rs1Data+`WORD_SIZE-1:`rs1Data]), .b(reg_EX[`rs2Data+`WORD_SIZE-1:`rs2Data]), .condcode(reg_EX[82:81]), .result(Branch_cond));
	Mux4Way muxa (.Src(ForwardA), .A(regFile[signal[`rs1+1:`rs1]]), .B(ALUResult), .C(WriteData), .D(expPC_IF_ID), .result(wireA));
	Mux4Way muxb (.Src(ForwardB), .A(regFile[signal[`rs2+1:`rs2]]), .B(ALUResult) , .C(WriteData), .D(Immediate), .result(wireB));
	Data_Hazard_Unit dhu (.isInst_ID_EX(reg_EX[`isInst]), .isInst_EX_MEM(reg_MEM[`isInst]), .rs1(signal[`rs1+1:`rs1]), .rs2(signal[`rs2+1:`rs2]),
	.rd_ID_EX(reg_EX[`rd+1:`rd]), .rd_EX_MEM(reg_MEM[`rd+1:`rd]), .MemRead_ID_EX(reg_EX[`MemRead]), .RegWrite_ID_EX(reg_EX[`RegWrite]),
	.RegWrite_EX_MEM(reg_MEM[`RegWrite]), .Jump(signal[`Jump]), .Branch(signal[`Branch]),
	.ALUSrc(signal[`ALUSrc]), .ForwardA(ForwardA), .ForwardB(ForwardB), .Stall(Stall));
	// if it doesn't jump or branch to the other addresses, pc just increments
	// else we should use ALUResult which has the calculated address.
	// if Load or Store, rt(=rs2) should be taken, else ALUResult is used.
	// "data" is "inout" type, so when readData is 1, "data" plays as input else output.
	assign data2 = (readData2)?  16'bz : reg_MEM[`rs2Data + `WORD_SIZE -1:`rs2Data]; 
	assign WriteData = (reg_MEM[`MemtoReg])? data2:reg_MEM[`ALUResult + `WORD_SIZE -1:`ALUResult];
	assign Flush = reg_EX[`isInst] && (reg_EX[`Jump] || (reg_EX[`Branch] && Branch_cond));
	initial begin
		pc <= 16'b0;
		readM1 <= 1'b1;
		readM2 <= 1'b1;
		writeM2 <= 1'b0;
		num_inst <= 16'b0;
		regFile[0] <= 16'b0;
		regFile[1] <= 16'b0;
		regFile[2] <= 16'b0;
		regFile[3] <= 16'b0;
		reg_EX <= 85'b0;
		reg_MEM <=85'b0;
		isInst_IF_ID <= 1'b0;
		is_halted_MEM_WB <= 1'b0;
	end

	always @(posedge Clk) begin//modify intermediate registers
		if(!Reset_N) begin
			pc <= 16'b0;
			readM1 <= 1'b1;
			readM2 <= 1'b1;
			writeM2 <= 1'b0;
			num_inst <= 16'b0;
			regFile[0] <= 16'b0;
			regFile[1] <= 16'b0;
			regFile[2] <= 16'b0;
			regFile[3] <= 16'b0;
			reg_EX <= 85'b0;
			reg_MEM <=85'b0;
			isInst_IF_ID <= 1'b0;
			is_halted_MEM_WB <= 1'b0;
		end
		else begin
			if(!Stall) begin
				//IF
				pc <= Flush? ALUResult:Imm_next_pc;
				//ID
				isInst_IF_ID <= !Flush;
				expPC_IF_ID <= Imm_next_pc;
				instruction <= data1;
				//EXE
				reg_EX <= Flush? 85'b0:{instruction,isInst_IF_ID,expPC_IF_ID,wireB,wireA,signal[19:0]};
				A <= (signal[`Jump] && !signal[`JALorJALR]) || signal[`Branch]? expPC_IF_ID:wireA;
				B <= signal[`ALUSrc]?  Immediate:wireB;
			end
			else begin
				reg_EX <= 85'b0;
			end
			//MEM
			reg_MEM <= {ALUResult,reg_EX[68:0]};
			readM2 <= reg_EX[`isInst]? reg_EX[`MemRead]:1'b0; 
			writeM2 <= reg_EX[`isInst] && reg_EX[`MemWrite];
			readData2 <= !reg_EX[`MemWrite];
			address2 <= ALUResult;		
			//WB
			is_halted_MEM_WB <= reg_MEM[`isInst]? reg_MEM[`Halt]:1'b0;
			if(reg_MEM[`isInst] && reg_MEM[`OpenPort]) begin
				output_port <= reg_MEM[`rs1Data + `WORD_SIZE - 1:`rs1Data];
			end
			if(reg_MEM[`isInst] && reg_MEM[`RegWrite]) begin
				regFile[reg_MEM[`rd+1:`rd]] <= (reg_MEM[`PCtoReg])? reg_MEM[`expPC+`WORD_SIZE-1:`expPC]: WriteData;
			end
			num_inst <= (reg_MEM[`isInst])? num_inst+1:num_inst; 
			//HALT
			is_halted <= is_halted_MEM_WB;
		end
	end
endmodule


module condition (a,b,condcode,result);
	output reg result;
	input wire [15:0] a;
	input wire [15:0] b;
	input wire [1:0] condcode;
	always @(*) begin
		case (condcode)
			2'b00: result <= (a != b); //BNE
			2'b01: result <= (a == b); // BEQ
			2'b10: result <= (a != 16'b0 && a[15] == 0);  // BGZ (a>0)
			2'b11: result <= (a[15] == 1); // BLZ(a<0)
		endcase
	end
endmodule


module Immediate_Generator (instruction,Immediate);
	output reg [`WORD_SIZE-1:0] Immediate;
	input wire [`WORD_SIZE-1:0] instruction;
	always @(*) begin
		case (instruction[15:12]) // opcode
			// { (offset7)8 ## offset7..0 } or { (imm7)8 ## imm7..0 }		
			`BNE_OP, `BEQ_OP, `BGZ_OP, `BLZ_OP, `ADI_OP, `LWD_OP, `SWD_OP: 
				Immediate <= {{8{instruction[7]}},instruction[7:0]}; 
			// ORI $rt <-- $rs | ( 08 ## imm7..0 )
			`ORI_OP: Immediate <= {8'b0,instruction[7:0]};
			// LHI $rt <-- imm7..0 ## 08 
			`LHI_OP: Immediate <= {instruction[7:0],8'b0};
			// JMP JAL $pc15..12 ## target11..0
			`JMP_OP, `JAL_OP: Immediate <= instruction; 
			default: Immediate <= 16'b0; 
		endcase
	end
endmodule


module Mux4Way(Src,A,B,C,D,result);
	input wire [1:0] Src;
	input wire [`WORD_SIZE-1:0] A;
	input wire [`WORD_SIZE-1:0] B;
	input wire [`WORD_SIZE-1:0] C;
	input wire [`WORD_SIZE-1:0] D;
	output wire [`WORD_SIZE-1:0] result;
	wire [`WORD_SIZE-1:0] temp1;
	wire [`WORD_SIZE-1:0] temp2;
	assign temp1 = Src[0]? B:A;
	assign temp2 = Src[0]? D:C;
	assign result = Src[1]? temp2:temp1;
endmodule