// Title         : vending_machine.v
// Author      : Jae-Eon Jo (Jojaeeon@postech.ac.kr) 
//					   Dongup Kwon (nankdu7@postech.ac.kr) (2015.03.30)

`include "vending_machine_def.v"

module vending_machine (

	clk,							// Clock signal
	reset_n,						// Reset signal (active-low)
	
	i_input_coin,				// coin is inserted.
	i_select_item,				// item is selected.
	i_trigger_return,			// change-return is triggered 
	
	o_available_item,			// Sign of the item availability
	o_output_item,			// Sign of the item withdrawal
	o_return_coin				// Sign of the coin return
);

	// Ports Declaration
	// Do not modify the module interface
	input clk;
	input reset_n;
	
	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] i_select_item;
	input i_trigger_return;
		
	output [`kNumItems-1:0] o_available_item;
	output [`kNumItems-1:0] o_output_item;
	output [`kNumCoins-1:0] o_return_coin;
 
	// Normally, every output is register,
	//   so that it can provide stable value to the outside.
	reg [`kNumItems-1:0] o_available_item;
	reg [`kNumItems-1:0] o_output_item;
	reg [`kNumCoins-1:0] o_return_coin;
	
	// Net constant values (prefix kk & CamelCase)
	// Please refer the wikepedia webpate to know the CamelCase practive of writing.
	// http://en.wikipedia.org/wiki/CamelCase
	// Do not modify the values.
	wire [31:0] kkItemPrice [`kNumItems-1:0];	// Price of each item
	wire [31:0] kkCoinValue [`kNumCoins-1:0];	// Value of each coin
	assign kkItemPrice[0] = 400;
	assign kkItemPrice[1] = 500;
	assign kkItemPrice[2] = 1000;
	assign kkItemPrice[3] = 2000;
	assign kkCoinValue[0] = 100;
	assign kkCoinValue[1] = 500;
	assign kkCoinValue[2] = 1000;


	// NOTE: integer will never be used other than special usages.
	// Only used for loop iteration.
	// You may add more integer variables for loop iteration.
	integer i, j, k;

	// Internal states. You may add your own net & reg variables.
	reg [`kTotalBits-1:0] current_total;
	reg [`kItemBits-1:0] num_items [`kNumItems-1:0];
	reg [`kCoinBits-1:0] num_coins [`kNumCoins-1:0];
	
	// Next internal states. You may add your own net and reg variables.
	reg [`kTotalBits-1:0] current_total_nxt;
	reg [`kItemBits-1:0] num_items_nxt [`kNumItems-1:0];
	reg [`kCoinBits-1:0] num_coins_nxt [`kNumCoins-1:0];
	
	// Variables. You may add more your own registers.
	reg [`kTotalBits-1:0] input_total, output_total, return_total;
	reg [31:0] waitTime;
	reg waiting;

	// initiate values
	initial begin
		// TODO: initiate values, consider
		num_coins[0] = 'd100;
		num_coins[1] = 'd100;
		num_coins[2] = 'd100;
		num_items[0] = 'd100;
		num_items[1] = 'd100;
		num_items[2] = 'd100;
		num_items[3] = 'd100;
		num_items[4] = 'd100;
		current_total = 0;
		waitTime = 'd10;
		o_available_item = 0;
		o_output_item = 0;
		o_return_coin = 0;
		waiting = 1'b0;
	end

	
	// Combinational logic for the next states
	always @(*) begin
		// TODO: current_total_nxt
		// You don't have to worry about concurrent activations in each input vector (or array).
		input_total = kkCoinValue[0] * i_input_coin[0] + kkCoinValue[1] * i_input_coin[1] + kkCoinValue[2] * i_input_coin[2];
		output_total =  kkItemPrice[0] * i_select_item[0] + kkItemPrice[1] * i_select_item[1] + kkItemPrice[2] * i_select_item[2] + kkItemPrice[3] * i_select_item[3]
					+ kkCoinValue[0] * o_return_coin[0] + kkCoinValue[1] * o_return_coin[1] + kkCoinValue[2] * o_return_coin[2];
		
		// Calculate the next current_total state.
		current_total_nxt = current_total + input_total - output_total;
																   
		// TODO: num_items_nxt			
		begin for(i=0;i<4;i=i+1) 
			num_items_nxt[i] = num_items[i]-i_select_item[i];
		end
		// TODO: num_coins_nxt
		begin for(i=0;i<3;i=i+1) 
			num_coins_nxt[i] = num_coins[i]+i_input_coin[i]-o_return_coin[i];
		end
		// You may add more next states.
		if((i_input_coin == 0 && i_select_item == 0) || i_trigger_return == 1'b1) begin
			waiting = 1'b1;
		end
		else begin
			waiting = 1'b0;
		end
	end

	
	
	// Combinational logic for the outputs
	always @(*) begin
		// TODO: o_available_item
		begin for(i=0;i<4;i=i+1)
			if( (current_total >= kkItemPrice[i]) && (num_items[i] > 0) ) begin
				o_available_item[i] = 1'b1;
			end
			else begin
				o_available_item[i] = 1'b0;
			end
		end
	
		// TODO: o_output_item
		o_output_item = o_available_item & i_select_item;
		// TODO: o_return_coin
		if(waitTime <= 'd0) begin
			if(current_total >= kkCoinValue[2]) begin
				o_return_coin = 3'b100;
			end
			else if(current_total >= kkCoinValue[1]) begin
				o_return_coin = 3'b010;
			end
			else if(current_total >= kkCoinValue[0]) begin
				o_return_coin = 3'b001;
			end
			else begin
				o_return_coin = 3'b000;
			end
		end
		else begin
			o_return_coin = 3'b000;
		end


	end
 
	
	
	// Sequential circuit to reset or update the states
	always @(posedge clk) begin
		if (!reset_n) begin
			// TODO: reset all states.
			num_coins[0] = 'd100;
			num_coins[1] = 'd100;
			num_coins[2] = 'd100;
			num_items[0] = 'd100;
			num_items[1] = 'd100;
			num_items[2] = 'd100;
			num_items[3] = 'd100;
			num_items[4] = 'd100;
			current_total = 0;
			waitTime = 'd10;
			o_available_item = 0;
			o_output_item = 0;
			o_return_coin = 0;
			waiting = 1'b0;
		end
		else begin
			// TODO: update all states.
			current_total = current_total_nxt;
			
			for(i=0;i<3;i=i+1) begin
				num_coins[i] = num_coins_nxt[i];
			end
			for(i=0;i<4;i=i+1) begin
				num_items[i] = num_items_nxt[i];
			end
			if(waiting && (waitTime > 'd0)) begin
				waitTime = waitTime-1;
			end
			else if(waiting && (waitTime == 'd0)) begin
				waitTime = 'd0;
			end
			else begin
				waitTime = 'd10;
			end
		end
	end

endmodule
