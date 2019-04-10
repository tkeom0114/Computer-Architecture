`timescale 1ns / 100ps

`define	NumBits	16

module ALU (A, B, FuncCode, C, OverflowFlag);
	input [`NumBits-1:0] A;
	input [`NumBits-1:0] B;
	input [3:0] FuncCode;
	output [`NumBits-1:0] C;
	output OverflowFlag;

	reg [`NumBits-1:0] C;
	reg OverflowFlag;
	reg [`NumBits:0] ltemp;
	reg [`NumBits-1:0] negB;

	initial begin
		C = 0;
		OverflowFlag = 0;		
	end					   	
	always @(*) begin
		OverflowFlag = 0;	
		if (FuncCode == 4'b0000) begin
			ltemp = {1'b1,A[15:0]} + {1'b1,B[15:0]};
			C = ltemp[15:0];
			if (A[15] == B[15] && ltemp[16] != ltemp[15]) begin
				OverflowFlag = 1;
			end
		end
		else if (FuncCode == 4'b0001) begin
			negB = ~B+1;
			ltemp = {1'b1,A[15:0]} + {1'b1,negB[15:0]};
			C = ltemp[15:0];
			if (A[15] == negB[15] && ltemp[16] != ltemp[15]) begin
				OverflowFlag = 1;
			end
		end
		else if (FuncCode == 4'b0010) begin
			C = A;
		end
		else if (FuncCode == 4'b0011) begin
			C = ~A;
		end
		else if (FuncCode == 4'b0100) begin
			C = A&B;
		end
		else if (FuncCode == 4'b0101) begin
			C = A|B;
		end
		else if (FuncCode == 4'b0110) begin
			C = ~(A&B);
		end
		else if (FuncCode == 4'b0111) begin
			C = ~(A|B);
		end
		else if (FuncCode == 4'b1000) begin
			C = ((~A)&B) | ((~B)&A);
		end
		else if (FuncCode == 4'b1001) begin
			C = ((~B)|A) & ((~A)|B);
		end
		else if (FuncCode == 4'b1010) begin
			C = A << 1;
		end
		else if (FuncCode == 4'b1011) begin
			C = A >> 1;
		end
		else if (FuncCode == 4'b1100) begin
			C = A << 1;
		end
		else if (FuncCode == 4'b1101) begin
			C = A >> 1;
			C = {A[15],C[14:0]};
		end
		else if (FuncCode == 4'b1110) begin
			C = ~A+1;
		end
		else begin
			C = 0;	
		end
	end
endmodule


