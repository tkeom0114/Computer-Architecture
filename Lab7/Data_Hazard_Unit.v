`include "opcodes.v" 

module Data_Hazard_Unit(
	input wire isInst_ID_EX,
	input wire isInst_EX_MEM,
	input wire [1:0] rs1,
	input wire [1:0] rs2,
	input wire [1:0] rd_ID_EX,
	input wire [1:0] rd_EX_MEM,
	input wire MemRead_ID_EX,
	input wire RegWrite_ID_EX,
	input wire RegWrite_EX_MEM,
	input wire Jump,
	input wire JALorJALR,
	input wire Branch,
	input wire ALUSrc,
	output reg [1:0] ForwardA,
	output reg [1:0] ForwardB,
	output reg Stall
);
	always @(*) begin
		//rs1
		if(isInst_ID_EX && RegWrite_ID_EX && (rs1 == rd_ID_EX)) begin
			ForwardA <= 2'b1;
		end
		else if(isInst_EX_MEM && RegWrite_EX_MEM && (rs1 == rd_EX_MEM)) begin
			ForwardA <= 2'b10;
		end
		else begin
			ForwardA <= 2'b0;
		end
		//rs2 MEM_write이면 11은 안되도록 조정 필요
		if(isInst_ID_EX && RegWrite_ID_EX && (rs2 == rd_ID_EX)) begin
			ForwardB <= 2'b1;
		end
		else if(isInst_EX_MEM && RegWrite_EX_MEM && (rs2 == rd_EX_MEM)) begin
			ForwardB <= 2'b10;
		end
		else begin
			ForwardB <= 2'b0;
		end
		//stall
		if(isInst_ID_EX && MemRead_ID_EX && (rs1 == rd_ID_EX || rs2 == rd_ID_EX)) begin
			Stall <= 1'b1;
		end
		else begin
			Stall <= 1'b0;
		end
	end
endmodule