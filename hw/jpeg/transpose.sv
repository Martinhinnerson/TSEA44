`include "include/timescale.v"

module transpose(input logic clk, wr , rd, 
		 input logic [95:0] in, 
		 output logic [95:0] ut);
   // Here you have to design the transpose memory
   logic [95:0] row01,row12,row23,row34,row45,row56,row67;

   row_reg row0(
		.clk(clk),
		.wr(wr),
		.rd(rd),
		.bits_i(in),
		.bits_o_rd(ut[11:0]),
		.bits_o_wr(row01));
   row_reg row1(
		.clk(clk),
		.wr(wr),
		.rd(rd),
		.bits_i(row01),
		.bits_o_rd(ut[23:12]),
		.bits_o_wr(row12));
   row_reg row2(
		.clk(clk),
		.wr(wr),
		.rd(rd),
		.bits_i(row12),
		.bits_o_rd(ut[35:24]),
		.bits_o_wr(row23));
   row_reg row3(
		.clk(clk),
		.wr(wr),
		.rd(rd),
		.bits_i(row23),
		.bits_o_rd(ut[47:36]),
		.bits_o_wr(row34));
   row_reg row4(
		.clk(clk),
		.wr(wr),
		.rd(rd),
		.bits_i(row34),
		.bits_o_rd(ut[59:48]),
		.bits_o_wr(row45));
   row_reg row5(
		.clk(clk),
		.wr(wr),
		.rd(rd),
		.bits_i(row45),
		.bits_o_rd(ut[71:60]),
		.bits_o_wr(row56));
   row_reg row6(
		.clk(clk),
		.wr(wr),
		.rd(rd),
		.bits_i(row56),
		.bits_o_rd(ut[83:72]),
		.bits_o_wr(row67));
   row_reg row7(
		.clk(clk),
		.wr(wr),
		.rd(rd),
		.bits_i(row67),
		.bits_o_rd(ut[95:84]),
		.bits_o_wr());

   
endmodule

// Local Variables:
// verilog-library-directories:("." ".." "../or1200" "../jpeg" "../pkmc" "../dvga" "../uart" "../monitor" "../lab1" "../dafk_tb" "../eth" "../wb" "../leela")
// End:

// Låt DCT läsa av första kolumnen innan rd sätts
module row_reg(input logic clk, wr, rd,
	       input logic [95:0] bits_i,
	       output logic [11:0] bits_o_rd,
	       output logic [95:0] bits_o_wr);

   logic [1:0] 			    input_select;
   assign input_select = {wr,rd};

   logic [95:0] 		    shift_reg;

   always_ff @(posedge clk) begin
      case (input_select)
	2'b10: begin
	   shift_reg <= bits_i;
	end
	2'b01: begin
	   shift_reg <= {shift_reg[83:0],16'h0};
	end
	default: begin
	end
      endcase
   end

   assign bits_o_rd = shift_reg[95:84];
   assign bits_o_wr = shift_reg;
      
endmodule
