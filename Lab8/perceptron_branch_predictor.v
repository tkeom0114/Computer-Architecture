`define BLOCK_NUM 256
`define BLOCK_BIT 8
`define HISTORY_BIT 16
`define HIT_TOT 17
`define THRESHOLD 44
`define WEIGHT_BIT 10

module perceptron_branch_predictor(clk, reset_n, input_ip, output_prediction, input_taken);
   input clk;
   input reset_n;
   input [63:0] input_ip;
   wire [63:0] input_ip;
   input input_taken;
   wire input_taken;
   output output_prediction;
   wire output_prediction;
   reg output_reg;
   reg pre_reg;

   // 256*17 matrix each of which has 32bits
   reg signed [`WEIGHT_BIT-1:0] predictor [0:`BLOCK_NUM-1][0:`HISTORY_BIT]; 
   reg [`HISTORY_BIT:0] history; // 16 bits for history and one bit for bias
   /* We should update the perceptron with the actual outcome of the previous ip
   so prev_block_index is needed to keep it */
   reg [`BLOCK_BIT-1:0] prev_block_index;
   reg signed [`WEIGHT_BIT-1:0] y; // output of the perceptron
   reg signed [`WEIGHT_BIT-1:0] temp [0:`HISTORY_BIT]; // used for dot product

   reg first; // used to check whether it is the first cycle or not
   integer i,j; // for for-loop
   assign output_prediction = pre_reg; // for the test, we use prev prediction

   initial begin
      output_reg <= 0;
      pre_reg <= 0;     
      y <= `WEIGHT_BIT'b0;
      first <= 1'b1; // At first, it should be 1 and except that, it is always 0
      history <= `HIT_TOT'b1; //  x_0 is always 1, providing a bias input
      prev_block_index <= `BLOCK_BIT'b11111111; 
      begin for(i=0;i<`BLOCK_NUM;i=i+1)
         begin for(j=0;j<`HISTORY_BIT+1;j=j+1)
            predictor[i][j] <= `WEIGHT_BIT'b0;
         end
      end
   end
   always @ (negedge reset_n) begin 
      output_reg <= 0;
      pre_reg <= 0;     
      y <= `WEIGHT_BIT'b0;
      first <= 1'b1; // At first, it should be 1 and except that, it is always 0
      history <= `HIT_TOT'b1; //  x_0 is always 1, providing a bias input
      prev_block_index <= `BLOCK_BIT'b11111111; 
      begin for(i=0;i<`BLOCK_NUM;i=i+1)
         begin for(j=0;j<`HISTORY_BIT+1;j=j+1)
            predictor[i][j] <= `WEIGHT_BIT'b0;
         end
      end
   end

   always @ (posedge clk) begin
      if(!first) begin
      /* if prediction was wrong OR the output y is within the threshold 
	  then train the perceptron */
         if(input_taken != output_reg || (y<8'd`THRESHOLD && y>-8'd`THRESHOLD)) begin
         /* When the branch outcome agrees with x_i(global branch history) 
		 then i-th weight is incremented,
         or decremented otherwise.*/
            predictor[prev_block_index][0] <= predictor[prev_block_index][0] 
				   + ((((~input_taken)&history[0]) || ((~history[0])&input_taken)) ?
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][1] <= predictor[prev_block_index][1] 
				   + ((((~input_taken)&history[1]) || ((~history[1])&input_taken)) ? 
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][2] <= predictor[prev_block_index][2] 
				   + ((((~input_taken)&history[2]) || ((~history[2])&input_taken)) ? 
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][3] <= predictor[prev_block_index][3]
				   + ((((~input_taken)&history[3]) || ((~history[3])&input_taken)) ?
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][4] <= predictor[prev_block_index][4]    
            	+ ((((~input_taken)&history[4]) || ((~history[4])&input_taken)) ?
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][5] <= predictor[prev_block_index][5]
				   + ((((~input_taken)&history[5]) || ((~history[5])&input_taken)) ? 
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][6] <= predictor[prev_block_index][6]  
				   + ((((~input_taken)&history[6]) || ((~history[6])&input_taken)) ? 
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][7] <= predictor[prev_block_index][7]
				   + ((((~input_taken)&history[7]) || ((~history[7])&input_taken)) ? 
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][8] <= predictor[prev_block_index][8]  
				   + ((((~input_taken)&history[8]) || ((~history[8])&input_taken)) ? 
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][9] <= predictor[prev_block_index][9]
				   + ((((~input_taken)&history[9]) || ((~history[9])&input_taken)) ? 
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][10] <= predictor[prev_block_index][10] 
				   + ((((~input_taken)&history[10]) || ((~history[10])&input_taken)) ? 
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][11] <= predictor[prev_block_index][11]
				   + ((((~input_taken)&history[11]) || ((~history[11])&input_taken)) ? 
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][12] <= predictor[prev_block_index][12]
				   + ((((~input_taken)&history[12]) || ((~history[12])&input_taken)) ? 
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][13] <= predictor[prev_block_index][13]
                + ((((~input_taken)&history[13]) || ((~history[13])&input_taken)) ?
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][14] <= predictor[prev_block_index][13]
				   + ((((~input_taken)&history[14]) || ((~history[14])&input_taken)) ? 
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][15] <= predictor[prev_block_index][15]   
				   + ((((~input_taken)&history[15]) || ((~history[15])&input_taken)) ? 
				   -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
            predictor[prev_block_index][16] <= predictor[prev_block_index][16]
			      + ((((~input_taken)&history[16]) || ((~history[16])&input_taken)) ? 
			      -`WEIGHT_BIT'b1 : `WEIGHT_BIT'b1);
         end
      end
	  /* Each element of history[i] is x_i; each is either 1(taken) or -1(not taken). 
      x_i are the bits of a global branch history shift register so it is moved to left one by one, 
      x_0 is always 1, providing a bias input */
      history <= {history[15:1],input_taken,1'b1};

      #1
      /* dot product of weight vector(predictor[][] and the input vector x_i(1 or -1) */
      temp[0] <= history[0] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][0] : -predictor[input_ip[`BLOCK_BIT-1:0]][0];
      temp[1] <= history[1] ? 
	   	predictor[input_ip[`BLOCK_BIT-1:0]][1] : -predictor[input_ip[`BLOCK_BIT-1:0]][1];
      temp[2] <= history[2] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][2] : -predictor[input_ip[`BLOCK_BIT-1:0]][2];
      temp[3] <= history[3] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][3] : -predictor[input_ip[`BLOCK_BIT-1:0]][3];
      temp[4] <= history[4] ? 
	   	predictor[input_ip[`BLOCK_BIT-1:0]][4] : -predictor[input_ip[`BLOCK_BIT-1:0]][4];
      temp[5] <= history[5] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][5] : -predictor[input_ip[`BLOCK_BIT-1:0]][5];
      temp[6] <= history[6] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][6] : -predictor[input_ip[`BLOCK_BIT-1:0]][6];
      temp[7] <= history[7] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][7] : -predictor[input_ip[`BLOCK_BIT-1:0]][7];
      temp[8] <= history[8] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][8] : -predictor[input_ip[`BLOCK_BIT-1:0]][8];
      temp[9] <= history[9] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][9] : -predictor[input_ip[`BLOCK_BIT-1:0]][9];
      temp[10] <= history[10] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][10] : -predictor[input_ip[`BLOCK_BIT-1:0]][10];
      temp[11] <= history[11] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][11] : -predictor[input_ip[`BLOCK_BIT-1:0]][11];
      temp[12] <= history[12] ? 
	   	predictor[input_ip[`BLOCK_BIT-1:0]][12] : -predictor[input_ip[`BLOCK_BIT-1:0]][12];
      temp[13] <= history[13] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][13] : -predictor[input_ip[`BLOCK_BIT-1:0]][13];
      temp[14] <= history[14] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][14] : -predictor[input_ip[`BLOCK_BIT-1:0]][14];
      temp[15] <= history[15] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][15] : -predictor[input_ip[`BLOCK_BIT-1:0]][15];
      temp[16] <= history[16] ? 
	  	   predictor[input_ip[`BLOCK_BIT-1:0]][16] : -predictor[input_ip[`BLOCK_BIT-1:0]][16];
	  #1
      /* So the final output of dot product is y below */
      y <= temp[0]+temp[1]+temp[2]+temp[3]+temp[4]+temp[5]+temp[6]+temp[7]
      +temp[8]+temp[9]+temp[10]+temp[11]+temp[12]+temp[13]+temp[14]+temp[15]
      +temp[16];
      #1
	  
	  // set previous prediction
	  pre_reg <= output_reg;
      // The branch is predicted as "not taken" when y is negative, or as "taken" otherwise.
      output_reg <= !(y<0); 
      prev_block_index <= input_ip[`BLOCK_BIT-1:0]; // keep the index of input_ip for the next cycle
      first <= 1'b0; // After the first cycle, it's always zero.
   end
endmodule