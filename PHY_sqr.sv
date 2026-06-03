package PHY_sqr_pkg;

    import uvm_pkg::*;
    import PHY_seq_item_pkg::*;
    `include "uvm_macros.svh"

    class PHY_sqr extends uvm_sequencer #(PHY_seq_item);
        `uvm_component_utils(PHY_sqr)

        function new(string name = "PHY_sqr", uvm_component parent = null);
            super.new(name, parent);
        endfunction

    endclass

endpackage