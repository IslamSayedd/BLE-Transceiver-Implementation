package PHY_agent_pkg;

    import PHY_seq_item_pkg::*;
    import PHY_driver_pkg::*;
    import PHY_monitor_pkg::*;
    import PHY_sqr_pkg::*;
    import PHY_config_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class PHY_agent extends uvm_agent;
        `uvm_component_utils(PHY_agent)

        PHY_driver drv;
        PHY_monitor mon;
        PHY_sqr sqr;
        PHY_config cfg;
        uvm_analysis_port #(PHY_seq_item) agt_ap;

        function new(string name = "PHY_agent", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if(!uvm_config_db #(PHY_config)::get(this, "", "vif", cfg)) begin
                `uvm_fatal("build_phase", "Agent - Unable to get configuration object");
            end

            drv = PHY_driver::type_id::create("drv", this);
            mon = PHY_monitor::type_id::create("mon", this);
            sqr = PHY_sqr::type_id::create("sqr", this);
            agt_ap = new("agt_ap", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);

            drv.BLE_PHY_vif = cfg.BLE_PHY_vif;
            mon.BLE_PHY_vif = cfg.BLE_PHY_vif;
            drv.seq_item_port.connect(sqr.seq_item_export);
            mon.mon_ap.connect(agt_ap);
        endfunction

    endclass

endpackage