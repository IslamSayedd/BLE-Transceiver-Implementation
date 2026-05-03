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
            bins idle_zero    = binsof(bit_valid_i_cp.bit_valid_low)     &&  binsof(phy_bit_i_cp.phy_bit_low);
            bins idle_one     = binsof(bit_valid_i_cp.bit_valid_low)     &&  binsof(phy_bit_i_cp.phy_bit_high);
            bins active_zero  = binsof(bit_valid_i_cp.bit_valid_high)    &&  binsof(phy_bit_i_cp.phy_bit_low);      
            bins active_one   = binsof(bit_valid_i_cp.bit_valid_high)    &&  binsof(phy_bit_i_cp.phy_bit_high);    
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
            bins addr_8_k_centre = {4'd8};   // peak tap (k=0, value=1505)
        }

        tap_value_i_cp: coverpoint seq_item_cov.tap_value_i 
        {
            bins val_tail      = {16'd1};     // k = ±8
            bins val_neartail  = {16'd6};     // k = ±7
            bins val_low       = {16'd27};    // k = ±6
            bins val_lowmid    = {16'd93};    // k = ±5
            bins val_mid       = {16'd254};   // k = ±4
            bins val_midhigh   = {16'd553};   // k = ±3
            bins val_high      = {16'd965};   // k = ±2
            bins val_nearpeak  = {16'd1347};  // k = ±1
            bins val_peak      = {16'd1505};  // k =  0  ← Gaussian centre
            illegal_bins val_illegal = default;
        }

        tap_addr_x_val_cp: cross tap_address_i_cp, tap_value_i_cp 
        {
            // ---- legal (address, value) pairs ----
            bins cross_addr0_val1    = binsof(tap_address_i_cp.addr_0_k_neg8)   && binsof(tap_value_i_cp.val_tail);
            bins cross_addr1_val6    = binsof(tap_address_i_cp.addr_1_k_neg7)   && binsof(tap_value_i_cp.val_neartail);
            bins cross_addr2_val27   = binsof(tap_address_i_cp.addr_2_k_neg6)   && binsof(tap_value_i_cp.val_low);
            bins cross_addr3_val93   = binsof(tap_address_i_cp.addr_3_k_neg5)   && binsof(tap_value_i_cp.val_lowmid);
            bins cross_addr4_val254  = binsof(tap_address_i_cp.addr_4_k_neg4)   && binsof(tap_value_i_cp.val_mid);
            bins cross_addr5_val553  = binsof(tap_address_i_cp.addr_5_k_neg3)   && binsof(tap_value_i_cp.val_midhigh);
            bins cross_addr6_val965  = binsof(tap_address_i_cp.addr_6_k_neg2)   && binsof(tap_value_i_cp.val_high);
            bins cross_addr7_val1347 = binsof(tap_address_i_cp.addr_7_k_neg1)   && binsof(tap_value_i_cp.val_nearpeak);
            bins cross_addr8_val1505 = binsof(tap_address_i_cp.addr_8_k_centre) && binsof(tap_value_i_cp.val_peak);

            // ---- everything else is a mismatch — flag it immediately ----
            illegal_bins cross_mismatch = default;
        }

        rssi_valid_o_cp: coverpoint seq_item_cov.rssi_valid_o
        {
            bins rssi_valid_low  = {1'b0};
            bins rssi_valid_high = {1'b1};
        }

        signal_flag_o_cp: coverpoint seq_item_cov.signal_flag_o
        {
            bins signal_flag_o_low   = {1'b0};
            bins signal_flag_o_high  = {1'b1};
        }

        rssi_out_o_cp: coverpoint seq_item_cov.rssi_out_o
        {
            bins rssi_very_weak  = {[16'd0    : 16'd1228]};   // < -80 dBm equivalent
            bins rssi_weak       = {[16'd1229  : 16'd1843]};  // -80 to -70 dBm (below threshold)
            bins rssi_medium     = {[16'd1844  : 16'd2457]};  // -70 to -60 dBm (above threshold)
            bins rssi_strong     = {[16'd2458  : 16'd3072]};  // -60 to -50 dBm
            bins rssi_very_strong= {[16'd3073  : 16'd65535]}; // > -50 dBm
        }

        // Cross: rssi output zone with signal_flag — verify threshold logic is correct
        rssi_out_x_flag_cp: cross rssi_out_o_cp, signal_flag_o_cp
        {
            // Below threshold zones must have flag = 0
            illegal_bins weak_zone_strong_flag  = binsof(rssi_out_o_cp.rssi_very_weak)      && binsof(signal_flag_o_cp.signal_flag_o_high);
            illegal_bins below_thresh_strong    = binsof(rssi_out_o_cp.rssi_weak)           && binsof(signal_flag_o_cp.signal_flag_o_high);
            // Above threshold zones must have flag = 1
            illegal_bins above_thresh_weak      = binsof(rssi_out_o_cp.rssi_medium)         && binsof(signal_flag_o_cp.signal_flag_o_low);
            illegal_bins strong_zone_weak_flag  = binsof(rssi_out_o_cp.rssi_strong)         && binsof(signal_flag_o_cp.signal_flag_o_low);
            illegal_bins vstrong_zone_weak_flag = binsof(rssi_out_o_cp.rssi_very_strong)    && binsof(signal_flag_o_cp.signal_flag_o_low);
        }

        rx_bit_o_cp: coverpoint seq_item_cov.rx_bit_o 
        {
            bins rising  = (1'b0 => 1'b1);
            bins falling = (1'b1 => 1'b0);
        }

        rx_bit_valid_o_cp: coverpoint seq_item_cov.rx_bit_valid_o 
        {
            bins rx_bit_valid_low    = {1'b0};
            bins rx_bit_valid_high   = {1'b1};
        }
        
    endgroup


    function new(string name = "PHY_coverage" , uvm_component parent = null);
        super.new(name , parent);
        cp = new();
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cov_export = new("cov_export" , this);
        cov_fifo = new("cov_fifo" , this);
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