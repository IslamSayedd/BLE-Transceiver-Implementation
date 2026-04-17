onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group tb -color Orange /RSSI_TOP_tb/clk
add wave -noupdate -expand -group tb -color Orange -format Literal /RSSI_TOP_tb/rst_n
add wave -noupdate -expand -group tb -color Orange -format Literal /RSSI_TOP_tb/valid_i
add wave -noupdate -expand -group tb -color Orange /RSSI_TOP_tb/I_in
add wave -noupdate -expand -group tb -color Orange /RSSI_TOP_tb/Q_in
add wave -noupdate -expand -group tb -color Orange /RSSI_TOP_tb/rssi_out_o
add wave -noupdate -expand -group tb -color Orange -format Literal /RSSI_TOP_tb/rssi_valid_o
add wave -noupdate -expand -group tb -color Orange -format Literal /RSSI_TOP_tb/signal_flag_o
add wave -noupdate -group db -color {Medium Orchid} -format Literal -itemcolor White /RSSI_TOP_tb/DUT/u_log10/valid_in_i
add wave -noupdate -group db -color {Medium Orchid} -itemcolor White /RSSI_TOP_tb/DUT/u_log10/avg_power_i
add wave -noupdate -group db -color {Medium Orchid} -itemcolor White /RSSI_TOP_tb/DUT/u_log10/rssi_out_o
add wave -noupdate -group db -color {Medium Orchid} -format Literal -itemcolor White /RSSI_TOP_tb/DUT/u_log10/valid_out_o
add wave -noupdate -group db -color {Medium Orchid} -itemcolor White /RSSI_TOP_tb/DUT/u_log10/x
add wave -noupdate -group db -color {Medium Orchid} -itemcolor White /RSSI_TOP_tb/DUT/u_log10/k
add wave -noupdate -group db -color {Medium Orchid} -itemcolor White /RSSI_TOP_tb/DUT/u_log10/frac_index
add wave -noupdate -group db -color {Medium Orchid} -itemcolor White /RSSI_TOP_tb/DUT/u_log10/frac_value
add wave -noupdate -group db -color {Medium Orchid} -itemcolor White /RSSI_TOP_tb/DUT/u_log10/log2_fixed
add wave -noupdate -group db -color {Medium Orchid} -itemcolor White /RSSI_TOP_tb/DUT/u_log10/scaled
add wave -noupdate -expand -group filter -color Yellow -format Literal /RSSI_TOP_tb/DUT/u_avg_filter/valid_in_i
add wave -noupdate -expand -group filter -color Yellow /RSSI_TOP_tb/DUT/u_avg_filter/data_in_i
add wave -noupdate -expand -group filter -color Yellow /RSSI_TOP_tb/DUT/u_avg_filter/avg_out_o
add wave -noupdate -expand -group filter -color Yellow -format Literal /RSSI_TOP_tb/DUT/u_avg_filter/valid_out_o
add wave -noupdate -expand -group filter -color Yellow /RSSI_TOP_tb/DUT/u_avg_filter/wr_ptr
add wave -noupdate -expand -group filter -color Yellow /RSSI_TOP_tb/DUT/u_avg_filter/sum
add wave -noupdate -expand -group filter -color Yellow /RSSI_TOP_tb/DUT/u_avg_filter/next_sum
add wave -noupdate -expand -group filter -color Yellow /RSSI_TOP_tb/DUT/u_avg_filter/i
add wave -noupdate -expand -group power_est -color Cyan -format Literal /RSSI_TOP_tb/DUT/u_power_estimator/valid_in
add wave -noupdate -expand -group power_est -color Cyan /RSSI_TOP_tb/DUT/u_power_estimator/I_in
add wave -noupdate -expand -group power_est -color Cyan /RSSI_TOP_tb/DUT/u_power_estimator/Q_in
add wave -noupdate -expand -group power_est -color Cyan /RSSI_TOP_tb/DUT/u_power_estimator/power_out
add wave -noupdate -expand -group power_est -color Cyan -format Literal /RSSI_TOP_tb/DUT/u_power_estimator/valid_out
add wave -noupdate -expand -group power_est -color Cyan /RSSI_TOP_tb/DUT/u_power_estimator/abs_I
add wave -noupdate -expand -group power_est -color Cyan /RSSI_TOP_tb/DUT/u_power_estimator/abs_Q
add wave -noupdate -expand -group power_est -color Cyan /RSSI_TOP_tb/DUT/u_power_estimator/I_sq
add wave -noupdate -expand -group power_est -color Cyan /RSSI_TOP_tb/DUT/u_power_estimator/Q_sq
add wave -noupdate -expand -group power_est -color Cyan /RSSI_TOP_tb/DUT/u_power_estimator/power_sum
add wave -noupdate -expand -group power_est -color Cyan /RSSI_TOP_tb/DUT/u_power_estimator/i
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {70000 ps} 0}
quietly wave cursor active 1
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {474803 ps}
