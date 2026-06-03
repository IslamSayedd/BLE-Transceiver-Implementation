import PHY_test_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
module BLE_PHY_top ();
    parameter CLOCK_PERIOD = 10;
    bit clk;
    initial begin
        clk=0;
        forever begin
           #(CLOCK_PERIOD/2) clk=~clk;
        end
    end

    BLE_PHY_if PHY_if (clk);
    BLE_PHY_verif DUT(PHY_if);
    bind BLE_PHY_verif PHY_sva BLE_PHY_if_inst (PHY_if);

    initial begin
        $readmemh("sin_lut.txt", DUT.u_TX.u_vco.u_iq_wave_generator.sin_mem);
        $readmemh("cos_lut.txt", DUT.u_TX.u_vco.u_iq_wave_generator.cos_mem);
        $readmemh("log2_lut.mem", DUT.u_RSSI.u_log10.log2_lut);
        uvm_config_db #(virtual BLE_PHY_if) ::set (null , "uvm_test_top" , "BLE_PHY_if" , PHY_if);
        run_test("PHY_test");    
    end

endmodule