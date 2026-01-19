vlib work
vlog *.sv
vsim -voptargs=+acc work.BLE_TX_RX_PHY_tb
do wave_tx_rx.do
run -all
