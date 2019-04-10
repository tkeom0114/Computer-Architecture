`include "hello_world.v"
module hello_world_tb();
reg clock_r, reset_r , enable_r;
wire [0:3]  counter_out;
initial begin
$display ("time \t clk reset enable counter");
$monitor ("%T \t %b %b %b %b", $time, clock_r , reset_r, enable_r, counter_out);
clock_r <= 1;
reset_r <= 0;
enable_r <= 0;
#5 enable_r <= 1;
#5 reset_r <= 1;
#10 reset_r <= 0;
#100 enable_r <= 0;
#5 $finish;
end 
always begin 
#5 clock_r <=  ~clock_r;
end 
counter U_counter (clock_r , reset_r , enable_r , counter_out);
endmodule 