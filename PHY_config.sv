package PHY_config_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"

class PHY_config extends uvm_object;
`uvm_object_utils(PHY_config)
virtual PHY_if PHY_vif;
    function new(string name = "PHY_config");
        super.new(name);
    endfunction 
endclass //PHY_config extends superClass
    
endpackage