`timescale 1ns / 1ps


module lab0_zed(
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

    typedef enum {NO_MSG, START_BIT_DETECTED, BIT0, BIT1, BIT2, BIT3, BIT4, BIT5, BIT6, BIT7, STOP_BIT} recv_state_t;
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


    integer unsigned cnt;
    integer unsigned next_cnt;

    always_ff @(posedge clk_i) begin
        if (rst_i)
            cnt <= 32'h0;
        else
            cnt <= next_cnt;
    end

    always_comb begin
        case(recv_state)
            NO_MSG: begin
                if (rx_neg) begin
                    next_recv_state = START_BIT_DETECTED;
                    next_cnt = 32'h0;
                end
                else begin
                    next_recv_state = NO_MSG;
                end
            end

            START_BIT_DETECTED: begin
                if (cnt == 32'd1302) begin
                    next_recv_state = BIT0;
                    next_cnt = 32'h0;
                end
                else begin
                    next_recv_state = START_BIT_DETECTED;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT0: begin
                if (cnt == 32'd868) begin
                    next_recv_state = BIT1;
                    next_cnt = 32'h0;
                end
                else begin
                    next_recv_state = BIT0;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT1: begin
                if (cnt == 32'd868) begin
                    next_recv_state = BIT2;
                    next_cnt = 32'h0;
                end
                else begin
                    next_recv_state = BIT1;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT2: begin
                if (cnt == 32'd868) begin
                    next_recv_state = BIT3;
                    next_cnt = 32'h0;
                end
                else begin
                    next_recv_state = BIT2;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT3: begin
                if (cnt == 32'd868) begin
                    next_recv_state = BIT4;
                    next_cnt = 32'h0;
                end
                else begin
                    next_recv_state = BIT3;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT4: begin
                if (cnt == 32'd868) begin
                    next_recv_state = BIT5;
                    next_cnt = 32'h0;
                end
                else begin
                    next_recv_state = BIT4;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT5: begin
                if (cnt == 32'd868) begin
                    next_recv_state = BIT6;
                    next_cnt = 32'h0;
                end
                else begin
                    next_recv_state = BIT5;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT6: begin
                if (cnt == 32'd868) begin
                    next_recv_state = BIT7;
                    next_cnt = 32'h0;
                end
                else begin
                    next_recv_state = BIT6;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT7: begin
                if (cnt == 32'd868) begin
                    next_recv_state = STOP_BIT;
                    next_cnt = 32'h0;
                end
                else begin
                    next_recv_state = BIT7;
                    next_cnt = cnt + 32'h1;
                end
            end

            STOP_BIT: begin
                next_recv_state = NO_MSG;
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

    // char_rx
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            char_rx <= 8'h00;
        end
        else begin
            if (recv_state == START_BIT_DETECTED && next_recv_state == BIT0) begin
                char_rx[0] <= rx_bit;
            end
            else if (recv_state == BIT0 && next_recv_state == BIT1) begin
                char_rx[1] <= rx_bit;
            end
            else if (recv_state == BIT1 && next_recv_state == BIT2) begin
                char_rx[2] <= rx_bit;
            end
            else if (recv_state == BIT2 && next_recv_state == BIT3) begin
                char_rx[3] <= rx_bit;
            end
            else if (recv_state == BIT3 && next_recv_state == BIT4) begin
                char_rx[4] <= rx_bit;
            end
            else if (recv_state == BIT4 && next_recv_state == BIT5) begin
                char_rx[5] <= rx_bit;
            end
            else if (recv_state == BIT5 && next_recv_state == BIT6) begin
                char_rx[6] <= rx_bit;
            end
            else if (recv_state == BIT6 && next_recv_state == BIT7) begin
                char_rx[7] <= rx_bit;
            end
        end
    end

    reg [7:0] to_led;

    // to_led
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            to_led <= 8'h0;
        end
        else if (recv_state == STOP_BIT && next_recv_state == NO_MSG) begin
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


    typedef enum {NO_SEND, SEND_START, BIT0, BIT1, BIT2, BIT3, BIT4, BIT5, BIT6, BIT7, SEND_STOP} trans_state_t;
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


    integer unsigned cnt;
    integer unsigned next_cnt;

    always_ff @(posedge clk_i) begin
        if (rst_i)
            cnt <= 32'h0;
        else
            cnt <= next_cnt;
    end

    always_comb begin
        case(trans_state)
            NO_SEND: begin
                if (send_pulse) begin
                    next_trans_state = SEND_START;
                    next_cnt = 32'h0;
                end
                else begin
                    next_trans_state = NO_SEND;
                end
            end

            SEND_START: begin
                if (cnt == 32'd868) begin
                    next_trans_state = BIT0;
                    next_cnt = 32'h0;
                end
                else begin
                    next_trans_state = SEND_START;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT0: begin
                if (cnt == 32'd868) begin
                    next_trans_state = BIT1;
                    next_cnt = 32'h0;
                end
                else begin
                    next_trans_state = BIT0;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT1: begin
                if (cnt == 32'd868) begin
                    next_trans_state = BIT2;
                    next_cnt = 32'h0;
                end
                else begin
                    next_trans_state = BIT1;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT2: begin
                if (cnt == 32'd868) begin
                    next_trans_state = BIT3;
                    next_cnt = 32'h0;
                end
                else begin
                    next_trans_state = BIT2;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT3: begin
                if (cnt == 32'd868) begin
                    next_trans_state = BIT4;
                    next_cnt = 32'h0;
                end
                else begin
                    next_trans_state = BIT3;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT4: begin
                if (cnt == 32'd868) begin
                    next_trans_state = BIT5;
                    next_cnt = 32'h0;
                end
                else begin
                    next_trans_state = BIT4;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT5: begin
                if (cnt == 32'd868) begin
                    next_trans_state = BIT6;
                    next_cnt = 32'h0;
                end
                else begin
                    next_trans_state = BIT5;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT6: begin
                if (cnt == 32'd868) begin
                    next_trans_state = BIT7;
                    next_cnt = 32'h0;
                end
                else begin
                    next_trans_state = BIT6;
                    next_cnt = cnt + 32'h1;
                end
            end

            BIT7: begin
                if (cnt == 32'd868) begin
                    next_trans_state = SEND_STOP;
                    next_cnt = 32'h0;
                end
                else begin
                    next_trans_state = BIT7;
                    next_cnt = cnt + 32'h1;
                end
            end

            SEND_STOP: begin
                if (cnt == 32'd868) begin
                    next_trans_state = NO_SEND;
                    next_cnt = 32'h0;
                end
                else begin
                    next_trans_state = SEND_STOP;
                    next_cnt = cnt + 32'h1;
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
        else if (trans_state == NO_SEND && next_trans_state == SEND_START) begin
            data <= switch_i;
        end
    end



    logic to_tx;

    // set what to send
    always_comb begin
        case(trans_state)
            NO_SEND:    to_tx = 1'b1;
            SEND_START: to_tx = 1'b0;
            BIT0:       to_tx = data[0];
            BIT1:       to_tx = data[1];
            BIT2:       to_tx = data[2];
            BIT3:       to_tx = data[3];
            BIT4:       to_tx = data[4];
            BIT5:       to_tx = data[5];
            BIT6:       to_tx = data[6];
            BIT7:       to_tx = data[7];
            SEND_STOP:  to_tx = 1'b1;
            default:    to_tx = 1'b1;
        endcase
    end


    // Set output
    assign tx_o = to_tx;

endmodule



