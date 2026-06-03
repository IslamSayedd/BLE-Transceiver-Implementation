package PHY_coverage_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import PHY_seq_item_pkg::*;

class PHY_coverage extends uvm_component;
    `uvm_component_utils(PHY_coverage)
    PHY_seq_item seq_item_cov;
    uvm_analysis_export #(PHY_seq_item) cov_export;
    uvm_tlm_analysis_fifo #(PHY_seq_item) cov_fifo;


    covergroup cp;

        //======================================================================
        // TX Input Coverpoints
        //======================================================================
        phy_bit_i_cp: coverpoint seq_item_cov.phy_bit_i 
        {
            bins phy_bit_low  = {1'b0};
            bins phy_bit_high = {1'b1};
        }

        bit_valid_i_cp: coverpoint seq_item_cov.bit_valid_i 
        {
            bins bit_valid_low  = {1'b0};
            bins bit_valid_high = {1'b1};
        }

        valid_x_data_cp: cross bit_valid_i_cp, phy_bit_i_cp 
        {
            bins idle_zero    = binsof(bit_valid_i_cp.bit_valid_low)  && binsof(phy_bit_i_cp.phy_bit_low);
            bins idle_one     = binsof(bit_valid_i_cp.bit_valid_low)  && binsof(phy_bit_i_cp.phy_bit_high);
            bins active_zero  = binsof(bit_valid_i_cp.bit_valid_high) && binsof(phy_bit_i_cp.phy_bit_low);      
            bins active_one   = binsof(bit_valid_i_cp.bit_valid_high) && binsof(phy_bit_i_cp.phy_bit_high);    
        }

        tap_address_i_cp: coverpoint seq_item_cov.tap_address_i 
        {
            bins addr_0_k_neg8   = {4'd0};
            bins addr_1_k_neg7   = {4'd1};
            bins addr_2_k_neg6   = {4'd2};
            bins addr_3_k_neg5   = {4'd3};
            bins addr_4_k_neg4   = {4'd4};
            bins addr_5_k_neg3   = {4'd5};
            bins addr_6_k_neg2   = {4'd6};
            bins addr_7_k_neg1   = {4'd7};
            bins addr_8_k_centre = {4'd8};
        }

        tap_value_i_cp: coverpoint seq_item_cov.tap_value_i 
        {
            bins val_tail      = {16'd1};
            bins val_neartail  = {16'd6};
            bins val_low       = {16'd27};
            bins val_lowmid    = {16'd93};
            bins val_mid       = {16'd254};
            bins val_midhigh   = {16'd553};
            bins val_high      = {16'd965};
            bins val_nearpeak  = {16'd1347};
            bins val_peak      = {16'd1505};
            ignore_bins val_ignore = {16'd0};
        }

        tap_addr_x_val_cp: cross tap_address_i_cp, tap_value_i_cp 
        {
            bins cross_addr0_val1    = binsof(tap_address_i_cp.addr_0_k_neg8)   && binsof(tap_value_i_cp.val_tail);
            bins cross_addr1_val6    = binsof(tap_address_i_cp.addr_1_k_neg7)   && binsof(tap_value_i_cp.val_neartail);
            bins cross_addr2_val27   = binsof(tap_address_i_cp.addr_2_k_neg6)   && binsof(tap_value_i_cp.val_low);
            bins cross_addr3_val93   = binsof(tap_address_i_cp.addr_3_k_neg5)   && binsof(tap_value_i_cp.val_lowmid);
            bins cross_addr4_val254  = binsof(tap_address_i_cp.addr_4_k_neg4)   && binsof(tap_value_i_cp.val_mid);
            bins cross_addr5_val553  = binsof(tap_address_i_cp.addr_5_k_neg3)   && binsof(tap_value_i_cp.val_midhigh);
            bins cross_addr6_val965  = binsof(tap_address_i_cp.addr_6_k_neg2)   && binsof(tap_value_i_cp.val_high);
            bins cross_addr7_val1347 = binsof(tap_address_i_cp.addr_7_k_neg1)   && binsof(tap_value_i_cp.val_nearpeak);
            bins cross_addr8_val1505 = binsof(tap_address_i_cp.addr_8_k_centre) && binsof(tap_value_i_cp.val_peak);
            ignore_bins addr0_mismatch = binsof(tap_address_i_cp.addr_0_k_neg8) && !binsof(tap_value_i_cp.val_tail);
            ignore_bins addr1_mismatch = binsof(tap_address_i_cp.addr_1_k_neg7) && !binsof(tap_value_i_cp.val_neartail);
            ignore_bins addr2_mismatch = binsof(tap_address_i_cp.addr_2_k_neg6) && !binsof(tap_value_i_cp.val_low);
            ignore_bins addr3_mismatch = binsof(tap_address_i_cp.addr_3_k_neg5) && !binsof(tap_value_i_cp.val_lowmid);
            ignore_bins addr4_mismatch = binsof(tap_address_i_cp.addr_4_k_neg4) && !binsof(tap_value_i_cp.val_mid);
            ignore_bins addr5_mismatch = binsof(tap_address_i_cp.addr_5_k_neg3) && !binsof(tap_value_i_cp.val_midhigh);
            ignore_bins addr6_mismatch = binsof(tap_address_i_cp.addr_6_k_neg2) && !binsof(tap_value_i_cp.val_high);
            ignore_bins addr7_mismatch = binsof(tap_address_i_cp.addr_7_k_neg1) && !binsof(tap_value_i_cp.val_nearpeak);
            ignore_bins addr8_mismatch = binsof(tap_address_i_cp.addr_8_k_centre) && !binsof(tap_value_i_cp.val_peak);
        }

        //======================================================================
        // AGC Output Coverpoints (TX path)
        //======================================================================
        In_Phase_AGC_o_cp: coverpoint seq_item_cov.In_Phase_AGC_o
        {
            bins negative  = {[12'h800:12'hFFF]};
            bins zero      = {12'h000};
            bins positive  = {[12'h001:12'h7FF]};
        }

        Quadrature_Phase_AGC_o_cp: coverpoint seq_item_cov.Quadrature_Phase_AGC_o
        {
            bins negative  = {[12'h800:12'hFFF]};
            bins zero      = {12'h000};
            bins positive  = {[12'h001:12'h7FF]};
        }

        //======================================================================
        // RX Input Coverpoints
        //======================================================================
        RX_Valid_i_cp: coverpoint seq_item_cov.RX_Valid_i
        {
            bins rx_valid_low  = {1'b0};
            bins rx_valid_high = {1'b1};
        }

        In_Phase_RX_i_cp: coverpoint seq_item_cov.In_Phase_RX_i
        {
            bins negative  = {[12'h800:12'hFFF]};
            bins zero      = {12'h000};
            bins positive  = {[12'h001:12'h7FF]};
        }

        Quadrature_Phase_RX_i_cp: coverpoint seq_item_cov.Quadrature_Phase_RX_i
        {
            bins negative  = {[12'h800:12'hFFF]};
            bins zero      = {12'h000};
            bins positive  = {[12'h001:12'h7FF]};
        }

        // Cross: RX valid with actual IQ data present
        RX_valid_x_InPhase_cp: cross RX_Valid_i_cp, In_Phase_RX_i_cp
        {
            bins valid_negative = binsof(RX_Valid_i_cp.rx_valid_high) && binsof(In_Phase_RX_i_cp.negative);
            bins valid_zero     = binsof(RX_Valid_i_cp.rx_valid_high) && binsof(In_Phase_RX_i_cp.zero);
            bins valid_positive = binsof(RX_Valid_i_cp.rx_valid_high) && binsof(In_Phase_RX_i_cp.positive);
            bins idle           = binsof(RX_Valid_i_cp.rx_valid_low);
        }

        //======================================================================
        // RX Output Coverpoints
        //======================================================================
        rx_bit_o_cp: coverpoint seq_item_cov.rx_bit_o 
        {
            bins rising  = (1'b0 => 1'b1);
            bins falling = (1'b1 => 1'b0);
        }

        rx_bit_valid_o_cp: coverpoint seq_item_cov.rx_bit_valid_o 
        {
            bins rx_bit_valid_low  = {1'b0};
            bins rx_bit_valid_high = {1'b1};
        }

        // Cross: only care about rx_bit value when rx_bit_valid is high
        rx_valid_x_bit_cp: cross rx_bit_valid_o_cp, rx_bit_o_cp
        {
            bins valid_bit_low  = binsof(rx_bit_valid_o_cp.rx_bit_valid_high) && binsof(rx_bit_o_cp.falling);
            bins valid_bit_high = binsof(rx_bit_valid_o_cp.rx_bit_valid_high) && binsof(rx_bit_o_cp.rising);
            ignore_bins invalid = binsof(rx_bit_valid_o_cp.rx_bit_valid_low);
        }

        //======================================================================
        // RSSI Output Coverpoints
        //======================================================================
        signal_flag_o_cp: coverpoint seq_item_cov.signal_flag_o
        {
            bins signal_flag_o_low  = {1'b0};
            bins signal_flag_o_high = {1'b1};
        }
    endgroup


    function new(string name = "PHY_coverage" , uvm_component parent = null);
        super.new(name , parent);
        cp = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cov_export = new("cov_export" , this);
        cov_fifo   = new("cov_fifo"   , this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        cov_export.connect(cov_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            cov_fifo.get(seq_item_cov);
            cp.sample();
        end
    endtask

endclass //PHY_coverage extends uvm_component
    
endpackage