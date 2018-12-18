`include "include/timescale.v"

module or1200_vlx_dp(/*AUTOARG*/
   // Outputs
   spr_dat_o, bit_reg_o, store_byte_o,
   // Inputs
   clk_i, rst_i, bit_vector_i, num_bits_to_write_i, spr_addr, 
   write_dp_spr_i, spr_dat_i, ack_i
   );

   input clk_i;
   input rst_i;
   input ack_i;
      
   input [31:0] bit_vector_i;
   input [4:0] 	num_bits_to_write_i;
   input 	spr_addr;
   input 	write_dp_spr_i;
   input [31:0] spr_dat_i;
   input 	set_bit_op_i;	

   output [31:0] spr_dat_o;
   output [31:0] bit_reg_o;
   output 	 store_byte_o;
   

   reg [31:0] 	bit_reg;
   reg [5:0] 	bit_reg_wr_pos;

   typedef enum {IDLE, STORE_FIRST_BYTE, STORE_SECOND_BYTE, STORE_THIRD_BYTE, STORE_FOURTH_BYTE} state_t;
   state_t state;

   logic [31:0] data_to_store;
   logic [31:0] last_data_to_store;
   logic [31:0] combined_code;
   logic [5:0] 	combined_wr_pos;
   logic 	store_byte;
   


   logic [31:0] code;
   logic [4:0] 	size;
   assign code = bit_vector_i;
   assign size = num_bits_to_write_i;

   
   assign combined_code = bit_reg | (code << (bit_reg_wr_pos - size));
   assign combined_wr_pos = bit_reg_wr_pos - size;
      


   logic insert_00;
   assign insert_00 = (last_data_to_store[7:0] == 8'hff);

   // store_byte
   // We want to store data if we have a complete byte to store,
   // OR if we need to insert 0x00
   always_comb begin
      if (state == IDLE & set_bit_op_i) begin
	 store_byte = (combined_wr_pos < 16) | insert_00;
      end else begin
	 store_byte = (bit_reg_wr_pos < 16) | insert_00;
      end
   end
   

   // state transitions
   always_ff @(posedge clk_i) begin
      if (rst_i) begin
	 state <= IDLE;
      end
      else begin
	 case (state)
	   IDLE: begin
	      if (set_bit_op_i & store_byte) begin
		 state <= STORE_FIRST_BYTE;
	      end
	   end
	   STORE_FIRST_BYTE: begin
	      if (store_byte & ack_i) begin
		 state <= STORE_SECOND_BYTE;
	      end
	      else if (~store_byte & ack_i) begin
		 state <= IDLE;
	      end
	   end
	   STORE_SECOND_BYTE: begin
	      if (store_byte & ack_i) begin
		 state <= STORE_THIRD_BYTE;
	      end
	      else if (~store_byte & ack_i) begin
		 state <= IDLE;
	      end
	   end
	   STORE_THIRD_BYTE: begin
	      if (store_byte & ack_i) begin
		 state <= STORE_FOURTH_BYTE;
	      end
	      else if (~store_byte & ack_i) begin
		 state <= IDLE;
	      end
	   end
	   STORE_FOURTH_BYTE: begin
	      if (ack_i) begin
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

   always_comb begin
      if (state == IDLE & set_bit_op_i & store_byte) begin
	 data_to_store = {24'b0, combined_code[23:16]};
      end else if (ack_i & set_bit_op_i & store_byte) begin
	 data_to_store = {24'b0, bit_reg[23:16]};
      end 
   end
   
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
	    if (ack_i & set_bit_op_i & store_byte) begin
	       if (insert_00) begin
		  bit_reg <= bit_reg;
		  bit_reg_wr_pos <= bit_reg_wr_pos;
	       end else begin
		  bit_reg <= {8'b0, bit_reg[15:0],8'b0};
		  bit_reg_wr_pos <= bit_reg_wr_pos + 8;
	       end
	    end else if (state == IDLE & store_byte & set_bit_op_i) begin
	       bit_reg <= {8'b0,combined_code[15:0],8'b0};
	       bit_reg_wr_pos <= combined_size + 8;
	    end else if (state == IDLE & ~store_byte & set_bit_op_i) begin
	       bit_reg <= combined_code;
	       bit_reg_wr_pos <= combined_size;
	    end
	 end // else: !if(write_dp_spr_i)
      end
   end // always_ff @ (posedge clk_i or posedge rst_i)

   
   

   assign spr_dat_o = spr_addr ? bit_reg : {26'b0,bit_reg_wr_pos};

endmodule // or1200_vlx_dp
// Local Variables:
// verilog-library-directories:("." ".." "../or1200" "../jpeg" "../pkmc" "../dvga" "../uart" "../monitor" "../lab1" "../dafk_tb" "../eth" "../wb" "../leela")
// End:
