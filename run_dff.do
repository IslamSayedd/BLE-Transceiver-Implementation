vlib work
vlog *.*v
vsim -voptargs=+acc work.BLE_TX_PHY_tb
do wave.do
run -all
