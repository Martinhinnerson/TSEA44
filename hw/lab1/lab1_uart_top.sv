`include "include/timescale.v"


module lab1_uart_top 
    (wishbone.slave wb,
    output wire int_o,
    input wire 	srx_pad_i,
    output wire stx_pad_o);
    
    assign int_o = 1'b0;  // Interrupt, not used in this lab
    assign wb.err = 1'b0; // Error, not used in this lab
    assign wb.rty = 1'b0; // Retry, not used in this course
    
    // Here you must instantiate lab0_uart or cut and paste
    // You will also have to change the interface of lab0_uart to make this work.
    //assign wb.ack = wb.stb;   // Change this line
    //assign stx_pad_o = srx_pad_i; // Change this line.. :)

    logic [7:0] shift_reg_rx_i;
    logic [7:0] shift_reg_tx_o;
    logic send;
    logic end_char_rx;
    logic end_char_tx;

    // Only using 31:24, 22:21 and 16 on wb.dat_i
    // Set others to 0
    assign wb.dat_i[23] = 1'b0;
    assign wb.dat_i[20:17] = 4'h0;
    assign wb.dat_i[15:0] = 16'h0000;


    uart_module uart(
        .clk_i(wb.clk),
        .rst_i(wb.rst),
        .rx_i(srx_pad_i),
        .tx_o(stx_pad_o),
        .shift_reg_rx_i(shift_reg_rx_i),
        .shift_reg_tx_o(shift_reg_tx_o),
        .send_i(send),
        .end_char_rx(end_char_rx),
        .end_char_tx(end_char_tx));

    uart_wb_transmitter uart_wb_trans(
        .clk_i(wb.clk),
        .rst_i(wb.rst),
        .stb_i(wb.stb),
        .we_i(wb.we),
        .sel3_i(wb.sel[3]),
        .adr2_i(wb.adr[2]),
        .tx_reg_i(wb.dat_o[31:24]),
        .end_char_tx(end_char_tx),
        .send_o(send),
        .shift_reg_tx_o(shift_reg_tx_o),
        .tx_empty_o(wb.dat_i[22:21]));

    uart_wb_receiver uart_wb_recv(
        .clk_i(wb.clk),
        .rst_i(wb.rst),
        .stb_i(wb.stb),
        .we_i(wb.we),
        .sel3_i(wb.sel[3]),
        .adr2_i(wb.adr[2]),
        .rx_reg_o(wb.dat_i[31:24]),
        .rx_full_o(wb.dat_i[16]),
        .end_char_rx(end_char_rx),
        .shift_reg_rx_i(shift_reg_rx_i));

    bus_ack ack(
        .clk_i(wb.clk),
        .rst_i(wb.rst),
        .stb_i(wb.stb),
        .ack_o(wb.ack));




endmodule


// Local Variables:
// verilog-library-directories:("." ".." "../or1200" "../jpeg" "../pkmc" "../dvga" "../uart" "../monitor" "../lab1" "../dafk_tb" "../eth" "../wb" "../leela")
// End:



module uart_module(
    input clk_i,
    input rst_i,
    input rx_i,
    output tx_o,
    output [7:0] shift_reg_rx_i,
    input [7:0] shift_reg_tx_o,
    input send_i,
    output end_char_rx,
    output end_char_tx);
    
    
    receiver_wb recv(.*);
    transmitter_wb trans(.*);
    
endmodule
// Local Variables:
// verilog-library-directories:("." "or1200" "jpeg" "pkmc" "dvga" "uart" "monitor" "lab1" "dafk_tb" "eth" "wb" "leela")
// End:


module uart_wb_transmitter(
    input clk_i,
    input rst_i,
    input stb_i,
    input we_i,
    input sel3_i,
    input adr2_i,
    input [7:0] tx_reg_i,
    input end_char_tx,
    output send_o,
    output [7:0] shift_reg_tx_o,
    output [1:0] tx_empty_o);
    
    logic tx_empty;
    logic wr;
    logic wr_delayed;
    logic [7:0] tx_reg;
    
    assign wr = (stb_i && we_i && sel3_i && !adr2_i);
    
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            wr_delayed <= 1'b0;
        end
        else begin
            wr_delayed <= wr;
        end
    end

    assign send_o = wr_delayed;


    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            tx_empty <= 1'b1;
        end
        else begin
            if (wr) begin
                tx_empty <= 1'b0;
            end
            else if (end_char_tx) begin
                tx_empty <= 1'b1;
            end
            // Else keep value
        end
    end

    assign tx_empty_o = {2{tx_empty}};


    always_ff @(posedge clk_i) begin
        if (rst_i) begin
           tx_reg <= 8'h00; 
        end
        else begin
            if (wr) begin
                tx_reg <= tx_reg_i;
            end
        end
    end

    assign shift_reg_tx_o = tx_reg;
    
    
endmodule


module bus_ack(
    input clk_i,
    input rst_i,
    input stb_i,
    output ack_o);
    
    logic ack;
    
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            ack <= 1'b0;
        end
        else begin
            ack <= stb_i;
        end
    end
    
    assign ack_o = ack;
    
endmodule


module uart_wb_receiver(
    input clk_i,
    input rst_i,
    input stb_i,
    input we_i,
    input sel3_i,
    input adr2_i,
    output [7:0] rx_reg_o,
    output rx_full_o,
    input end_char_rx,
    input [7:0] shift_reg_rx_i);
    
    logic rx_full;
    logic [7:0] rx_reg;
    
    logic rd;
    assign rd = (stb_i && !we_i && sel3_i && !adr2_i);
    
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            rx_full <= 1'b0;
        end
        else begin
            if (rd) begin
                rx_full <= 1'b0;
            end
            else if (end_char_rx) begin
                rx_full <= 1'b1;
            end
            // Else keep same value
        end
    end
    
    assign rx_full_o = rx_full;
    
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            rx_reg <= 8'h00;
        end
        else begin
            if (end_char_rx) begin
                rx_reg <= shift_reg_rx_i;
            end
            // Else keep value
        end
    end
    
    assign rx_reg_o = rx_reg;
    
endmodule



module receiver_wb(
    input clk_i,
    input rst_i,
    input rx_i,
    output [7:0] shift_reg_rx_i,
    output end_char_rx);

   parameter BAUD_DELAY=217;
   parameter BAUD_START=325;
   
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
                if (cnt == BAUD_START) begin
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
                if (cnt8 == 4'd7 && cnt == BAUD_DELAY) begin
                    next_recv_state = STOP_BIT;
                    next_cnt = 10'h0;
                    next_cnt8 = 4'h0;
                end
                else if (cnt == BAUD_DELAY) begin
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
    assign shift_reg_rx_i = to_led;
    assign end_char_rx = change_led;
    
endmodule


module transmitter_wb(
    input clk_i,
    input rst_i,
    output tx_o,
    input [7:0] shift_reg_tx_o,
    input send_i,
    output end_char_tx);

   parameter BAUD_DELAY=217;
    
    
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
    logic stop_bit_sent;
    
    // Determine next state, next counters and load_data
    always_comb begin
        next_data_bit = data_bit;
        load_data = 1'b0;
        stop_bit_sent = 1'b0;
        
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
                if (cnt == BAUD_DELAY) begin
                    next_trans_state = SEND_DATA;
                    next_cnt = 10'h0;
                end
                else begin
                    next_trans_state = SEND_START;
                    next_cnt = cnt + 10'h1;
                end
            end
            
            SEND_DATA: begin
                if (data_bit == 7 && cnt == BAUD_DELAY) begin
                    next_trans_state = SEND_STOP;
                    next_cnt = 10'h0;
                    next_data_bit = 4'h0;
                end
                else if (cnt == BAUD_DELAY) begin
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
                if (cnt == BAUD_DELAY) begin
                    next_trans_state = NO_SEND;
                    next_cnt = 10'h0;
                    stop_bit_sent = 1'b1;
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
            data <= shift_reg_tx_o;
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
    assign end_char_tx = stop_bit_sent;
    
endmodule



