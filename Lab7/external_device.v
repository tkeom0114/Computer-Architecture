`timescale 1ns/1ns	

`define WORD_SIZE 16
`define BLOCK_SIZE 64


// This is a SAMPLE. You should design your own external_device.
module external_device (data, BG, offset, dma_begin_interrupt);
	
	/* input */
	input BG;    
	input [`WORD_SIZE-1:0] offset;  
    
	/* output */
	output reg dma_begin_interrupt;
	output wire [`BLOCK_SIZE-1:0] data;
	
	/* external device storage */
	reg [`WORD_SIZE-1:0] stored_data [11:0];

	assign data = BG? {stored_data[offset+16'b11],stored_data[offset+16'b10],stored_data[offset+16'b01],stored_data[offset+16'b00]}:64'b0;
	
	
	/* Initialization */
	//assign data = ...
	initial begin
		dma_begin_interrupt <= 0;
		stored_data[0] <= 16'h0000;
		stored_data[1] <= 16'h1111;
		stored_data[2] <= 16'h2222;
		stored_data[3] <= 16'h3333;
		stored_data[4] <= 16'h4444;
		stored_data[5] <= 16'h5555;
		stored_data[6] <= 16'h6666;
		stored_data[7] <= 16'h7777;
		stored_data[8] <= 16'h8888;
		stored_data[9] <= 16'h9999;
		stored_data[10] <= 16'haaaa;
		stored_data[11] <= 16'hbbbb;
	end

	/* Interrupt CPU at some time */
	initial begin
		#50000;
		$display("LOG: Start DMA! #1");
		dma_begin_interrupt = 1;
		#60;						
		dma_begin_interrupt = 0;
		#(150000-60-50000)
		$display("LOG: Start DMA! #2");
		dma_begin_interrupt = 1;
		#60;						
		dma_begin_interrupt = 0;
	end
endmodule
