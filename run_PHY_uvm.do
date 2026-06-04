vlib work
vlog -f src_files.list +cover -covercells
vsim -voptargs=+acc work.BLE_PHY_top -classdebug -uvmcontrol=all -cover 
add wave -r /BLE_PHY_top/*
add wave -divider "RX PATH"
add wave /BLE_PHY_top/DUT/u_RX/u_fsk_demod/iq_valid_i
add wave /BLE_PHY_top/DUT/u_RX/u_fsk_demod/in_phase_i_i
add wave /BLE_PHY_top/DUT/u_RX/u_fsk_demod/quadrature_q_i
add wave /BLE_PHY_top/DUT/u_RX/u_fsk_demod/in_phase_i_0
add wave /BLE_PHY_top/DUT/u_RX/u_fsk_demod/in_phase_i_1
add wave /BLE_PHY_top/DUT/u_RX/u_fsk_demod/quadrature_q_0
add wave /BLE_PHY_top/DUT/u_RX/u_fsk_demod/quadrature_q_1
add wave /BLE_PHY_top/DUT/u_RX/u_fsk_demod/decision
add wave /BLE_PHY_top/DUT/u_RX/u_fsk_demod/demod_signal_o
add wave /BLE_PHY_top/DUT/u_RX/u_fsk_demod/demod_signal_valid_o
add wave /BLE_PHY_top/DUT/u_RX/u_fsk_demod/valid_pipe
add wave -divider "DOWNSAMPLER"
add wave /BLE_PHY_top/DUT/u_RX/u_bit_downsampler/bit_i
add wave /BLE_PHY_top/DUT/u_RX/u_bit_downsampler/bit_valid_i
add wave /BLE_PHY_top/DUT/u_RX/u_bit_downsampler/cnt
add wave /BLE_PHY_top/DUT/u_RX/u_bit_downsampler/bit_o
add wave /BLE_PHY_top/DUT/u_RX/u_bit_downsampler/bit_valid_o
coverage save TX_top.ucdb -onexit 
run -all