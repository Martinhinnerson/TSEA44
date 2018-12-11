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
	
	logic [31:0] 	 dout_res;
	logic 		 ce_in, ce_ut;
	logic [8:0] 		 rdc;
	logic [8:0] 		 wrc;
	
	logic [31:0] 	 dob, ut_doa;
	
	logic [0:7][11:0] 	 x, in, ut;
	
	logic [0:7][15:0] 	 y;   
	
	logic [31:0] 	 q, dia;
	logic [31:0] 	 doa;
	logic 		 csren;
	logic [7:0] 		 csr;
	
	logic 		 dmaen;
	logic 		 dct_busy;
	logic 		 dma_start_dct;
	
	
	logic t_rd;
	logic t_wr;
	logic dct_enable;
	logic count_in_enable;
	logic count_out_enable;
	logic count_in_rst;
	logic count_out_rst;
	logic dct_mux_sel;
	logic [31:0] rec;
	logic [1:0] 	q2_mux_sel;
	logic [63:0] ram_to_dct;
	logic [31:0] ram_to_dct_reg;
	
	
	
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
	assign wb.err = 1'b0; // wb.stb
	
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
	
	// ============================================================================
	// Block ram signal assignment
	// ============================================================================
	assign bram_data = {~wb.dat_o[31], wb.dat_o[30:24], ~wb.dat_o[23], wb.dat_o[22:16], ~wb.dat_o[15], wb.dat_o[14:8], ~wb.dat_o[7], wb.dat_o[6:0]};
	assign bram_addr = wb.adr[10:2];
	assign bram_we = wb.we;
	assign bram_ce = ce_in;
	
	// ============================================================================
	// OUTMEM memory counter
	// ============================================================================
	always_ff @(posedge wb.clk) begin
		if (wb.rst || count_out_rst) begin
			wrc <= 9'h0;
		end else if (count_out_enable) begin 
			wrc <= wrc + 9'h1;
		end
	end
	
	// ============================================================================
	// INMEM memory counter
	// ============================================================================
	always_ff @(posedge wb.clk) begin
		if (wb.rst || count_in_rst) begin
			rdc <= 9'h0;
		end else if (count_in_enable) begin
			rdc <= rdc + 9'h1;
		end
	end
	
	
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
	.ADDRB(rdc),
	.DIB(32'h0), .DIPB(4'h0), 
	.ENB(1'b1),.WEB(1'b0), 
	.DOB(dob), .DOPB());
	
	RAMB16_S36_S36 #(.SIM_COLLISION_CHECK("NONE")) utmem
	(// DCT write
	.CLKA(wb.clk), .SSRA(wb.rst),
	.ADDRA(wrc),
	.DIA(dia), .DIPA(4'h0), .ENA(1'b1),
	.WEA(count_out_enable), .DOA(ut_doa), .DOPA(),
	// WB read & write
	.CLKB(wb.clk), .SSRB(wb.rst),
	.ADDRB(bram_addr),
	.DIB(wb.dat_o), .DIPB(4'h0), .ENB(ce_ut),
	.WEB(wb.we), .DOB(dout_res), .DOPB());
	
	// ============================================================================
	// WB.DAT_I signal generation
	// Control: wb.adr[12:11]
	// ============================================================================
	always_comb begin
		case (wb.adr[12:11])
			2'b00: begin
				wb.dat_i = doa;
			end
			2'b01: begin
				wb.dat_i = dout_res;
			end
			default: begin
				wb.dat_i = {csr, 24'h0};
			end
		endcase
	end
	
	// You must also create the control logic...
	
	// 8 point DCT
	// control: dcten
	
	// ============================================================================
	// 8 point DCT
	// ============================================================================
	dct dct0
	(.y(y), .x(x), 
	.clk_i(wb.clk), .en(dct_enable)
	);
	
	// ============================================================================
	// DCT input hold reg
	// ============================================================================
	always_ff @(posedge wb.clk) begin
		ram_to_dct_reg <= dob;
	end
	
	assign ram_to_dct = {ram_to_dct_reg, dob};
	
	// ============================================================================
	// DCT input mux
	// Control: dct_mux_sel
	// ============================================================================
	always_comb begin
		if (dct_mux_sel) begin
			x = ut;
		end else begin
			x = {{4{ram_to_dct[63]}},ram_to_dct[63:56], {4{ram_to_dct[55]}},ram_to_dct[55:48],
			{4{ram_to_dct[47]}},ram_to_dct[47:40], {4{ram_to_dct[39]}},ram_to_dct[39:32],
			{4{ram_to_dct[31]}},ram_to_dct[31:24], {4{ram_to_dct[23]}},ram_to_dct[23:16],
			{4{ram_to_dct[15]}},ram_to_dct[15:8], {4{ram_to_dct[7]}},ram_to_dct[7:0]};
		end
	end
	
	// ============================================================================
	// Transpose Memory
	// Control: trd, twr
	// ============================================================================
	transpose tmem
	(.clk(wb.clk), 
	.wr(t_wr) , .rd(t_rd), 
	.in({y[0][11:0],y[1][11:0],y[2][11:0],y[3][11:0],y[4][11:0],y[5][11:0],y[6][11:0],y[7][11:0]}), 
	.ut(ut));
	
	// ============================================================================
	// WB Ctrl
	// ============================================================================
	wb_ctrl_module wb_ctrl(
	.clk_i(wb.clk),
	.rst_i(wb.rst),
	.stb_i(wb.stb),
	.ack_o(wb.ack));
	
	// ============================================================================
	// Q2
	// ============================================================================
	q2 quant(
	.x_o(dia),
	.x_i(q),
	.rec_i(rec));
	
	// ============================================================================
	// Q2 input mux
	// Control: q2_mux_sel
	// ============================================================================
	always_comb begin
		case (q2_mux_sel)
			2'b00: begin
				q = {y[6][15:0],y[7][15:0]};
			end
			2'b01: begin
				q = {y[4][15:0],y[5][15:0]};
			end
			2'b10: begin
				q = {y[2][15:0],y[3][15:0]};
			end
			default: begin
				q = {y[0][15:0],y[1][15:0]};
			end
		endcase // case (q2_mux_sel)
	end // always_comb begin
	
	// ============================================================================
	// DCT2 Control Unit
	// ============================================================================
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
	.q2_mux_sel(q2_mux_sel),
	.rec_o(rec));
	
	
	
endmodule

// Local Variables:
// verilog-library-directories:("." ".." "../or1200" "../jpeg" "../pkmc" "../dvga" "../uart" "../monitor" "../lab1" "../dafk_tb" "../eth" "../wb" "../leela")
// End:

// =============================================================================
// Wishbone control module
// =============================================================================
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

// =============================================================================
// DCT Control module
// =============================================================================
module dct_ctrl_module(
	input clk_i, rst_i, stb_i, we_i,
	input [31:0] dat_o, adr_i,
	output logic [7:0] csr_o,
	output logic t_rd, t_wr, count_in_enable, count_out_enable,
	output logic [1:0] q2_mux_sel,
	output logic dct_mux_sel, dct_enable, count_in_rst, count_out_rst,
	output logic [31:0] rec_o);
	
	typedef enum        {IDLE, INIT, FIRST1, FIRST2, FIRST3, FIRST4, FIRST5, FIRST_STAGE_DONE,
	SECOND1, SECOND2, SECOND3, SECOND4, SECOND5, SECOND6, DCT_DONE} state_t;
	state_t state;
	
	parameter [15:0] rec [0:63] = '{	2048, 2731, 2341, 2341, 1820, 1365, 669, 455, 
	2979, 2731, 2521, 1928, 1489, 936, 512, 356, 
	3277, 2341, 2048, 1489, 886, 596, 420, 345, 
	2048, 1725, 1365, 1130, 585, 512, 377, 334, 
	1365, 1260, 819, 643, 482, 405, 318, 293, 
	819, 565, 585, 377, 301, 315, 271, 328, 
	643, 546, 485, 410, 318, 290, 273, 318, 
	537, 596, 585, 529, 426, 356, 324, 331};
	
	logic [7:0] 	       csr;
	logic [1:0] 	       dct_state_counter;
	logic [1:0] 	       q2_loop_counter;
	
	
	assign csr_o = csr;
	assign q2_mux_sel = q2_loop_counter;
	

	logic [1:0] csr_mux_sel;
	logic [6:0] rec_counter;
	
	// =============================================================================
	// FSM for the DCT accelerator
	// =============================================================================	
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			state <= IDLE;
		end else begin
			case (state)
				IDLE: begin
					if (csr[0]) begin
						state <= INIT;
						dct_state_counter <= 2'd3;
					end
				end
				INIT: begin
					state <= FIRST1;
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
					if (dct_state_counter == 2'h0 && q2_loop_counter == 2'h0) begin //adde q2 here
						state <= SECOND4;
						dct_state_counter <= 2'd3; //why 2?
						q2_loop_counter <= 2'd3; //added this
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
						q2_loop_counter <= 2'd2; //changed to 2 from 3
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
	
	// =============================================================================
	// Counter for the reciprocals
	// =============================================================================
	always_ff @(posedge clk_i) begin
		if(rst_i || count_out_rst) begin
			rec_counter <= 7'h0;
		end
		else if(count_out_enable) begin
			rec_counter <= rec_counter + 2'd2;
		end
	end
	
	assign rec_o = {rec[rec_counter], rec[rec_counter + 1]};
	
	
	// =============================================================================
	// Control signal assignment for each state
	// =============================================================================
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
			INIT: begin
				count_in_rst = 1'b0;
				count_in_enable = 1'b1;
			end
			FIRST1: begin
				count_in_rst = 1'b0;
				count_in_enable = 1'b1;
			end
			FIRST2, FIRST4: begin
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
			SECOND2, SECOND5, SECOND6: begin
				count_out_enable = 1'b1;
				count_out_rst = 1'b0;
				dct_mux_sel = 1'b1;
			end
			SECOND3: begin
				t_rd = 1'b1;
				dct_enable = 1'b1;
				count_out_rst = 1'b0;
				dct_mux_sel = 1'b1;
			end
			SECOND4: begin
				dct_enable = 1'b1;
				count_out_rst = 1'b0;
				dct_mux_sel = 1'b1;
			end
			DCT_DONE: begin
				csr_mux_sel = 2'b10;
			end
			default: begin
			end
		endcase // case (state)
	end
	
	// =============================================================================
	// CSR control block
	// Control: csr_mux_sel, rst_i, we_i, stb_i, adr_i[12:11]
	// =============================================================================
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
					if (we_i && stb_i && adr_i[12:11] == 2'b10) begin
						csr <= dat_o[31:24];
					end 
				end
			endcase
		end
	end
	
endmodule // dct_ctrl
