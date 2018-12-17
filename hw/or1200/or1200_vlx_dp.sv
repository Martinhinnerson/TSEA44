`include "include/timescale.v"

module or1200_vlx_dp(/*AUTOARG*/
   // Outputs
   spr_dat_o, bit_reg_o, 
   // Inputs
   clk_i, rst_i, bit_vector_i, num_bits_to_write_i, spr_addr, 
   write_dp_spr_i, spr_dat_i
   );

   input clk_i;
   input rst_i;
   
   input [31:0] bit_vector_i;
   input [4:0] 	num_bits_to_write_i;
   input 	spr_addr;
   input 	write_dp_spr_i;
   input [31:0] spr_dat_i;
   input 	set_bit_op_i;	

   output [31:0] spr_dat_o;
   output [31:0] bit_reg_o;
   output 	 store_byte;
   

   reg [31:0] 	bit_reg;
   reg [5:0] 	bit_reg_wr_pos;

   typedef enum {IDLE, NEW_INSTR, STORING_MORE_BYTES} state_t;
   state_t state;

   logic [31:0] data_to_store;
   logic [31:0] last_data_to_store;
   logic [31:0] combined_code;
   logic [5:0] 	combined_wr_pos;


   logic [31:0] code;
   logic [4:0] 	size;
   assign code = bit_vector_i;
   assign size = num_bits_to_write_i;
   

   // combined_code, combined_wr_pos
   always_comb begin
      combined_code = bit_reg;
      combined_wr_pos = bit_reg_wr_pos;
      
      case (state)
	IDLE: begin
	   if (set_bit_op_i) begin
	      combined_code = bit_reg | (code << (bit_reg_wr_pos - size));
	      combined_wr_pos = bit_reg_wr_pos - size;
	   end
	end
	// Keep default values in the other cases
      endcase
   end


   logic insert_00;
   assign insert_00 = (last_data_to_store[7:0] == 8'hff);

   // store_byte
   // We want to store data if we have a complete byte to store,
   // OR if we need to insert 0x00
   assign store_byte = (combined_wr_pos < 16) | insert_00;
   

   // state transitions
   always_ff @(posedge clk_i) begin
      if (rst_i) begin
	 state <= IDLE;
      end
      else begin
	 case (state)
	   IDLE: begin
	      if (set_bit_op_i) begin
		 state <= NEW_INSTR;
	      end
	   end
	   NEW_INSTR: begin
	      if (store_byte) begin
		 state <= STORING_MORE_BYTES;
	      end
	      else begin
		 state <= IDLE;
	      end
	   end
	   STORING_MORE_BYTES: begin
	      if (~store_byte) begin
		 state <= IDLE;
	      end
	   end
	 endcase
      end
   end // always_ff @ (posedge clk_i)


   // last_data_to_store
   always_ff @(posedge clk_i) begin
      if (rst_i) begin
	 last_data_to_store <= 32'h0;
      end
      else begin
	 last_data_to_store <= data_to_store;
      end
   end

   
   
   
   // data_to_store
   // Set output data
   assign data_to_store = (state != IDLE) ? (insert_00 ? 32'h0 : {24'b0, combined_code[23:16]}) : 32'h0;
   assign bit_reg_o = data_to_store;
   

   //Here you must write code for packing bits to a register.
   always_ff @(posedge clk_i or posedge rst_i) begin
      if(rst_i) begin
	 bit_reg <= 0;
	 bit_reg_wr_pos <= 23;
      end
      else begin
	 if(write_dp_spr_i) begin
	    if(spr_addr) begin
	       bit_reg <= spr_dat_i;
	    end
	    else begin
	       bit_reg_wr_pos <= {26'b0,spr_dat_i[5:0]};
	    end
	 end
	 else begin
	    if (store_byte & ~insert_00) begin
	       // store, so shift
	       bit_reg <= {8'h0, combined_code[15:0], 8'h0};
	       bit_reg_wr_pos <= combined_wr_pos + 8;
	    end
	    else if ((store_byte & insert_00) | (~store_byte & ~insert_00)) begin
	       // store 00 before storing next byte, or nothing to store, so no shift
	       bit_reg <= combined_code;
	       bit_reg_wr_pos <= combined_wr_pos;
	    end
	 end
      end
   end // always_ff @ (posedge clk_i or posedge rst_i)

   
   

   assign spr_dat_o = spr_addr ? bit_reg : {26'b0,bit_reg_wr_pos};

endmodule // or1200_vlx_dp
// Local Variables:
// verilog-library-directories:("." ".." "../or1200" "../jpeg" "../pkmc" "../dvga" "../uart" "../monitor" "../lab1" "../dafk_tb" "../eth" "../wb" "../leela")
// End:
