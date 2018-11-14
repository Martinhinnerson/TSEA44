onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider lab0_zed_tb
add wave -noupdate /lab0_zed_tb/clk_i
add wave -noupdate /lab0_zed_tb/rst_i
add wave -noupdate /lab0_zed_tb/send_i
add wave -noupdate -radix ascii /lab0_zed_tb/switch_i
add wave -noupdate -radix ascii /lab0_zed_tb/led_o
add wave -noupdate /lab0_zed_tb/jumper
add wave -noupdate -divider lab0
add wave -noupdate /lab0_zed_tb/uart/clk_i
add wave -noupdate /lab0_zed_tb/uart/rst_i
add wave -noupdate /lab0_zed_tb/uart/rx_i
add wave -noupdate /lab0_zed_tb/uart/tx_o
add wave -noupdate /lab0_zed_tb/uart/led_o
add wave -noupdate /lab0_zed_tb/uart/switch_i
add wave -noupdate /lab0_zed_tb/uart/send_i
add wave -noupdate -height 16 /lab0_zed_tb/uart/t_state
add wave -noupdate -height 16 /lab0_zed_tb/uart/r_state
add wave -noupdate -radix unsigned /lab0_zed_tb/uart/internal_clock
add wave -noupdate /lab0_zed_tb/uart/send_flag
add wave -noupdate /lab0_zed_tb/uart/t_buf
add wave -noupdate /lab0_zed_tb/uart/r_buf
add wave -noupdate -radix unsigned /lab0_zed_tb/uart/t_data_ctr
add wave -noupdate -radix unsigned /lab0_zed_tb/uart/r_data_ctr
add wave -noupdate /lab0_zed_tb/uart/next_t_state
add wave -noupdate /lab0_zed_tb/uart/next_r_state
add wave -noupdate /lab0_zed_tb/uart/tx_logic
add wave -noupdate /lab0_zed_tb/uart/output_logic
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {19238411 ps} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {105 us}
