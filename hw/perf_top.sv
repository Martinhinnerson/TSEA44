`include "include/timescale.v"

// ==============================================================
// perf_top: Module for the performance counters
// ==============================================================
module perf_top
   (
   wishbone.slave wb,
   // Master signals
   wishbone.monitor m0, m1, m6
   );
   
   assign 	wb.rty = 1'b0;	// not used in this course
   assign 	wb.err = 1'b0;  // not used in this course
   assign 	wb.ack = wb.stb && wb.cyc; // change if needed
   
   logic [31:0] m0_stb_cyc,m0_ack,m1_stb_cyc,m1_ack,m6_stb_cyc,m6_ack;
   logic 	rst_m0_stb_cyc,rst_m0_ack,rst_m1_stb_cyc,rst_m1_ack,rst_m6_stb_cyc,rst_m6_ack;
   logic [31:0] out;
   
   //Reset signals for the counters
   assign rst_m0_stb_cyc = (wb.stb && wb.we && wb.adr == 32'h99000000);
   assign rst_m0_ack = (wb.stb && wb.we && wb.adr == 32'h99000004);
   assign rst_m1_stb_cyc = (wb.stb && wb.we && wb.adr == 32'h99000008);
   assign rst_m1_ack = (wb.stb && wb.we && wb.adr == 32'h9900000c);
   assign rst_m6_stb_cyc = (wb.stb && wb.we && wb.adr == 32'h99000010);
   assign rst_m6_ack = (wb.stb && wb.we && wb.adr == 32'h99000014);
   
   //M0 stb & cyc counter
   always_ff @(posedge wb.clk) begin
      if (wb.rst) begin
         m0_stb_cyc <= 32'h0;
      end
      else begin 
         if (rst_m0_stb_cyc) begin
            m0_stb_cyc <= 32'h0;
         end
         else if (m0.stb && m0.cyc) begin
            m0_stb_cyc <= m0_stb_cyc + 1'b1;
         end
      end
   end
   
   //M0 ack counter
   always_ff @(posedge wb.clk) begin
      if (wb.rst) begin
         m0_ack <= 32'h0;
      end
      else begin 
         if (rst_m0_ack) begin
            m0_ack <= 32'h0;
         end
         else if (m0.ack) begin
            m0_ack <= m0_ack + 1'b1;
         end
      end 
   end
   
   //M1 stb & cyc counter
   always_ff @(posedge wb.clk) begin
      if (wb.rst) begin
         m1_stb_cyc <= 32'h0;
      end
      else begin
         if (rst_m1_stb_cyc) begin
            m1_stb_cyc <= 32'h0;
         end
         else if (m1.stb && m1.cyc) begin
            m1_stb_cyc <= m1_stb_cyc + 1'b1;
         end
      end
   end
   
   //M1 ack counter
   always_ff @(posedge wb.clk) begin
      if (wb.rst) begin
         m1_ack <= 32'h0;
      end
      else begin 
         if (rst_m1_ack) begin
            m1_ack <= 32'h0;
         end
         else if (m1.ack) begin
            m1_ack <= m1_ack + 1'b1;
         end
      end
   end

   //M6 stb & cyc counter
   always_ff @(posedge wb.clk) begin
      if (wb.rst) begin
         m6_stb_cyc <= 32'h0;
      end
      else begin 
         if (rst_m6_stb_cyc) begin
            m6_stb_cyc <= 32'h0;
         end
         else if (m6.stb && m6.cyc) begin
            m6_stb_cyc <= m6_stb_cyc + 1'b1;
         end
      end
   end
   
   //M6 ack counter
   always_ff @(posedge wb.clk) begin
      if (wb.rst) begin
         m6_ack <= 32'h0;
      end
      else begin 
         if (rst_m6_ack) begin
            m6_ack <= 32'h0;
         end
         else if (m6.ack) begin
            m6_ack <= m6_ack + 1'b1;
         end
      end 
   end
   
   
   always_comb begin
      case (wb.adr)
         32'h99000000: begin
            out <= m0_stb_cyc;
         end
         32'h99000004: begin
            out <= m0_ack;
         end
         32'h99000008: begin
            out <= m1_stb_cyc;
         end
         32'h9900000c: begin
            out <= m1_ack;
         end
	 32'h99000010: begin
            out <= m6_stb_cyc;
         end
         32'h99000014: begin
            out <= m6_ack;
         end
         default: begin
            out <= m0_stb_cyc;
         end
      endcase // case (wb.adr)
   end
   
   assign wb.dat_i = out;
   
   
endmodule // perf_top
// Local Variables:
// verilog-library-directories:("." "or1200" "jpeg" "pkmc" "dvga" "uart" "monitor" "lab1" "dafk_tb" "eth" "wb" "leela")
// End:


