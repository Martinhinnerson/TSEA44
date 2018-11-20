`include "include/timescale.v"

module perf_top
  (
   wishbone.slave wb,
      // Master signals
   wishbone.monitor m0, m1
   );

   assign 	wb.rty = 1'b0;	// not used in this course
   assign 	wb.err = 1'b0;  // not used in this course
   assign 	wb.ack = wb.stb && wb.cyc; // change if needed

   logic [31:0] ctr0,ctr1,ctr2,ctr3;
   logic 	rst0,rst1,rst2,rst3;
   logic [31:0] out;
   
 
   assign rst0 = (wb.stb && wb.we && wb.adr == 32'h99000000);
   assign rst1 = (wb.stb && wb.we && wb.adr == 32'h99000004);
   assign rst2 = (wb.stb && wb.we && wb.adr == 32'h99000008);
   assign rst3 = (wb.stb && wb.we && wb.adr == 32'h9900000c);
   
   always_ff @(posedge wb.clk) begin
      if (wb.rst) begin
	 ctr0 <= 32'h0;
      end
      else begin 
	 if (rst0) begin
	    ctr0 <= 32'h0;
	 end
	 else if (m0.stb && m0.cyc) begin
	    ctr0 <= ctr0 + 1'b1;
	 end
      end
   end
      
   always_ff @(posedge wb.clk) begin
      if (wb.rst) begin
	 ctr1 <= 32'h0;
      end
      else begin 
	 if (rst1) begin
	    ctr1 <= 32'h0;
	 end
	 else if (m0.ack) begin
	    ctr1 <= ctr1 + 1'b1;
	 end
      end 
   end
   
   always_ff @(posedge wb.clk) begin
      if (wb.rst) begin
	 ctr2 <= 32'h0;
      end
      else begin
	 if (rst2) begin
	    ctr2 <= 32'h0;
	 end
	 else if (m1.stb && m1.cyc) begin
	    ctr2 <= ctr2 + 1'b1;
	 end
      end
   end

   always_ff @(posedge wb.clk) begin
      if (wb.rst) begin
	 ctr3 <= 32'h0;
      end
      else begin 
	 if (rst3) begin
	    ctr3 <= 32'h0;
	 end
	 else if (m1.ack) begin
	    ctr3 <= ctr3 + 1'b1;
	 end
      end
   end 

   always_comb begin
      case (wb.adr)
	32'h99000000: begin
	   out <= ctr0;
	end
	32'h99000004: begin
	   out <= ctr1;
	end
	32'h99000008: begin
	   out <= ctr2;
	end
	32'h9900000c: begin
	   out <= ctr3;
	end
	default: begin
	   out <= ctr0;
	end
      endcase // case (wb.adr)
   end

   assign wb.dat_i = out;
   
   
endmodule // perf_top
// Local Variables:
// verilog-library-directories:("." "or1200" "jpeg" "pkmc" "dvga" "uart" "monitor" "lab1" "dafk_tb" "eth" "wb" "leela")
// End:


