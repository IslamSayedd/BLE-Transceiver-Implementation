package PHY_env_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import PHY_sb_pkg::*;
import PHY_agent_pkg::*;
import PHY_coverage_pkg::*;

class PHY_env extends uvm_env;

    `uvm_component_utils(PHY_env);
    PHY_coverage cov;
    PHY_agent agt;
    PHY_sb sb;

    function new( string name = "PHY_env" , uvm_component parent = null);
        super.new(name , parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = PHY_agent::type_id::create("agt",this);
        cov = PHY_coverage::type_id::create("cov",this);
        sb  = PHY_sb::type_id::create("sb",this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.agt_ap.connect(sb.sb_export);
        agt.agt_ap.connect(cov.cov_export);
    endfunction

endclass //PHY_env extends superClass
endpackage