`include "include/timescale.v"

module q2(output[31:0] x_o, 
	  input [31:0] x_i, rec_i);

   logic [31:0] first_pixel;
   logic [31:0] second_pixel;

   assign first_pixel = {{16{x_i[31]}}, x_i[31:16]};
   assign second_pixel = {{16{x_i[15]}}, x_i[15:0]};

   logic [31:0] mult_first_pixel;
   logic [31:0] mult_second_pixel;

   assign mult_first_pixel = first_pixel * rec_i[31:16];
   assign mult_second_pixel = second_pixel * rec_i[15:0];

   logic [31:0] round_first_pixel;
   logic [31:0] round_second_pixel;

   logic 	rnd_first;
   logic 	rnd_second;
   
   assign rnd_first = (mult_first_pixel[16] && ((mult_first_pixel[31] == 1'b0) || (mult_first_pixel[15:0] != 16'h0000)));
   assign rnd_second = (mult_second_pixel[16] && ((mult_second_pixel[31] == 1'b0) || (mult_second_pixel[15:0] != 16'h0000)));
   
   
   assign round_first_pixel = {mult_first_pixel[31] , mult_first_pixel[31:17]} + rnd_first;
   assign round_second_pixel = {mult_second_pixel[31], mult_second_pixel[31:17]} + rnd_second;
   
   
   //assign round_first_pixel = (mult_first_pixel >>> 17) + (mult_first_pixel[16] && ((mult_first_pixel == 32'h80000000) || (mult_first_pixel == 32'hFFFF)));
   //assign round_second_pixel = (mult_second_pixel >>> 17) + (mult_second_pixel[16] && ((mult_second_pixel == 32'h80000000) || (mult_second_pixel == 32'hFFFF)));
   

   // Set output
   assign x_o = {round_first_pixel[15:0], round_second_pixel[15:0]};
   
endmodule //
// Local Variables:
// verilog-library-directories:("." ".." "../or1200" "../jpeg" "../pkmc" "../dvga" "../uart" "../monitor" "../lab1" "../dafk_tb" "../eth" "../wb" "../leela")
// End:
