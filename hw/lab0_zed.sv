/`timescale 1ns / 1ps


module lab0_zed(
    input   clk_i,
    input   rst_i,
    input   rx_i,
    output  tx_o,
    output  [7:0] led_o,
    input   [7:0] switch_i,
    input   send_i);

    //Reciever parameters
    reg[7:0] rx_shift_reg;
    reg[7:0] rx_hold_reg;
    reg[2:0] rx_bitCtr;
    reg[3:0] rx_delayCtr;
    reg[2:0] rx_state;
    reg rx_i_sync;

    parameter word_length = 3'd8; // word lenght used by the uart protocol

    parameter rx_idle       = 3'd0;
    parameter rx_start      = 3'd1;
    parameter rx_read_bit   = 3'd2;
    parameter rx_next       = 3'd3;
    parameter rx_stop       = 3'd4;

    parameter liu_id    = 8'b01010110;

    //Transmitter parameters
    reg[7:0] tx_shift_reg;
    reg[7:0] tx_hold_reg;
    reg[3:0] tx_counter;
    reg[2:0] tx_state;

    parameter tx_counter_start = 4'd8;

    parameter tx_idle   = 3'd0;
    parameter tx_start  = 3'd1;
    parameter tx_send   = 3'd2;
    parameter tx_stop   = 3'd3;

    wire[7:0] ascii_code;
    wire c_tx_shift;
    wire c_tx_count;

    //Other parameters
    wire clk_baud;

    parameter CLK_FREQ  = 100000000;
    parameter BAUDRATE  = 115200;
    integer BAUDDELAY = CLK_FREQ/BAUDRATE;
    integer BAUDDELAY_HALF = BAUDDELAY/2;

    /*** Sync the rx input ***/
    always @(posedge clk_i) begin
        rx_i_sync <= rx_i;
    end

    always @(posedge clk_i) begin
        led_o <= rx_hold_reg;
    end

    /*** Baudrate generator ***/
    always @(posedge clk_i)
    begin
        clk_baud <= #BAUDDELAY_HALF ~clk_baud;
    end

    /*** Reciever module ***/
    always @(posedge clk_i or posedge rst_i)
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
                    end
                    else begin //If we have bits left go back to read_bit
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
                default: rx_state = rx_idle; //We should never be here
            endcase
        end
    end

    /*** Transmitter module ***/
    always @(posedge clk_i or posedge rst_i)
    begin
        if (rst_i) begin
            tx_state <= tx_idle;
            tx_counter <= tx_counter_start;
            tx_shift_reg <= 0'd0;
            tx_hold_reg <= 0'd0;
        end
        else
        begin
            case(rx_state)
                tx_idle: begin
                    
                end
                tx_start: begin
                    
                end
                tx_read: begin
                    
                end
                tx_stop: begin
                    
                end
                default: tx0_state = tx_idle;
            endcase
        end
    end


endmodule
// Local Variables:
// verilog-library-directories:("." "or1200" "jpeg" "pkmc" "dvga" "uart" "monitor" "lab1" "dafk_tb" "eth" "wb" "leela")
// End:























