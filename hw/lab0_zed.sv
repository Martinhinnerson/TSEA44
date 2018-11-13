`timescale 1ns / 1ps


module lab0_zed(
		input   clk_i,
		input   rst_i,
		input   rx_i,
		output  tx_o,
		output  [7:0] led_o,
		input   [7:0] switch_i,
		input   send_i);


   //temporary registers to store the output to
   reg 			tx_o_tmp;
   reg [7:0] 		led_o_tmp;
   
   
   //Reciever parameters
   reg [7:0] 		rx_shift_reg;
   reg [7:0] 		rx_hold_reg;
   reg [3:0] 		rx_bitCtr;
   reg [9:0] 		rx_delayCtr;
   reg [2:0] 		rx_state;
   reg 			rx_i_sync;

   parameter rx_idle       = 3'd0;
   parameter rx_start      = 3'd1;
   parameter rx_read_bit   = 3'd2;
   parameter rx_next       = 3'd3;
   parameter rx_stop       = 3'd4;

   parameter liu_id    = 8'b01010110;

   //Transmitter parameters
   reg [7:0] 		tx_shift_reg;
   reg [7:0] 		tx_hold_reg;
   reg [3:0] 		tx_bitCtr;
   reg [9:0] 		tx_delayCtr;
   reg [2:0] 		tx_state;			

   parameter tx_idle       = 3'd0;
   parameter tx_start      = 3'd1;
   parameter tx_send_bit   = 3'd2;
   parameter tx_next       = 3'd3;
   parameter tx_stop       = 3'd4;
   parameter tx_end        = 3'd5;

   //Other parameters
   parameter word_length = 4'd7; // word lenght-1 used by the uart protocol

   parameter CLK_FREQ  = 100000000;
   parameter BAUDRATE  = 115200;
   parameter BAUDDELAY = CLK_FREQ/BAUDRATE; //This might not work since the result is not int
   parameter BAUDDELAY_HALF = BAUDDELAY/2; //Same here
   
   /*** Sync the rx input ***/
   always_ff @(posedge clk_i) begin
      rx_i_sync <= rx_i;
   end
   
   assign  led_o[7:0] = rx_hold_reg[7:0];
   
   always_ff @(posedge clk_i) begin
      tx_hold_reg[7:0] <= switch_i[7:0];
   end

   /*** Reciever module ***/
   always_ff @(posedge clk_i or posedge rst_i)
     begin
        if (rst_i) begin
           rx_state <= rx_idle;
           rx_bitCtr <= word_length;
           rx_delayCtr <= BAUDDELAY_HALF;
           rx_shift_reg <= 0'd0;
           rx_hold_reg <= liu_id;
        end
        else
          begin
             case(rx_state)
               rx_idle: begin
                  rx_delayCtr <= BAUDDELAY_HALF;
                  rx_bitCtr <= word_length;
                  if (rx_i_sync == 1'b0) begin //If we recieve a start bit
                     rx_state <= rx_start;
                  end
               end
               rx_start: begin
                  if(rx_delayCtr == 0) begin
                     if(rx_i_sync == 1'b1) //Control if it really was a start bit
                       rx_state <= rx_idle;
                     else
                       rx_state <= rx_read_bit;
                     rx_delayCtr <= BAUDDELAY;
                  end else begin
                     rx_delayCtr <= rx_delayCtr - 1'b1;
                  end
               end
               rx_read_bit: begin
                  if (rx_delayCtr == 0) begin //If we are in the middle of the recieved pulse
                     rx_state <= rx_next;
                     rx_delayCtr <= BAUDDELAY;
                     rx_shift_reg[7:0] <= {rx_i_sync, rx_shift_reg[7:1]}; //shift in one bit
                  end else begin
                     rx_delayCtr <= rx_delayCtr - 1'b1;
                  end
               end
               rx_next: begin
                  if (rx_bitCtr == 3'b0) begin //If we have no bits left to read, go to stop
                     rx_delayCtr <= BAUDDELAY;
                     rx_state <= rx_stop;
                  end else begin //If we have bits left go back to read_bit
                     rx_state <= rx_read_bit;
                     rx_bitCtr <= rx_bitCtr - 1'b1;
                  end
               end
               rx_stop: begin
                  if (rx_delayCtr == 0) begin //check the stop bit
                     rx_state <= rx_idle;
                     if(rx_i_sync) begin //stop bit is ok
                        rx_hold_reg <= rx_shift_reg; //store the read character to the hold reg
                     end else begin
                        //stop bit is not ok
                     end
                  end else begin
                     rx_delayCtr <= rx_delayCtr - 1'b1;
                  end
               end
               default: rx_state <= rx_idle; //We should never be here
             endcase
          end
     end

   /*** Transmitter module ***/
   always_ff @(posedge clk_i or posedge rst_i)
     begin
        if (rst_i) begin
           tx_state <= tx_idle;
           tx_bitCtr <= word_length;
           tx_delayCtr <= BAUDDELAY;
           tx_shift_reg <= 0'd0;
           tx_o_tmp <= 1'b1;	   
        end
        else
          begin
             case(tx_state)
               tx_idle: begin
                  tx_delayCtr <= BAUDDELAY;
                  tx_bitCtr <= word_length;
                  tx_shift_reg <= tx_hold_reg;
		  if (send_i) begin //If the send button is pushed
                     tx_state <= tx_start;
		  end
               end
               tx_start: begin
                  tx_o_tmp <= 1'b0; //send start bit
                  tx_state <= tx_send_bit;
               end
               tx_send_bit: begin
                  if (tx_delayCtr == 0) begin //Send the next bit
                     tx_state <= tx_next;
                     tx_delayCtr <= BAUDDELAY;
                     tx_o_tmp <= tx_shift_reg[0];
                     tx_shift_reg[7:0] <= {1'b0, tx_shift_reg[7:1]};
                  end else begin
                     tx_delayCtr <= tx_delayCtr - 1'b1;
                  end
               end
               tx_next: begin
                  if (tx_bitCtr == 4'b0) begin //If we have no bits left to read, go to stop
                     tx_delayCtr <= BAUDDELAY;
                     tx_state <= tx_stop;
                  end else begin //If we have bits left go back to read_bit
                     tx_state <= tx_send_bit;
                     tx_bitCtr <= tx_bitCtr - 1'b1;
                  end
               end
               tx_stop: begin
                  if (tx_delayCtr == 0) begin //send the stop bit
		                tx_state <= tx_end;
                    tx_o_tmp <= 1'b1;
                    tx_delayCtr <= BAUDDELAY;
                  end else begin
                    tx_delayCtr <= tx_delayCtr - 1'b1;
                  end
                tx_end: begin 
                  if(tx_delayCtr == 0) begin //wait out the stop bit before returning
                    if(!send_i) begin //only return if the button is not held down
                      tx_state <= tx_idle;
                    end
                    else begin
                      tx_delayCtr <= tx_delayCtr - 1'b1;
                    end
                  end
               end
               default: tx_state <= tx_idle; //We should never be here
             endcase
          end // else: !if(rst_i)
     end
   assign tx_o = tx_o_tmp;

endmodule
// Local Variables:
// verilog-library-directories:("." "or1200" "jpeg" "pkmc" "dvga" "uart" "monitor" "lab1" "dafk_tb" "eth" "wb" "leela")
// End:
























