//////////////////////////////////////////////////////////////////////
////                                                              ////
////  DAFK JPEG Accelerator top                                   ////
////                                                              ////
////  This file is part of the DAFK Lab Course                    ////
////  http://www.da.isy.liu.se/courses/tsea02                     ////
////                                                              ////
////  Description                                                 ////
////  DAFK JPEG Top Level SystemVerilog Version                   ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author:                                                     ////
////      - Olle Seger, olles@isy.liu.se                          ////
////      - Andreas Ehliar, ehliar@isy.liu.se                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2005-2007 Authors                              ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
`include "include/timescale.v"
`include "include/dafk_defines.v"

  typedef     enum {TST, CNT, RST} op_t;
  typedef struct packed
	  {op_t op;
	   logic rden;
	   logic reg1en;
	   logic mux1;
	   logic dcten;
	   logic twr;
	   logic trd;
	   logic [1:0] mux2;
	   logic wren;
	   } mmem_t;

  module jpeg_top(wishbone.slave wb, wishbone.master wbm);

   logic 		 state;
   logic [6:0] 		 mpc;
   logic [31:0] 	 dout_res;
   logic 		 ce_in, ce_ut;
   logic [5:0] 		 rdc;
   logic [4:0] 		 wrc;

   logic [31:0] 	 dob, ut_doa;
   
   logic [0:7][11:0] 	 x, in, ut;

   logic [0:7][15:0] 	 y;   

   logic [31:0] 	 reg1;
   
   logic [31:0] 	 q, dia;
   logic [31:0] 	 doa;
   logic 		 csren;
   logic [7:0] 		 csr;
   logic 		 clr;
   mmem_t 	mmem;

   logic 		 dmaen;

   logic 		 dct_busy;
   logic 		 dma_start_dct;

   // ********************************************
   // *          Wishbone interface              *
   // ********************************************

   assign 	 ce_in = wb.stb && (wb.adr[12:11]==2'b00); // Input mem
   assign 	 ce_ut = wb.stb && (wb.adr[12:11]==2'b01); // Output mem
   assign 	 csren = wb.stb && (wb.adr[12:11]==2'b10); // Control reg
   assign        dmaen = wb.stb && (wb.adr[12:11]==2'b11); // DMA control
   
   
   // ack FSM
   // You must create the wb.ack signal somewhere...
   
   // You must change the error signal when you
   // have implemented your design
   assign wb.err = wb.stb;

   assign wb.rty = 1'b0;
   
   // Signals to the blockrams...
   logic [31:0] dma_bram_data;
   logic [8:0]  dma_bram_addr;
   logic        dma_bram_we;

   logic [31:0] bram_data;
   logic [8:0]  bram_addr;
   logic        bram_we;
   logic        bram_ce;

   logic [31:0] wb_dma_dat;

   // You must create the signals to the block ram somewhere...
   
   
   jpeg_dma dma
     (
      .clk_i(wb.clk), .rst_i(wb.rst),

      .wb_adr_i	(wb.adr),
      .wb_dat_i	(wb.dat_o),
      .wb_we_i	(wb.we),
      .dmaen_i	(dmaen),
      .wb_dat_o	(wb_dma_dat),

      .wbm(wbm),
      
      .dma_bram_data		(dma_bram_data[31:0]),
      .dma_bram_addr		(dma_bram_addr[8:0]),
      .dma_bram_we		(dma_bram_we),

      .start_dct (dma_start_dct),
      .dct_busy (dct_busy)
      );
   
   RAMB16_S36_S36 #(.SIM_COLLISION_CHECK("NONE")) inmem
     (// WB read & write
      .CLKA(wb.clk), .SSRA(wb.rst),
      .ADDRA(bram_addr),
      .DIA(bram_data), .DIPA(4'h0), 
      .ENA(bram_ce), .WEA(bram_we), 
      .DOA(doa), .DOPA(),
      // DCT read
      .CLKB(wb.clk), .SSRB(wb.rst),
      .ADDRB({3'h0,rdc}),
      .DIB(32'h0), .DIPB(4'h0), 
      .ENB(1'b1),.WEB(1'b0), 
      .DOB(dob), .DOPB());
   
   RAMB16_S36_S36 #(.SIM_COLLISION_CHECK("NONE")) utmem
     (// DCT write
      .CLKA(wb.clk), .SSRA(wb.rst),
      .ADDRA({4'h0,wrc}),
      .DIA(q), .DIPA(4'h0), .ENA(1'b1),
      .WEA(mmem.wren), .DOA(ut_doa), .DOPA(),
      // WB read & write
      .CLKB(wb.clk), .SSRB(wb.rst),
      .ADDRB(wb.adr[10:2]),
      .DIB(wb.dat_o), .DIPB(4'h0), .ENB(ce_ut),
      .WEB(wb.we), .DOB(dout_res), .DOPB());

   // You must create the wb.dat_i signal somewhere...

   // You must also create the control logic...
   				      
   // 8 point DCT
   // control: dcten
   dct dct0
     (.y(y), .x(x), 
      .clk_i(wb.clk), .en(mmem.dcten)
   );

   logic 	dct_mux_sel;
   logic [63:0] ram_to_dct;
   

   always_comb begin
      if (dct_mux_sel) begin
	 x = ut;
      end else begin
	 x = {4'h0,ram_to_dct[63:56], 4'h0,ram_to_dct[55:48],
	      4'h0,ram_to_dct[47:40], 4'h0,ram_to_dct[39:32],
	      4'h0,ram_to_dct[31:24], 4'h0,ram_to_dct[23:16],
	      4'h0,ram_to_dct[15:8], 4'h0,ram_to_dct[7:0]};
      end
   end
   
   // transpose memory
   // control: trd, twr

   transpose tmem
     (.clk(wb.clk), .rst(wb.rst), 
      .wr(mmem.twr) , .rd(mmem.trd), 
      .in({y[7][11:0],y[6][11:0],y[5][11:0],y[4][11:0],y[3][11:0],y[2][11:0],y[1][11:0],y[0][11:0]}), 
      .ut(ut));

   wb_ctrl_module wb_ctrl(
		.clk_i(wb.clk),
		.rst_i(wb.rst),
		.stb_i(wb.stb),
		.ack_o(wb.ack));

   logic [31:0] rec;
   logic [1:0] 	q2_mux_sel;
   
   

   q2 quant(
	    .x_o(dia),
	    .x_i(q),
	    .rec_i(rec));

   always_comb begin
      case (q2_mux_sel)
	2'b00: begin
	   q = {y[1][15:0],y[0][15:0]};
	end
	2'b01: begin
	   q = {y[3][15:0],y[2][15:0]};
	end
	2'b10: begin
	   q = {y[5][15:0],y[4][15:0]};
	end
	default: begin
	   q = {y[7][15:0],y[6][15:0]};
	end
      endcase // case (q2_mux_sel)
   end // always_comb begin

   logic t_rd;
   logic t_wr;
   logic count_in_enable;
   logic count_out_enable;
   logic count_in_rst;
   logic count_out_rst;
   logic dct_enable;
   logic dct_mux_sel;
   
   
   
   dct_ctrl_module dct_ctrl(
			    .clk_i(wb.clk),
			    .rst_i(wb.rst),
			    .stb_i(wb.stb),
			    .we_i(wb.we),
			    .dat_o(wb.dat_o),
			    .adr_i(wb.adr),
			    .csr_o(csr),
			    .t_rd(t_rd),
			    .t_wr(t_wr),
			    .count_in_enable(count_in_enable),
			    .count_out_enable(count_out_enable),
			    .count_in_rst(count_in_rst),
			    .count_out_rst(count_out_rst),
			    .dct_enable(dct_enable),
			    .dct_mux_sel(dct_mux_sel),
			    .q2_mux_sel(q2_mux_sel));

      
   
endmodule

// Local Variables:
// verilog-library-directories:("." ".." "../or1200" "../jpeg" "../pkmc" "../dvga" "../uart" "../monitor" "../lab1" "../dafk_tb" "../eth" "../wb" "../leela")
// End:

module wb_ctrl_module(
    input clk_i,
    input rst_i,
    input stb_i,
    output ack_o);
    
    logic ack;
    
    //Send acknowledgement when strobe is received
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            ack <= 1'b0;
        end
        if (ack) begin
	    ack <= 1'b0;
        end else begin
            ack <= stb_i;
        end
    end
    
   assign ack_o = ack;
    
endmodule // wb_ctrl

module dct_ctrl_module(
		input clk_i, rst_i, stb_i, we_i
		input [31:0] dat_o, adr_i,
		output [7:0] csr_o,
		output t_rd, t_wr, count_in_enable, count_out_enable,
		output [1:0] q2_mux_sel,
		output dct_mux_sel, dct_enable, count_in_rst, count_out_rst);
   
   typedef enum        {IDLE, FIRST1, FIRST2, FIRST3, FIRST4, FIRST5, FIRST_STAGE_DONE,
			SECOND1, SECOND2, SECOND3, SECOND4, SECOND5, SECOND6, DCT_DONE} state_t;
   state_t state;
   logic [7:0] 	       csr;
   logic [1:0] 	       dct_state_counter;
   logic [1:0] 	       q2_loop_counter;
   
   assign csr_o = csr;
   assign q2_mux_sel = q2_loop_counter;
   
   
   always_ff @(posedge clk_i) begin
      if (rst_i) begin
	 state <= IDLE;
      end else begin
	 case (state)
	   IDLE: begin
	      if (csr[0]) begin
		 state <= FIRST1;
		 dct_state_counter <= 2'd3;
	      end
	   end
	   FIRST1: begin
	      state <= FIRST2;
	   end
	   FIRST2: begin
	      if(dct_state_counter == 2'h0) begin
		 state <= FIRST3;
		 dct_state_counter <= 2'd3;
	      end else begin
		 state <= FIRST1;
		 dct_state_counter <= dct_state_counter - 1'b1;
	      end
	   end
	   FIRST3: begin
	      state <= FIRST4;
	   end
	   FIRST4: begin
	      if (dct_state_counter == 2'h0) begin
		 state <= FIRST5;
		 dct_state_counter <= 2'd3;
	      end else begin
		 state <= FIRST3;
		 dct_state_counter <= dct_state_counter - 1'b1;
	      end
	   end
	   FIRST5: begin
	      if (dct_state_counter == 2'h0) begin
		 state <= FIRST_STAGE_DONE;
		 dct_state_counter <= 2'd3;
	      end else begin
		 dct_state_counter <= dct_state_counter - 1'b1;
	      end
	   end
	   FIRST_STAGE_DONE: begin
	      state <= SECOND1;
	   end
	   SECOND1: begin
	      if (dct_state_counter == 2'h0) begin
		 state <= SECOND2;
		 dct_state_counter <= 2'd3;
		 q2_loop_counter <= 2'd3;
	      end else begin
		 dct_state_counter <= dct_state_counter - 1'b1;
	      end
	   end
	   SECOND2: begin
	      if (dct_state_counter == 2'h0) begin
		 state <= SECOND4;
		 dct_state_counter <= 2'd2;
	      end else if (q2_loop_counter == 2'h0) begin
		 state <= SECOND3;
		 dct_state_counter <= dct_state_counter - 1'b1;
		 q2_loop_counter <= 2'd3;
	      end else begin
		 q2_loop_counter <= q2_loop_counter - 1'b1;
	      end
	   end
	   SECOND3: begin
	      state <= SECOND2;
	   end
	   SECOND4: begin
	      state <= SECOND5;
	   end
	   SECOND5: begin
	      if (dct_state_counter == 2'h0) begin
		 state <= SECOND6;
		 q2_loop_counter <= 2'd3;
	      end else if (q2_loop_counter == 2'h0) begin
		 state <= SECOND4;
		 dct_state_counter <= dct_state_counter - 1'b1;
		 q2_loop_counter <= 2'd3;
	      end else begin
		 q2_loop_counter <= q2_loop_counter - 1'b1;
	      end
	   end
	   SECOND6: begin
	      if (q2_loop_counter == 2'h0) begin
		 state <= DCT_DONE;
	      end else begin
		 q2_loop_counter <= q2_loop_counter - 1'b1;
	      end
	   end
	   DCT_DONE: begin
	      state <= IDLE;
	   end
	   default: begin
	      state <= IDLE;
	      dct_state_counter <= 2'h0;
	   end
	 endcase // case (state)
      end // else: !if(rst_i)
   end // always_ff @ (posedge clk_i)

   logic [1:0] csr_mux_sel;
   

   always_comb begin
      t_wr = 1'b0;
      t_rd = 1'b0;
      count_in_enable = 1'b0;
      count_out_enable = 1'b0;
      count_in_rst = 1'b1;
      count_out_rst = 1'b1;
      dct_enable = 1'b0;
      dct_mux_sel = 1'b0;
      csr_mux_sel = 2'b00;
      case (state)
	IDLE: begin
	end
	FIRST1: begin
	   count_in_rst = 1'b0;
	   count_in_enable = 1'b1;
	end
	FIRST2 | FIRST4: begin
	   count_in_rst = 1'b0;
	   count_in_enable = 1'b1;
	   dct_enable = 1'b1;
	end
	FIRST3: begin
	   count_in_rst = 1'b0;
	   count_in_enable = 1'b1;
	   t_wr = 1'b1;
	end
	FIRST5: begin
	   dct_enable = 1'b1;
	   t_wr = 1'b1;
	end
	FIRST_STAGE_DONE: begin
	   csr_mux_sel = 2'b01;
	end
	SECOND1: begin
	   t_rd = 1'b1;
	   dct_mux_sel = 1'b1;
	   dct_enable = 1'b1;
	end
	SECOND2 | SECOND5 | SECOND6: begin
	   count_out_enable = 1'b1;
	   count_out_rst = 1'b0;
	end
	SECOND3: begin
	   t_rd = 1'b1;
	   dct_enable = 1'b1;
	   count_out_rst = 1'b0;
	end
	SECOND4: begin
	   dct_enable = 1'b1;
	   count_out_rst = 1'b0;
	end
	DCT_DONE: begin
	   csr_mux_sel = 2'b10;
	end
	default: begin
	end
      endcase // case (state)
   end

   always_ff @(posedge clk_i) begin
      if (rst_i) begin
	 csr <= 8'h0;
      end else begin
	 case (csr_mux_sel)
	   2'b01: begin
	      csr <= {csr[7:1],1'b0};
	   end
	   2'b10: begin
	      csr <= {1'b1, csr[6:0]};
	   end
	   default: begin
	      if (we_i && stb_i && adr_i[15:0] == 16'h1000) begin
		 csr = dat_o[31:24];
	      end 
	   end
	 endcase
      end
   end

endmodule // dct_ctrl
