package PHY_monitor_pkg;
import PHY_seq_item_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
class PHY_monitor extends uvm_monitor;
    `uvm_component_utils(PHY_monitor)
    virtual BLE_PHY_if BLE_PHY_vif;
    PHY_seq_item rsp_seq_item;
    uvm_analysis_port #(PHY_seq_item) mon_ap;

    function new( string name = "PHY_monitor" , uvm_component parent = null);
        super.new(name , parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_ap = new("mon_ap" , this);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            rsp_seq_item = PHY_seq_item::type_id::create("PHY_seq_item");
            @(negedge BLE_PHY_vif.clk);
            rsp_seq_item.rst_n          =   BLE_PHY_vif.rst_n;
            rsp_seq_item.phy_bit_i      =   BLE_PHY_vif.phy_bit_i;
            rsp_seq_item.bit_valid_i    =   BLE_PHY_vif.bit_valid_i;
            rsp_seq_item.tap_value_i    =   BLE_PHY_vif.tap_value_i;
            rsp_seq_item.tap_address_i  =   BLE_PHY_vif.tap_address_i;
            rsp_seq_item.rssi_out_o     =   BLE_PHY_vif.rssi_out_o;
            rsp_seq_item.rssi_valid_o   =   BLE_PHY_vif.rssi_valid_o;
            rsp_seq_item.signal_flag_o  =   BLE_PHY_vif.signal_flag_o;
            rsp_seq_item.rx_bit_o       =   BLE_PHY_vif.rx_bit_o;
            rsp_seq_item.rx_bit_valid_o =   BLE_PHY_vif.rx_bit_valid_o;
            mon_ap.write(rsp_seq_item);
            `uvm_info("run_phase" , rsp_seq_item.convert2string() , UVM_HIGH);
        end
        
    endtask
endclass    //PHY_monitor extends uvm_monitor

endpackage