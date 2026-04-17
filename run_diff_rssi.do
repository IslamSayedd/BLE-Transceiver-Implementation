vlib work
vlog *.*v
vsim -voptargs=+acc work.RSSI_TOP_tb
do wave.do
run -all
