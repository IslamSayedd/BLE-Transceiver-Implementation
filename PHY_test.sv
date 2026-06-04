package PHY_test_pkg;
import PHY_seq_pkg::*;
import PHY_env_pkg::*;
import PHY_config_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"

class PHY_test extends uvm_test;
    `uvm_component_utils(PHY_test)
    virtual BLE_PHY_if BLE_PHY_vif;
    PHY_rst_seq rst_seq;
    PHY_sending_seq sending_seq;
    PHY_cov_tap_seq cov_tap_seq;
    PHY_tx_seq tx_seq;
    PHY_rx_seq rx_seq;
    PHY_env env;
    PHY_config cfg;

    function new(string name = "PHY_test" , uvm_component parent = null);
        super.new(name , parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        rst_seq     = PHY_rst_seq::type_id::create("rst_seq", this);
        tx_seq      = PHY_tx_seq::type_id::create("tx_seq", this);
        rx_seq      = PHY_rx_seq::type_id::create("rx_seq", this);
        cov_tap_seq = PHY_cov_tap_seq::type_id::create("cov_tap_seq", this);
        sending_seq = PHY_sending_seq::type_id::create("sending_seq", this);
        env = PHY_env::type_id::create("env", this);
        cfg = PHY_config::type_id::create("cfg", this);

        if (!uvm_config_db #(virtual BLE_PHY_if) ::get(this,"","BLE_PHY_if", cfg.BLE_PHY_vif)) begin
            `uvm_fatal("Build Phase" , "Test - Unable to get the interface")
        end
        
        uvm_config_db #(PHY_config) ::set(this,"*","vif",cfg);

    endfunction

    task run_phase(uvm_phase phase);

        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("run_phase","reset low",UVM_LOW);
        rst_seq.start(env.agt.sqr);
        `uvm_info("run_phase","reset high",UVM_LOW);

        `uvm_info("run_phase","Coverage Tap Loading started",UVM_LOW);
        cov_tap_seq.start(env.agt.sqr);
        `uvm_info("run_phase","Coverage Tap Loading ended",UVM_LOW);

        `uvm_info("run_phase","Sending Data started",UVM_LOW);
        tx_seq.start(env.agt.sqr);
        `uvm_info("run_phase","Sending Data ended",UVM_LOW);

        /*`uvm_info("run_phase","Receiving Data started",UVM_LOW);
        rx_seq.start(env.agt.sqr);
        `uvm_info("run_phase","Receiving Data ended",UVM_LOW);*/

        /*`uvm_info("run_phase","Sending Data started",UVM_LOW);
        sending_seq.start(env.agt.sqr);
        `uvm_info("run_phase","Sending Data ended",UVM_LOW);*/

        phase.drop_objection(this);
        
    endtask

endclass
endpackage