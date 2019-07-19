`define BLOCK_NUM 256
`define BLOCK_BIT 8
`define TAG_BIT 56
`define ENTRY_BIT 58

module basic_branch_predictor(clk, reset_n, input_ip, output_prediction, input_taken);
input clk;
	input reset_n;
	input [63:0] input_ip; // 64-bit instruction address (branch instructions only)
	wire [63:0] input_ip;
	/* input_taken is branch outcome for the instruction address 
	given in the previous cycle */
	input input_taken;
	wire input_taken;
	output output_prediction; // Predicted branch outcome
	wire output_prediction;
	reg output_reg;
	
	// 256 entries, each of which has 58 bits
	reg [`TAG_BIT+1:0] predictor [0:`BLOCK_NUM-1]; 
	/* We should update the counter state of previous cycle's ip 
	so prev_block_index is needed to keep the prev_block */
	reg [`BLOCK_BIT-1:0] prev_block_index;
	/* reg first is used to check whether it is the first cycle or not
	because we do not update the predictor at the first cycle. */
	reg first;
	integer i; // It's for for-loop
	assign output_prediction = output_reg; // for the test, we use prev prediction

	initial begin
		output_reg <= 0;
		first <= 1'b1; // At first, it should be 1 and except that, it is always 0
		// Initialize each entry of the predictor with zero
		begin for(i=0;i<`BLOCK_NUM;i=i+1) 
			predictor[i] <= `ENTRY_BIT'b0;
		end
	end

	always @ (negedge reset_n) begin
		// reset all state asynchronously
		output_reg <= 0;
		first <= 1'b1; 
		begin for(i=0;i<`BLOCK_NUM;i=i+1) 
			predictor[i] <= `ENTRY_BIT'b0;
		end
	end

	always @ (posedge clk) begin
		if(!first) begin // Update the predictor after the first cycle
		/* 2-bit Saturation counter. 
		00: Strongly not taken
		01: Weakly not taken
		10: Weakly taken
		11: Strongly taken */
			if(input_taken) begin // If the actual branch outcome was 1, 
			/* Find the entry with prev_block_index and then update the state.
			the counter is incremented if the branch was taken, 
			and decremented otherwise.*/
				case(predictor[prev_block_index][1:0])
					2'b00 : predictor[prev_block_index][1:0] <= 2'b01;
					2'b01 : predictor[prev_block_index][1:0] <= 2'b10;
					2'b10 : predictor[prev_block_index][1:0] <= 2'b11;
					2'b11 : predictor[prev_block_index][1:0] <= 2'b11;
				endcase
			end
			else begin
				case(predictor[prev_block_index][1:0])
					2'b00 : predictor[prev_block_index][1:0] <= 2'b00;
					2'b01 : predictor[prev_block_index][1:0] <= 2'b00;
					2'b10 : predictor[prev_block_index][1:0] <= 2'b01;
					2'b11 : predictor[prev_block_index][1:0] <= 2'b10;
				endcase
			end
		end
		/* Save the previous prediction.
		The high bit of the counter is taken as the prediction */
		output_reg <= predictor[prev_block_index][1:1];
		/* If there is no entry that has the same tag 
		then set the entry with the input_ip's tag 
		and set the stage as "Strongly not taken" */
		if(predictor[input_ip[`BLOCK_BIT-1:0]][`ENTRY_BIT-1:2] != input_ip[63:`BLOCK_BIT]) begin 
			predictor[input_ip[`BLOCK_BIT-1:0]] <= {input_ip[63:`BLOCK_BIT],2'b00};
		end
		// keep the index of input_ip for the next cycle
		prev_block_index <= input_ip[`BLOCK_BIT-1:0]; 
		first <= 1'b0; // After the first cycle, it's always zero.
	end
endmodule
