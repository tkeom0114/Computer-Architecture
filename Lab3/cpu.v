`include "ALU.v"	   
`include "control.v"
`timescale 1ns/100ps

module cpu (readM, writeM, address, data, ackOutput, inputReady, reset_n, clk);
	output readM;	// read signal to memory							
	output writeM;	// write signal to memory	
	output [`WORD_SIZE-1:0] address;	// target memory address
	inout [`WORD_SIZE-1:0] data;	// data for reading or writing
	input ackOutput;	// signal from memory "data is written"
	input inputReady;	//signal from memory 'data is ready for reading"
	input reset_n;	// reset CPU
	input clk; // clock signal
// Fill it your codes	
									
	reg [`WORD_SIZE-1:0] address;	
	wire [`WORD_SIZE-1:0] data;
	wire [`WORD_SIZE-1:0] immdata;
	reg [`WORD_SIZE-1:0] instruction;
	reg [`WORD_SIZE-1:0] pc;
	reg [`WORD_SIZE-1:0] regFile[`NUM_REGS-1:0];
	reg readM;									
	reg writeM;
	reg readData;
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
	wire [`WORD_SIZE-1:0] ALUResult;
	wire [`WORD_SIZE-1:0] Immediate; 
	wire [3:0] ALUOp;
	wire [1:0] rs1;
	wire [1:0] rs2;
	wire [1:0] rd;
	//tristate of data
	wire data_write;
	wire [`WORD_SIZE-1:0] data_out;

	control cont (.instruction(instruction), .Jump(Jump), 
	.JALorJALR(JALorJALR), .Branch(Branch), .MemRead(MemRead), .MemWrite(MemWrite)
	, .MemtoReg(MemtoReg), .PCtoReg(PCtoReg), .ALUSrc(ALUSrc), .RegWrite(RegWrite), 
	.Halt(Halt), .ALUOp(ALUOp), .rs1(rs1), .rs2(rs2), .rd(rd));
	Immediate_Generator imm (.instruction(instruction), .Immediate(Immediate));
	ALU alu (.A(((Jump && !JALorJALR) || Branch)? (pc+16'b1):regFile[rs1]),
	 .B(ALUSrc? Immediate:regFile[rs2]), 
	 .FuncCode(ALUOp), .C(ALUResult));
	condition cond (.a(regFile[rs1]), 
	.b(regFile[rs2]), 
	.condcode(instruction[13:12]), 
	.result(Branch_cond));
	
	// if it doesn't jump or branch to the other addresses, pc just increments
	// else we should use ALUResult which has the calculated address.
	assign Imm_next_pc = (Jump || (Branch && Branch_cond))?  ALUResult:(pc+16'b1);
	// Whenever it does not halt, keep taking the next pc.
	assign Next_pc = (Halt)? pc:Imm_next_pc;
	// if Load or Store, rt(=rs2) should be taken, else ALUResult is used.
	assign data_out = (MemRead || MemWrite)?  regFile[rs2] : ALUResult;
	// "data" is "inout" type, so when readData is 1, "data" plays as input else output.
	assign data = (readData)?  16'bz : data_out; 

	initial begin
		pc <= 16'b0;
		address <= 16'b0;
		readM <= 1'b1;
		writeM <= 1'b0;
		
		regFile[0] <= 16'b0;
		regFile[1] <= 16'b0;
		regFile[2] <= 16'b0;
		regFile[3] <= 16'b0;
		readData <= 1'b0;
	end

	always @(posedge clk) begin//get data from memory and out next pc
		if (!reset_n) begin
			pc <= 16'b0;
			address <= 16'b0;
			readM <= 1'b1;
			writeM <= 1'b0;
			regFile[0] <= 16'b0;
			regFile[1] <= 16'b0;
			regFile[2] <= 16'b0;
			regFile[3] <= 16'b0;
			readData <= 1'b1;
		end
		else begin
			// if Load or Store
			if (MemRead || MemWrite) begin
				// wait till the memory work done properly
				wait ((inputReady && MemRead) || (ackOutput && MemWrite));
				//turn off the read/write signal to memory
				readM <= 1'b0;
				writeM <= 1'b0;
				//WriteBack
				if (RegWrite) begin
					readData <= 1'b1;
					#5;
					regFile[rd] <= data; // data from memory
				end
			end
			else if (RegWrite) begin //WriteBack
				regFile[rd] <= (PCtoReg)? (pc + 16'b1) : data_out; // PC+1 or ALUResult is written
			end
			pc <= Next_pc;
			address <= Next_pc;
			// turn on the read signal to memory to get next pc
			readM <= 1'b1; 
			writeM <= 1'b0;
		end
	end		

	always @(negedge clk) begin//get instruction from memory(data==instruction)
		if (!reset_n) begin
			pc <= 16'b0;
			address <= 16'b0;
			readM <= 1'b1;
			writeM <= 1'b0;
			regFile[0] <= 16'b0;
			regFile[1] <= 16'b0;
			regFile[2] <= 16'b0;
			regFile[3] <= 16'b0;
			readData <= 1'b1;
		end
		else begin
			wait (inputReady);
			readData <= 1'b1; 
			readM <= 1'b0;
			writeM <= 1'b0;
			#5;
			instruction <= data; // get data(instruction)
			#5;
			if(MemRead || MemWrite) begin
				address <= ALUResult; // set the target address
			end
			readM <= MemRead; // set signal based on MemRead and MemWrite
			writeM <= MemWrite;
			readData <= 1'b0;
			#5;
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
			2'b10: result <= (a > 0);  // BGZ
			2'b11: result <= (a < 0); // BLZ
		endcase
	end
endmodule

module Immediate_Generator (instruction,Immediate);
	output reg [`WORD_SIZE-1:0] Immediate;
	input wire [`WORD_SIZE-1:0] instruction;
	always @(*) begin
		case (instruction[15:12]) // opcode
			// { (offset7)8 ## offset7..0 } or { (imm7)8 ## imm7..0 }		
			4'd0, 4'd01, 4'd02, 4'd03, 4'd04, 4'd07, 4'd08: 
				Immediate <= {{8{instruction[7]}},instruction[7:0]}; 
			// ORI $rt <-- $rs | ( 08 ## imm7..0 )
			4'd5: Immediate <= {8'b0,instruction[7:0]};
			// LHI $rt <-- imm7..0 ## 08 
			4'd6: Immediate <= {instruction[7:0],8'b0};
			// JMP JAL $pc15..12 ## target11..0
			4'd9, 4'd10: Immediate <= instruction; 
			default: Immediate <= 16'b0; 
		endcase
	end
endmodule