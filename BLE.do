vlib work
vlog NRZ.sv NRZ_upsample.sv upsample.sv gaussian_filter.sv VCO.sv Power_Estimator.sv avgerage_filter.sv log10_32bits.sv fsk_demod_mult_v1.sv bit_downsampler.sv Accumulator.sv agc_top.sv RSSI_TOP.sv BLE_TX_PHY.sv BLE_RX_PHY.sv BLE_PHY.sv BLE_PHY_verif.sv BLE_PHY_if.sv PHY_config.sv PHY_seq_item.sv PHY_sqr.sv PHY_sequence.sv PHY_driver.sv PHY_monitor.sv PHY_coverage.sv PHY_sb.sv PHY_agent.sv PHY_env.sv PHY_test.sv PHY_sva.sv BLE_PHY_top.sv +cover -covercells
vsim -voptargs="+acc" -suppress 3009 work.BLE_PHY_top -cover
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
run -all
coverage save BLE_PHY_top.ucdb -onexit