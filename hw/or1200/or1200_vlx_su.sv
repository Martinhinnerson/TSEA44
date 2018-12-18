`include "include/timescale.v"

module or1200_vlx_su(/*AUTOARG*/
   // Outputs
   vlx_addr_o, dat_o, last_byte_o, store_byte_o, 
   // Inputs
   clk_i, rst_i, ack_i, dat_i, store_byte_i, set_init_addr_i
   );
   
   input clk_i;
   input rst_i;
   input ack_i; //ack is high when write completes
   
   input [31:0] dat_i; //the data to be stored
   input 	store_byte_i; //start storing data in the next clock cycle if high 	
   input 	set_init_addr_i; //set the address in the next clock cycle if high
   
   output 	reg [31:0] vlx_addr_o; //address where data is stored
   output 	reg [31:0] dat_o; //actual data stored 
   output 	last_byte_o; //high when the last byte is being stored.
   output 	store_byte_o; //high when a byte should be stored


   // Not using last_byte_o right now, do we need to???
   
   
   //You must extend this module

   // Set the address of where to store, vlx_addr_o
   always_ff @(posedge clk_i) begin
      if(rst_i) begin
         vlx_addr_o <= 0;
      end
      else if (set_init_addr_i) begin
         vlx_addr_o <= dat_i;
         // Might need to set this to dat_i - 1 ???
      end
      else if (store_byte_i) begin
         vlx_addr_o <= vlx_addr_o + 1;
         // Always increases, should not on first, but if init is -1 it is ok???
      end
   end

   // Set the data to store, dat_o
   always_ff @(posedge clk_i) begin
      if (rst_i) begin
         dat_o <= 0;
      end
      else if (store_byte_i) begin
         dat_o <= dat_i;
      end
   end


   // Set store_byte_o when we want to write
   // Use a reg to keep value until until we don't want to write any more
   logic store_byte_o_reg;
   always_ff @(posedge clk_i) begin
      if (rst_i) begin
         store_byte_o_reg <= 1'b0;
      end
      else begin
         if (store_byte_i) begin
            store_byte_o_reg <= 1'b1;
         end
         else if (ack_i && ~store_byte_i) begin
            store_byte_o_reg <= 1'b0;
         end
      end
   end

   assign store_byte_o = store_byte_o_reg;


   
endmodule // or1200_vlx_su
// Local Variables:
// verilog-library-directories:("." ".." "../or1200" "../jpeg" "../pkmc" "../dvga" "../uart" "../monitor" "../lab1" "../dafk_tb" "../eth" "../wb" "../leela")
// End:
