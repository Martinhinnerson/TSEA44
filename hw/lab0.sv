`timescale 1ns / 1ps


module lab0(
    input clk_i,
    input rst_i,
    input rx_i,
    output tx_o,
    output [7:0] led_o,
    input [7:0] switch_i,
    input send_i);


    receiver recv(.*);
    transmitter trans(.*);

endmodule
// Local Variables:
// verilog-library-directories:("." "or1200" "jpeg" "pkmc" "dvga" "uart" "monitor" "lab1" "dafk_tb" "eth" "wb" "leela")
// End:



module receiver(
    input clk_i,
    input rst_i,
    input rx_i,
    output [7:0] led_o);

    typedef enum {NO_MSG, START_BIT_DETECTED, DATA_BITS, STOP_BIT} recv_state_t;
    recv_state_t recv_state, next_recv_state;
    

    reg rx_bit;
    reg last_rx_bit;
    logic rx_neg;

    // synchronize rx_i
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            rx_bit <= 1'b1;
            last_rx_bit <= 1'b1;
        end
        else begin
            rx_bit <= rx_i;
            last_rx_bit <= rx_bit;
        end
    end

    // Check for negative edge
    // Neg edge if last was 1 and now we have 0
    assign rx_neg = last_rx_bit & ~rx_bit;


    logic [9:0] cnt;
    logic [9:0] next_cnt;
    
    logic [3:0] cnt8;
    logic [3:0] next_cnt8;

    // Counter registers
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            cnt <= 10'h0;
            cnt8 <= 4'h0;
        end
        else begin
            cnt <= next_cnt;
            cnt8 <= next_cnt8;
        end
    end
    
    logic shift;
    logic change_led;

    // Determine next state, next cnts, shift and change_led
    always_comb begin
        shift = 1'b0;
        change_led = 1'b0;
        next_cnt8 = cnt8;
    
        case(recv_state)
            NO_MSG: begin
                if (rx_neg) begin
                    next_recv_state = START_BIT_DETECTED;
                    next_cnt = 10'h0;
                end
                else begin
                    next_recv_state = NO_MSG;
                end
            end

            START_BIT_DETECTED: begin
                if (cnt == 10'd521) begin
                    next_recv_state = DATA_BITS;
                    next_cnt = 10'h0;
                    shift = 1'b1;
                    next_cnt8 = 4'h0;
                end
                else begin
                    next_recv_state = START_BIT_DETECTED;
                    next_cnt = cnt + 10'h1;
                end
            end

            DATA_BITS: begin
                if (cnt8 == 4'd7 && cnt == 10'd347) begin
                    next_recv_state = STOP_BIT;
                    next_cnt = 10'h0;
                    next_cnt8 = 4'h0;
                end
                else if (cnt == 10'd347) begin
                    next_recv_state = DATA_BITS;
                    next_cnt = 10'h0;
                    next_cnt8 = cnt8 + 4'h1;
                    shift = 1'b1;
                end
                else begin
                    next_recv_state = DATA_BITS;
                    next_cnt = cnt + 10'h1;
                end
            end

            STOP_BIT: begin
                next_recv_state = NO_MSG;
                change_led = 1'b1;
            end

            default:
                next_recv_state = NO_MSG;
        endcase
    end

    // next state
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            recv_state <= NO_MSG;
        end
        else begin
            recv_state <= next_recv_state;
        end
    end

    reg [7:0] char_rx;
    
    // shift in bits from rx
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            char_rx <= 8'h00;
        end
        else if (shift) begin
            char_rx <= {rx_bit, char_rx[7:1]};
        end
    end

    reg [7:0] to_led;

    // Set to_led to send to leds
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            to_led <= 8'h0;
        end
        else if (change_led) begin
            to_led <= char_rx;
        end
    end

    // Set output
    assign led_o = to_led;

endmodule


module transmitter(
    input clk_i,
    input rst_i,
    output tx_o,
    input [7:0] switch_i,
    input send_i);


    typedef enum {NO_SEND, SEND_START, SEND_DATA, SEND_STOP} trans_state_t;
    trans_state_t trans_state, next_trans_state;
    

    logic last_send_i;
    logic current_send_i;
    logic send_pulse;

    // for detecting pos edge
    always_ff @(posedge clk_i) begin
        current_send_i <= send_i;
        last_send_i <= current_send_i;
    end
    // Check for positive edge
    // Pos edge if last was 0 and now we have 1
    assign send_pulse = ~last_send_i & current_send_i;


    logic [9:0] cnt;
    logic [9:0] next_cnt;
    logic [3:0] data_bit;
    logic [3:0] next_data_bit;

    // Counter registers
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            cnt <= 32'h0;
            data_bit <= 4'h0;
        end
        else begin
            cnt <= next_cnt;
            data_bit <= next_data_bit;
        end
    end
    
    logic load_data;

    // Determine next state, next counters and load_data
    always_comb begin
        next_data_bit = data_bit;
        load_data = 1'b0;
    
        case(trans_state)
            NO_SEND: begin
                if (send_pulse) begin
                    next_trans_state = SEND_START;
                    next_cnt = 10'h0;
                    next_data_bit = 4'h0;
                    load_data = 1'b1;
                end
                else begin
                    next_trans_state = NO_SEND;
                end
            end

            SEND_START: begin
                if (cnt == 10'd347) begin
                    next_trans_state = SEND_DATA;
                    next_cnt = 10'h0;
                end
                else begin
                    next_trans_state = SEND_START;
                    next_cnt = cnt + 10'h1;
                end
            end

            SEND_DATA: begin
                if (data_bit == 7 && cnt == 10'd347) begin
                    next_trans_state = SEND_STOP;
                    next_cnt = 10'h0;
                    next_data_bit = 4'h0;
                end
                else if (cnt == 10'd347) begin
                    next_trans_state = SEND_DATA;
                    next_cnt = 10'h0;
                    next_data_bit = data_bit + 4'h1;
                end
                else begin
                    next_trans_state = SEND_DATA;
                    next_cnt = cnt + 10'h1;
                end
            end

            SEND_STOP: begin
                if (cnt == 10'd347) begin
                    next_trans_state = NO_SEND;
                    next_cnt = 10'h0;
                end
                else begin
                    next_trans_state = SEND_STOP;
                    next_cnt = cnt + 10'h1;
                end
            end

            default:
                next_trans_state = NO_SEND;
        endcase
    end

    // next state
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            trans_state <= NO_SEND;
        end
        else begin
            trans_state <= next_trans_state;
        end
    end


    reg [7:0] data;

    // data from switches
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            data <= 8'h0;
        end
        else if (load_data) begin
            data <= switch_i;
        end
    end

    logic to_tx;

    // set what to send
    always_comb begin
        case(trans_state)
            NO_SEND:    to_tx = 1'b1;
            SEND_START: to_tx = 1'b0;
            SEND_DATA:  to_tx = data[data_bit];
            SEND_STOP:  to_tx = 1'b1;
            default:    to_tx = 1'b1;
        endcase
    end


    // Set output
    assign tx_o = to_tx;

endmodule



