`include "opcodes.v" 

module control(
	input wire [`WORD_SIZE-1:0] instruction,
    output reg Jump,
	output reg JALorJALR,//0 if JAL, 1 if JALR(using registers like JPR, JRL)
    output reg Branch,
    output reg MemRead,
    output reg MemtoReg,
    output reg MemWrite,
    output reg PCtoReg,
    output reg ALUSrc,
    output reg RegWrite,
	output reg Halt,
    output reg [3:0] ALUOp,
	output reg [1:0] rs1,
	output reg [1:0] rs2,
	output reg [1:0] rd
);
	wire [3:0]opcode;
    wire [5:0]funct;
	assign opcode = instruction[15:12];
	assign funct = instruction[5:0];
	
    always @(*) begin
		if (opcode == 4'd15) begin // if R
			// if ADD, SUB, AND, ORR, NOT, TCP, SHL, SHR
            if (funct < 6'd8) begin 
			    Jump <= 0;
				JALorJALR <= 1'bx;
			    Branch <= 0;
			    MemRead <= 0;
			    MemtoReg <= 0;
			    ALUOp <= funct; // funct indicates which operation should be done
			    MemWrite <= 0;
				PCtoReg <= 0;
			    ALUSrc <= 0;
			    RegWrite <= 1; // rd <-- alu result
				rs1 <= instruction[11:10];
				rs2 <= instruction[09:08];
				rd <= instruction[07:06];
				Halt <= 0;
            end
            else if (funct == 6'd25) begin // JPR
			    Jump <= 1; // this is jump
				JALorJALR <= 1; // using register
			    Branch <= 0;
			    MemRead <= 0;
			    MemtoReg <= 0;
			    ALUOp <= 4'b1000; // C = A
			    MemWrite <= 0;
				PCtoReg <= 0; // $pc <-- $rs
			    ALUSrc <= 0;
			    RegWrite <= 0;
				rs1 <= instruction[11:10];
				rs2 <= 2'bxx;
				rd <= 2'bxx;
				Halt <= 0;
            end
            else if (funct == 6'd26) begin //JRL
			    Jump <= 1; // this is jump
				JALorJALR <= 1; // using register
			    Branch <= 0;
			    MemRead <= 0;
			    MemtoReg <= 0;
			    ALUOp <= 4'b1000; // C = A
			    MemWrite <= 0;
				PCtoReg <= 1; // $2 <-- $pc $pc <-- $rs
			    ALUSrc <= 0;
			    RegWrite <= 1;
				rs1 <= instruction[11:10];
				rs2 <= 2'bxx;
				rd <= 2'b10;
				Halt <= 0;
            end
			else if (funct == 6'd29) begin //HALT
			    Jump <= 1'bx;
				JALorJALR <= 1'bx;
				Branch <= 1'bx;
				MemRead <= 1'bx;
				MemtoReg <= 1'bx;
				ALUOp <= 4'bxxxx;
				MemWrite <= 1'bx;
				PCtoReg <= 1'bx;
				ALUSrc <= 1'bx;
				RegWrite <= 1'bx;
				rs1 <= 2'bxx;
				rs2 <= 2'bxx;
				rd <= 2'bxx;
				Halt <= 1;
            end
            else begin //(RWD, WWD, ENI, DSI)
				Jump <= 1'bx;
				JALorJALR <= 1'bx;
				Branch <= 1'bx;
				MemRead <= 1'bx;
				MemtoReg <= 1'bx;
				ALUOp <= 4'bxxxx;
				MemWrite <= 1'bx;
				PCtoReg <= 1'bx;
				ALUSrc <= 1'bx;
				RegWrite <= 1'bx;
				rs1 <= 2'bxx;
				rs2 <= 2'bxx;
				rd <= 2'bxx;
				Halt <= 0;
            end
		end
		else if (opcode < 4'b0100) begin //if Bxx
			Jump <= 0;
			JALorJALR <= 1'bx;
			Branch <= 1;
			MemRead <= 0;
			MemtoReg <= 0;
			ALUOp <= 4'b0000;
			MemWrite <= 0;
			PCtoReg <= 0;
			ALUSrc <= 1; //{ (offset7)8 ## offset7..0 }
			RegWrite <= 0;
			rs1 <= instruction[11:10];
			rs2 <= instruction[09:08];
			rd <= 2'bxx;
			Halt <= 0;
		end
		else if (opcode < 4'd7) begin //if ADI,ORI,LHI
			Jump <= 0;
			JALorJALR <= 1'bx;
			Branch <= 0;
			MemRead <= 0;
			MemtoReg <= 0;
			MemWrite <= 0;
			PCtoReg <= 0;
			ALUSrc <= 1; // { (imm7)8 ## imm7..0 }
			RegWrite <= 1; // $rt <--
			rs1 <= instruction[11:10];
			rs2 <= 2'bxx;
			rd <= instruction[09:08]; // $rt <--
			Halt <= 0;
			case (opcode)
				4'b0100 : ALUOp <= 4'b0000; // ADI
				4'b0101 : ALUOp <= 4'b0011; // ORI
				4'b0110 : ALUOp <= 4'b1001; // LHI
				default : ALUOp <= 4'b1111; 
			endcase
		end
		else if (opcode == 4'd7) begin //if LWD
			Jump <= 0;
			JALorJALR <= 1'bx;
			Branch <= 0;
			MemRead <= 1; // M[$rs + ]
			MemtoReg <= 1; // $rt <-- M[]
			ALUOp <= 4'b0000;
			MemWrite <= 0;
			PCtoReg <= 0;
			ALUSrc <= 1; // { (offset7)8 ## offset7..0 }
			RegWrite <= 1; // $rt <--
			rs1 <= instruction[11:10];
			rs2 <= 2'bxx;
			rd <= instruction[09:08];
			Halt <= 0;
		end
		else if (opcode == 4'd8) begin //if SWD
			Jump <= 0;
			JALorJALR <= 1'bx;
			Branch <= 0;
			MemRead <= 0;
			MemtoReg <= 0;
			ALUOp <= 4'b0000;
			MemWrite <= 1; // M[$rs + { (offset7)8 ## offset7..0 }] <-- $rt
			PCtoReg <= 0;
			ALUSrc <= 1; // M[$rs + { (offset7)8 ## offset7..0 }] <-- $rt
			RegWrite <= 0;
			rs1 <= instruction[11:10];
			rs2 <= instruction[09:08];
			rd <= 2'bxx;
			Halt <= 0;
		end
		else if (opcode == 4'd9) begin //if JMP 
			// $pc <-- $pc15..12 ## target11..0
			Jump <= 1; 
			JALorJALR <= 0;
			Branch <= 0;
			MemRead <= 0;
			MemtoReg <= 0;
			ALUOp <= 4'b1010; // C = {A[15:12],B[11:0]};
			MemWrite <= 0;
			PCtoReg <= 0;
			ALUSrc <= 1; // $pc15..12 ## target11..0
			RegWrite <= 0;
			rs1 <= 2'bxx;
			rs2 <= 2'bxx;
			rd <= 2'bxx;
			Halt <= 0;
		end
		else if (opcode == 4'd10) begin //if JAL 
			// $2 <-- $pc $pc <-- $pc15..12 ## target11..0
			Jump <= 1;
			JALorJALR <= 0;
			Branch <= 0;
			MemRead <= 0;
			MemtoReg <= 0;
			ALUOp <= 4'b1010; //C = {A[15:12],B[11:0]};
			MemWrite <= 0;
			PCtoReg <= 1; // $2 <-- $pc
			ALUSrc <= 1; // $pc15..12 ## target11..0
			RegWrite <= 1; // $2 <--
			rs1 <= 2'bxx;
			rs2 <= 2'bxx;
			rd <= 2'b10; // $2 <--
			Halt <= 0;
		end
		else begin // when opcode does not belong to any case
			Jump <= 1'bx;
			JALorJALR <= 1'bx;
			Branch <= 1'bx;
			MemRead <= 1'bx;
			MemtoReg <= 1'bx;
			ALUOp <= 4'bxxxx;
			MemWrite <= 1'bx;
			PCtoReg <= 1'bx;
			ALUSrc <= 1'bx;
			RegWrite <= 1'bx;
			rs1 <= 2'bxx;
			rs2 <= 2'bxx;
			rd <= 2'bxx;
			Halt <= 0;
		end
	end
endmodule