package PHY_driver_pkg;

    import PHY_seq_item_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class PHY_driver extends uvm_driver #(PHY_seq_item);
        `uvm_component_utils(PHY_driver)

        virtual BLE_PHY_if BLE_PHY_vif;
        PHY_seq_item stim_seq_item;

        function new(string name = "PHY_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                stim_seq_item = PHY_seq_item::type_id::create("stim_seq_item");
                seq_item_port.get_next_item(stim_seq_item);

                // TX Inputs
                BLE_PHY_vif.rst_n          = stim_seq_item.rst_n;
                BLE_PHY_vif.phy_bit_i      = stim_seq_item.phy_bit_i;
                BLE_PHY_vif.bit_valid_i    = stim_seq_item.bit_valid_i;
                BLE_PHY_vif.tap_value_i    = stim_seq_item.tap_value_i;
                BLE_PHY_vif.tap_address_i  = stim_seq_item.tap_address_i;

                // RX Inputs
                BLE_PHY_vif.Quadrature_Phase_RX_i  = stim_seq_item.Quadrature_Phase_RX_i;
                BLE_PHY_vif.In_Phase_RX_i          = stim_seq_item.In_Phase_RX_i;
                BLE_PHY_vif.RX_Valid_i             = stim_seq_item.RX_Valid_i;

                @(negedge BLE_PHY_vif.clk);

                seq_item_port.item_done();
                `uvm_info("run_phase", stim_seq_item.convert2string_stimulus(), UVM_HIGH)
            end
        endtask

    endclass

endpackage