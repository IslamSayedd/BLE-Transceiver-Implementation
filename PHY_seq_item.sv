package PHY_seq_item_pkg;

    import uvm_pkg::*;
    import PHY_config_pkg::*;
    `include "uvm_macros.svh"

    class PHY_seq_item extends uvm_sequence_item;
        `uvm_object_utils(PHY_seq_item)

        // TX Inputs
        rand logic                  rst_n;
        rand logic                  phy_bit_i;
        rand logic                  bit_valid_i;
        rand logic [15:0]           tap_value_i;
        rand logic [3:0]            tap_address_i;

        // RX Inputs
        rand logic [11:0]           Quadrature_Phase_RX_i;
        rand logic [11:0]           In_Phase_RX_i;
        rand logic                  RX_Valid_i;

        // TX Outputs
        logic [11:0]                Quadrature_Phase_AGC_o;
        logic [11:0]                In_Phase_AGC_o;

        // RX Outputs
        logic                       rx_bit_o;
        logic                       rx_bit_valid_o;

        // RSSI Output
        logic                       signal_flag_o;

        function new(string name = "PHY_seq_item");
            super.new(name);
        endfunction

        function string convert2string();
            return $sformatf("%s rst_n = %0b, phy_bit_i = %0b, bit_valid_i = %0b, tap_value_i = %0h, tap_address_i = %0h, Quadrature_Phase_RX_i = %0h, In_Phase_RX_i = %0h, RX_Valid_i = %0b, Quadrature_Phase_AGC_o = %0h, In_Phase_AGC_o = %0h, rx_bit_o = %0b, rx_bit_valid_o = %0b, signal_flag_o = %0b",
            super.convert2string(), rst_n, phy_bit_i, bit_valid_i, tap_value_i, tap_address_i, Quadrature_Phase_RX_i, In_Phase_RX_i, RX_Valid_i, Quadrature_Phase_AGC_o, In_Phase_AGC_o, rx_bit_o, rx_bit_valid_o, signal_flag_o);
        endfunction

        function string convert2string_stimulus();
            return $sformatf("rst_n = %0b, phy_bit_i = %0b, bit_valid_i = %0b, tap_value_i = %0h, tap_address_i = %0h, Quadrature_Phase_RX_i = %0h, In_Phase_RX_i = %0h, RX_Valid_i = %0b",
            rst_n, phy_bit_i, bit_valid_i, tap_value_i, tap_address_i, Quadrature_Phase_RX_i, In_Phase_RX_i, RX_Valid_i);
        endfunction

    endclass

endpackage