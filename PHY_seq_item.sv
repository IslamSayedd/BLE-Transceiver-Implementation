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

        constraint rst_c { rst_n dist {0:=2  , 1:=98}; }

        // ─── tap_address_i: only 0–8 are valid array indices (NUM_OF_TAPS=9) 
        constraint tap_addr_range_c {
            tap_address_i inside {[4'd0 : 4'd8]};
        }

        // ─── each address maps to exactly one correct tap value 
        constraint tap_addr_val_paired_c {
            (tap_address_i == 4'd0) -> (tap_value_i == 16'd1   );
            (tap_address_i == 4'd1) -> (tap_value_i == 16'd6   );
            (tap_address_i == 4'd2) -> (tap_value_i == 16'd27  );
            (tap_address_i == 4'd3) -> (tap_value_i == 16'd93  );
            (tap_address_i == 4'd4) -> (tap_value_i == 16'd254 );
            (tap_address_i == 4'd5) -> (tap_value_i == 16'd553 );
            (tap_address_i == 4'd6) -> (tap_value_i == 16'd965 );
            (tap_address_i == 4'd7) -> (tap_value_i == 16'd1347);
            (tap_address_i == 4'd8) -> (tap_value_i == 16'd1505);
        }

        // ─── RX IQ: cover all three signed zones ──────────────────────────────────────
        constraint rx_inphase_zones_c {
            In_Phase_RX_i dist {
                12'h000           := 5,
                [12'h001:12'h7FF] := 45,
                [12'h800:12'hFFF] := 50
            };
        }

        constraint rx_quadphase_zones_c {
            Quadrature_Phase_RX_i dist {
                12'h000           := 5,
                [12'h001:12'h7FF] := 45,
                [12'h800:12'hFFF] := 50
            };
        }

        // ─── RX_Valid_i: bias high to exercise the valid_* cross bins ─────────────────
        constraint rx_valid_c {
            RX_Valid_i dist {1'b0 := 5, 1'b1 := 95};
        }

        constraint tx_rx_mutex_c {
            !(bit_valid_i && RX_Valid_i);
        }

    endclass

endpackage