package PHY_seq_pkg;

    import uvm_pkg::*;
    import PHY_seq_item_pkg::*;
    `include "uvm_macros.svh"

    // Reset Sequence
    class PHY_rst_seq extends uvm_sequence #(PHY_seq_item);
        `uvm_object_utils(PHY_rst_seq)

        PHY_seq_item seq_item;

        function new(string name = "PHY_rst_seq");
            super.new(name);
        endfunction

        task body();
            seq_item = PHY_seq_item::type_id::create("seq_item");
            start_item(seq_item);

            seq_item.rst_n                  = 0;
            seq_item.phy_bit_i              = 0;
            seq_item.bit_valid_i            = 0;
            seq_item.tap_value_i            = 0;
            seq_item.tap_address_i          = 0;
            seq_item.Quadrature_Phase_RX_i  = 0;
            seq_item.In_Phase_RX_i          = 0;
            seq_item.RX_Valid_i             = 0;

            finish_item(seq_item);
        endtask

    endclass


    class PHY_cov_tap_seq extends uvm_sequence #(PHY_seq_item);
        `uvm_object_utils(PHY_cov_tap_seq)

        PHY_seq_item seq_item;

        // Specific tap values matching coverage bins
        logic [15:0] cov_taps [9] = '{
            16'd1,    // addr 0 - val_tail
            16'd6,    // addr 1 - val_neartail
            16'd27,   // addr 2 - val_low
            16'd93,   // addr 3 - val_lowmid
            16'd254,  // addr 4 - val_mid
            16'd553,  // addr 5 - val_midhigh
            16'd965,  // addr 6 - val_high
            16'd1347, // addr 7 - val_nearpeak
            16'd1505  // addr 8 - val_peak
        };

        function new(string name = "PHY_cov_tap_seq");
            super.new(name);
        endfunction

        task body();
            for (int i = 0; i < 9; i++) begin
                seq_item = PHY_seq_item::type_id::create("seq_item");
                start_item(seq_item);

                seq_item.rst_n                  = 1;
                seq_item.tap_address_i          = i;
                seq_item.tap_value_i            = cov_taps[i];
                seq_item.phy_bit_i              = 0;
                seq_item.bit_valid_i            = 0;
                seq_item.Quadrature_Phase_RX_i  = 0;
                seq_item.In_Phase_RX_i          = 0;
                seq_item.RX_Valid_i             = 0;

                finish_item(seq_item);
            end
        endtask

    endclass


    // TX Sequence
    class PHY_tx_seq extends uvm_sequence #(PHY_seq_item);
        `uvm_object_utils(PHY_tx_seq)

        PHY_seq_item seq_item;

        function new(string name = "PHY_tx_seq");
            super.new(name);
        endfunction

        task body();
            repeat(15000) begin
                seq_item = PHY_seq_item::type_id::create("seq_item");
                start_item(seq_item);

                assert(seq_item.randomize());
                seq_item.bit_valid_i  = 1;
                seq_item.RX_Valid_i = 0;

                finish_item(seq_item);
            end
        endtask

    endclass

    // RX Sequence
    class PHY_rx_seq extends uvm_sequence #(PHY_seq_item);
        `uvm_object_utils(PHY_rx_seq)

        PHY_seq_item seq_item;

        function new(string name = "PHY_rx_seq");
            super.new(name);
        endfunction

        task body();
            repeat(15000) begin
                seq_item = PHY_seq_item::type_id::create("seq_item");
                start_item(seq_item);

                assert(seq_item.randomize());
                seq_item.bit_valid_i  = 0;
                seq_item.RX_Valid_i = 1;

                finish_item(seq_item);
            end
        endtask

    endclass

    // Tap Loading Sequence
    /*class PHY_tap_seq extends uvm_sequence #(PHY_seq_item);
        `uvm_object_utils(PHY_tap_seq)

        PHY_seq_item seq_item;
        logic [15:0] taps [9];

        function new(string name = "PHY_tap_seq");
            super.new(name);
        endfunction

        task body();
            // Load taps from file
            $readmemh("taps.txt", taps);

            // Send all 9 taps in order
            for (int i = 0; i < 9; i++) begin
                seq_item = PHY_seq_item::type_id::create("seq_item");
                start_item(seq_item);

                seq_item.rst_n                  = 1;
                seq_item.tap_address_i          = i;
                seq_item.tap_value_i            = taps[i];
                seq_item.phy_bit_i              = 0;
                seq_item.bit_valid_i            = 0;
                seq_item.Quadrature_Phase_RX_i  = 0;
                seq_item.In_Phase_RX_i          = 0;
                seq_item.RX_Valid_i             = 0;

                finish_item(seq_item);
            end
        endtask

    endclass*/

    // Full Flow Sequence
    class PHY_sending_seq extends uvm_sequence #(PHY_seq_item);
        `uvm_object_utils(PHY_sending_seq)

        PHY_seq_item seq_item;

        function new(string name = "PHY_sending_seq");
            super.new(name);
        endfunction

        task body();
            repeat(150000) begin
                seq_item = PHY_seq_item::type_id::create("seq_item");
                start_item(seq_item);

                assert(seq_item.randomize());

                finish_item(seq_item);
            end
        endtask

    endclass

endpackage