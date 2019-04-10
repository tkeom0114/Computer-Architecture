`timescale 1ns/1ns
`include "opcodes.v" 

module cpu(clk, reset_n, readM, writeM, address, data, num_inst, output_port, is_halted);
	input clk;
	input reset_n;
	
	output readM;
	output writeM;
	output [`WORD_SIZE-1:0] address;

	inout [`WORD_SIZE-1:0] data;

	output [`WORD_SIZE-1:0] num_inst;		// number of instruction during execution (for debuging & testing purpose)
	output [`WORD_SIZE-1:0] output_port;	// this will be used for a "WWD" instruction
	output is_halted;

	// TODO : Implement your multi-cycle CPU!
	

	reg [`WORD_SIZE-1:0] num_inst;
	reg [`WORD_SIZE-1:0] output_port;
	reg [`WORD_SIZE-1:0] address;	
	wire [`WORD_SIZE-1:0] data;
	wire [`WORD_SIZE-1:0] immdata;
	reg [`WORD_SIZE-1:0] instruction;
	reg [`WORD_SIZE-1:0] pc;
	reg [`WORD_SIZE-1:0] regFile[`NUM_REGS-1:0];
	reg readM;									
	reg writeM;
	reg readData;
	reg is_halted;
	wire reset_n;
	wire [`WORD_SIZE-1:0] Imm_next_pc;
	wire [`WORD_SIZE-1:0] Next_pc;
	wire Jump;
	wire JALorJALR;//0 if JAL, 1 if JALR
    wire Branch;
	wire Branch_cond;
	wire MemRead;
    wire MemtoReg;
    wire MemWrite;
    wire PCtoReg;
    wire ALUSrc;
    wire RegWrite;
	wire Halt;
	wire OpenPort;
	wire [`WORD_SIZE-1:0] ALUResult;
	wire [`WORD_SIZE-1:0] Immediate; 
	wire [3:0] ALUOp;
	wire [1:0] rs1;
	wire [1:0] rs2;
	wire [1:0] rd;
	wire [2:0] State;
	//tristate of data
	wire data_write;
	wire [`WORD_SIZE-1:0] data_out;
	assign Imm_next_pc = pc + 16'b1;
	control cont (.instruction(instruction), .clk(clk), .reset_n(reset_n), .Jump(Jump)
	, .OpenPort(OpenPort), .JALorJALR(JALorJALR), .Branch(Branch), .MemRead(MemRead)
	, .MemWrite(MemWrite), .MemtoReg(MemtoReg), .PCtoReg(PCtoReg), .ALUSrc(ALUSrc) 
	, .RegWrite(RegWrite), .Halt(Halt), .ALUOp(ALUOp), .rs1(rs1), .rs2(rs2), .rd(rd), .State(State));
	Immediate_Generator imm (.instruction(instruction), .Immediate(Immediate));
	ALU alu (.A(((Jump && !JALorJALR) || Branch)? (Imm_next_pc):regFile[rs1]),
	 .B(ALUSrc? Immediate:regFile[rs2]), 
	 .FuncCode(ALUOp), .C(ALUResult));
	condition cond (.a(regFile[rs1]), 
	.b(regFile[rs2]), 
	.condcode(instruction[13:12]), 
	.result(Branch_cond));
	
	// if it doesn't jump or branch to the other addresses, pc just increments
	// else we should use ALUResult which has the calculated address.
	assign Next_pc = (Jump || (Branch && Branch_cond))?  ALUResult:(Imm_next_pc);
	// if Load or Store, rt(=rs2) should be taken, else ALUResult is used.
	assign data_out = (MemRead || MemWrite)?  regFile[rs2] : ALUResult;
	// "data" is "inout" type, so when readData is 1, "data" plays as input else output.
	assign data = (readData)?  16'bz : data_out; 

	initial begin
		pc <= 16'b0;
		readM <= 1'b1;
		writeM <= 1'b0;
		address <= 16'b0;
		num_inst <= 16'b0;
		regFile[0] <= 16'b0;
		regFile[1] <= 16'b0;
		regFile[2] <= 16'b0;
		regFile[3] <= 16'b0;
		readData <= 1'b1;
	end

	always @(State) begin
		if(!reset_n) begin
			pc <= 16'b0;
			readM <= 1'b1;
			writeM <= 1'b0;
			address <= 16'b0;
			num_inst <= 16'b0;
			regFile[0] <= 16'b0;
			regFile[1] <= 16'b0;
			regFile[2] <= 16'b0;
			regFile[3] <= 16'b0;
			readData <= 1'b1;
		end
		else begin
			case(State)// In IF, all of works in memory
			`ID: begin 
				instruction <= data;
				readM <= 1'b0;
				writeM <= 1'b0;
			end
			`EX: begin
				is_halted <= Halt;
				if(OpenPort) begin
					output_port <= regFile[rs1];
				end
				if(MemRead || MemWrite) begin
					if(MemRead) begin
						readData <= 1'b1;
					end
					else begin
						readData <= 1'b0;
					end
					address <= ALUResult; // set the target address
					readM <= MemRead; // set signal based on MemRead and MemWrite
					writeM <= MemWrite;
				end
				else if(RegWrite) begin
					readM <= MemRead; // set signal based on MemRead and MemWrite
					writeM <= MemWrite;
				end
				else begin
					readData <= 1'b1; 
					num_inst <= num_inst+1;
					pc <= Next_pc;
					address <= Next_pc;
					readM <= 1'b1; 
					writeM <= 1'b0;
				end
			end
			`MEM: begin
				if(!RegWrite) begin
					readData <= 1'b1; 
					num_inst <= num_inst+1;
					pc <= Next_pc;
					address <= Next_pc;
					readM <= 1'b1; 
					writeM <= 1'b0;
				end
			end
			`WB: begin
				if(MemRead) begin
					regFile[rd] <= data;
				end
				else begin
					regFile[rd] <= (PCtoReg)? (Imm_next_pc) : data_out;
				end
				readData <= 1'b1; 
				num_inst <= num_inst+1;
				pc <= Next_pc;
				address <= Next_pc;
				readM <= 1'b1; 
				writeM <= 1'b0;
				
			end
			endcase	
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
