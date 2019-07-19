`timescale 1ns/1ns	

`include "opcodes.v"


module DMA_controller (clk,start, address, address_dma, BG, BR, offset, dma_end_interrupt, finish);
	/* inout setting */	
	
	/* input */
	input clk;
	wire clk;
	input start;
	wire start;
	input BG;
	wire BG;
	input [`WORD_SIZE-1:0] address;
	wire [`WORD_SIZE-1:0] address;
	input finish;
	wire finish;
    
	/* output */
	output BR;
	reg BR;
	output dma_end_interrupt;
	reg dma_end_interrupt;
	output [`WORD_SIZE-1:0] address_dma;
	reg [`WORD_SIZE-1:0] address_dma;
	output [`WORD_SIZE-1:0] offset;
	reg [`WORD_SIZE-1:0] offset;

	reg [`WORD_SIZE-1:0] remain;
	reg [`WORD_SIZE-1:0] dma_num;
	


	initial begin
		dma_end_interrupt = 1'b0;
		offset = 16'b0;
		BR = 1'b0;
		dma_num = 16'b0;
	end
	always @(posedge clk) begin
		if (start) begin
			BR <= 1'b1;
			address_dma <= address;
			remain <= `DEVICE_LENGTH;
			dma_num <= dma_num + 1;
		end
		if(BG && finish) begin
			if(remain != 16'd0) begin
				offset <= `DEVICE_LENGTH - remain;
				remain <= remain - 16'd4;
			end
			else begin
				$display("LOG: End DMA! #%d",dma_num);
				dma_end_interrupt <=1'b1;
				BR <= 1'b0;
			end
		end
		if(dma_end_interrupt) begin
			dma_end_interrupt <=1'b0;
		end
	end

endmodule
