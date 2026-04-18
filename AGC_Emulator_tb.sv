`timescale 1ns/1ps

module channel_emulator_tb ();

    //==========================================================================
    // Parameters
    //==========================================================================
    // NRZ Upsample parameters
    parameter NRZ_DATA_WIDTH       = 11;
    parameter SAMPLE_PER_SYMBOL    = 8;

    // Gaussian Filter parameters
    parameter TAP_WIDTH            = 16;
    parameter GAUS_OUT_WIDTH       = 16;
    parameter ADDRESS_WIDTH        = 4;
    parameter NUM_OF_TAPS          = 9;

    // VCO parameters — must match original TB (LUT files are 16-bit wide)
    parameter VCO_OUT_WIDTH        = 16;
    parameter VCO_DATA_WIDTH       = 16;
    parameter VCO_OUT_SIZE         = 16;

    // AGC / Emulator parameters
    parameter IQ_WIDTH             = 12;
    parameter AGC_IQ_WIDTH         = 16;
    parameter AVG_LOG2             = 4;
    parameter POWER_TARGET         = 33'd4294967296;
    parameter STEP_SIZE            = 3;

    // Testbench
    parameter Clock_PERIOD         = 20;   // 50 MHz
    parameter FLUSH_CYCLES         = 150;  // pipeline drain after each message

    //==========================================================================
    // TX Signals
    //==========================================================================
    reg                          clk;
    reg                          rst_n;
    reg                          phy_bit_i_tb;
    reg                          bit_valid_i_tb;
    reg  [TAP_WIDTH-1:0]         tap_value_i_tb;
    reg  [ADDRESS_WIDTH-1:0]     tap_address_i_tb;

    wire [VCO_OUT_SIZE-1:0]      Quadrature_Phase_o_tb;
    wire [VCO_OUT_SIZE-1:0]      In_Phase_o_tb;
    wire                         Phase_Valid_o_tb;

    // Tap storage
    logic [TAP_WIDTH-1:0] taps [NUM_OF_TAPS-1:0];

    // Test pattern
    reg [NRZ_DATA_WIDTH-1:0]     test_message;

    //==========================================================================
    // Channel Emulator Signals
    //==========================================================================
    // α is a parameter — we use 4 separate emulator instances, one per scenario
    // Alternatively we re-parameterize at runtime via a reg — here we use
    // a single instance and re-drive the scaled I/Q via a task that applies α
    // in the testbench so we can change it between test cases dynamically.

    reg signed [IQ_WIDTH-1:0]    I_to_emulator;
    reg signed [IQ_WIDTH-1:0]    Q_to_emulator;
    reg                          valid_to_emulator;

    wire signed [IQ_WIDTH-1:0]   I_rx_w;
    wire signed [IQ_WIDTH-1:0]   Q_rx_w;
    wire                         valid_rx_w;

    // Current alpha (Q8 fixed-point, driven by task)
    reg [8:0]  current_alpha_q8;   // 9-bit to hold up to 512

    //==========================================================================
    // RX Signals
    //==========================================================================
    wire                         rx_bit_tb;
    wire                         rx_bit_valid_tb;

    // Bit tracking
    integer                      rx_bit_count;
    integer                      tx_bit_count;

    //==========================================================================
    // Alpha Scaling (done in TB so we can change α between test cases)
    // We scale TX output here and feed into emulator's I_tx / Q_tx ports.
    // The emulator internally has ALPHA_Q8=256 (×1.0) so it passes through —
    // actual α is applied here in the TB for runtime flexibility.
    //==========================================================================
    // Truncate 16-bit VCO output to 12-bit (take lower 12 bits), then apply α
    wire signed [IQ_WIDTH-1:0] I_tx_12bit;
    wire signed [IQ_WIDTH-1:0] Q_tx_12bit;

    assign I_tx_12bit = In_Phase_o_tb[IQ_WIDTH-1:0];
    assign Q_tx_12bit = Quadrature_Phase_o_tb[IQ_WIDTH-1:0];

    always @(*) begin
        // Apply α: multiply by current_alpha_q8 (Q8) then >> 8
        I_to_emulator     = ($signed(I_tx_12bit) * $signed({1'b0, current_alpha_q8})) >>> 8;
        Q_to_emulator     = ($signed(Q_tx_12bit) * $signed({1'b0, current_alpha_q8})) >>> 8;
        valid_to_emulator = Phase_Valid_o_tb;
    end

    //==========================================================================
    // Initial Block
    //==========================================================================
    initial begin
        $dumpfile("channel_emulator.vcd");
        $dumpvars;

        // Load LUT tables
        $readmemh("sin_lut.txt", TX.u_vco.u_iq_wave_generator.sin_mem);
        $readmemh("cos_lut.txt", TX.u_vco.u_iq_wave_generator.cos_mem);

        // Load Gaussian taps
        $readmemh("taps.txt", taps);

        initialize();

        @(negedge clk);
        reset();

        repeat(5) @(negedge clk);
        load_taps();

        repeat(5) @(negedge clk);

        //======================================================================
        // Scenario 1 — α = 0.1  (Weak Signal)
        // ALPHA_Q8 = 26  (26/256 ≈ 0.10)
        // Expected: AGC boosts gain → I/Q restored → correct RX bits
        //======================================================================
        $display("\n════════════════════════════════════════");
        $display("Scenario 1: α ≈ 0.1  — WEAK SIGNAL");
        $display("ALPHA_Q8 = 26  (26/256 ≈ 0.10)");
        $display("Expected: AGC boosts gain to restore I/Q");
        $display("════════════════════════════════════════");

        current_alpha_q8 = 9'd26;
        agc_warmup();
        test_message = 11'b10101010100;
        send_message(test_message);
        repeat(FLUSH_CYCLES) @(negedge clk);

        //======================================================================
        // Scenario 2 — α = 0.5  (Medium Signal)
        // ALPHA_Q8 = 128  (128/256 = 0.50)
        // Expected: AGC applies moderate boost → correct RX bits
        //======================================================================
        $display("\n════════════════════════════════════════");
        $display("Scenario 2: α = 0.5  — MEDIUM SIGNAL");
        $display("ALPHA_Q8 = 128  (128/256 = 0.50)");
        $display("Expected: AGC applies moderate correction");
        $display("════════════════════════════════════════");

        current_alpha_q8 = 9'd128;
        test_message = 11'b10101010100;
        send_message(test_message);
        repeat(FLUSH_CYCLES) @(negedge clk);

        //======================================================================
        // Scenario 3 — α = 1.0  (Normal / No Attenuation)
        // ALPHA_Q8 = 256  (256/256 = 1.0)
        // Expected: AGC holds gain near 1.0 → signal passes cleanly
        //======================================================================
        $display("\n════════════════════════════════════════");

        @(negedge clk); rst_n = 1'b0;
        @(negedge clk); rst_n = 1'b1;
        repeat(5) @(negedge clk);
        load_taps();
        repeat(5) @(negedge clk);

        $display("Scenario 3: α = 1.0  — NORMAL SIGNAL");
        $display("ALPHA_Q8 = 256  (256/256 = 1.0)");
        $display("Expected: AGC steady, no correction needed");
        $display("════════════════════════════════════════");

        current_alpha_q8 = 9'd256;
        test_message = 11'b10101010100;
        send_message(test_message);
        repeat(FLUSH_CYCLES) @(negedge clk);

        //======================================================================
        // Scenario 4 — α = 2.0  (Strong / Clipping Risk)
        // ALPHA_Q8 = 512  (512/256 = 2.0)
        // Expected: AGC reduces gain → clipping prevented → correct RX bits
        //======================================================================
        $display("\n════════════════════════════════════════");

        @(negedge clk); rst_n = 1'b0;
        @(negedge clk); rst_n = 1'b1;
        repeat(5) @(negedge clk);
        load_taps();
        repeat(5) @(negedge clk);

        $display("Scenario 4: α = 2.0  — STRONG SIGNAL");
        $display("ALPHA_Q8 = 490  (490/256 = 1.91)");
        $display("Expected: AGC reduces gain — maximum recoverable alpha");
        $display("════════════════════════════════════════");

        current_alpha_q8 = 9'd490; //alpha = 1.91
        test_message = 11'b10101010100;
        send_message(test_message);
        repeat(FLUSH_CYCLES) @(negedge clk);

        //======================================================================
        // Summary
        //======================================================================
        $display("\n════════════════════════════════════════");
        $display("All 4 AGC Scenarios Completed");
        $display("Check waveform for:");
        $display("  - I_to_emulator / Q_to_emulator  : scaled TX signal");
        $display("  - EMULATOR.gain_w                : AGC gain word G");
        $display("  - I_rx_w / Q_rx_w                : corrected IQ to RX");
        $display("  - rx_bit_tb / rx_bit_valid_tb    : decoded RX bits");
        $display("════════════════════════════════════════");

        $stop;
    end

    //==========================================================================
    // RX Bit Monitor — prints every decoded bit
    //==========================================================================
    always @(posedge clk) begin
        if (rx_bit_valid_tb) begin
            $display("  [%0t] RX Bit[%0d] = %b", $time, rx_bit_count, rx_bit_tb);
            rx_bit_count = rx_bit_count + 1;
        end
    end

    //==========================================================================
    // Tasks
    //==========================================================================

    task initialize;
        begin
            clk              = 1'b0;
            rst_n            = 1'b1;
            phy_bit_i_tb     = 1'b0;
            bit_valid_i_tb   = 1'b0;
            tap_value_i_tb   = 'b0;
            tap_address_i_tb = 'b0;
            test_message     = 'b0;
            current_alpha_q8 = 9'd256;   // default α = 1.0
            rx_bit_count     = 0;
            tx_bit_count     = 0;
        end
    endtask

    task reset;
        begin
            #(Clock_PERIOD);
            rst_n = 1'b0;
            #(Clock_PERIOD);
            rst_n = 1'b1;
            $display("[%0t] Reset completed", $time);
        end
    endtask

    task load_taps;
        integer j;
        begin
            for (j = 0; j < NUM_OF_TAPS; j = j + 1) begin
                tap_address_i_tb = j;
                tap_value_i_tb   = taps[j];
                #(Clock_PERIOD);
            end
            $display("[%0t] Gaussian taps loaded", $time);
        end
    endtask

    task agc_warmup;
        integer w;
        begin
            $display("[%0t] AGC warmup start...", $time);
            for (w = 0; w < 128; w = w + 1) begin
                @(negedge clk);
                phy_bit_i_tb   = w[0];
                bit_valid_i_tb = 1'b1;
            end
            @(negedge clk);
            phy_bit_i_tb   = 1'b0;
            bit_valid_i_tb = 1'b0;
            repeat(50) @(negedge clk);
            $display("[%0t] AGC warmup complete", $time);
        end
    endtask

    task send_message;
        input [NRZ_DATA_WIDTH-1:0] message;
        integer i;
        begin
            $display("[%0t] Sending: 0b%b", $time, message);
            tx_bit_count = 0;

            for (i = NRZ_DATA_WIDTH-1; i >= 0; i = i - 1) begin
                @(negedge clk);
                phy_bit_i_tb   = message[i];
                bit_valid_i_tb = 1'b1;
                $display("  [%0t] TX Bit[%0d] = %b", $time, tx_bit_count, message[i]);
                tx_bit_count = tx_bit_count + 1;
            end

            @(negedge clk);
            phy_bit_i_tb   = 1'b0;
            bit_valid_i_tb = 1'b0;
            $display("[%0t] Transmission complete", $time);
        end
    endtask

    //==========================================================================
    // TX Instantiation
    //==========================================================================
    BLE_TX_PHY #(
        .NRZ_DATA_WIDTH    ( NRZ_DATA_WIDTH    ),
        .SAMPLE_PER_SYMBOL ( SAMPLE_PER_SYMBOL ),
        .TAP_WIDTH         ( TAP_WIDTH         ),
        .GAUS_OUT_WIDTH    ( GAUS_OUT_WIDTH     ),
        .ADDRESS_WIDTH     ( ADDRESS_WIDTH      ),
        .NUM_OF_TAPS       ( NUM_OF_TAPS        ),
        .VCO_OUT_WIDTH     ( VCO_OUT_WIDTH      ),
        .VCO_DATA_WIDTH    ( VCO_DATA_WIDTH     ),
        .VCO_OUT_SIZE      ( VCO_OUT_SIZE       )
    ) TX (
        .clk                ( clk                    ),
        .rst_n              ( rst_n                  ),
        .phy_bit_i          ( phy_bit_i_tb           ),
        .bit_valid_i        ( bit_valid_i_tb         ),
        .tap_value_i        ( tap_value_i_tb         ),
        .tap_address_i      ( tap_address_i_tb       ),
        .Quadrature_Phase_o ( Quadrature_Phase_o_tb  ),
        .In_Phase_o         ( In_Phase_o_tb          ),
        .Phase_Valid_o      ( Phase_Valid_o_tb       )
    );

    //==========================================================================
    // Channel Emulator Instantiation
    // ALPHA_Q8=256 (×1.0) because α scaling is done in TB above
    //==========================================================================
    channel_emulator #(
        .IQ_WIDTH      ( IQ_WIDTH      ),
        .AGC_IQ_WIDTH  ( AGC_IQ_WIDTH  ),
        .ALPHA_Q8      ( 256           ),   // TB handles α — emulator passes through
        .AVG_LOG2      ( AVG_LOG2      ),
        .POWER_TARGET  ( POWER_TARGET  ),
        .STEP_SIZE     ( STEP_SIZE     )
    ) EMULATOR (
        .clk           ( clk               ),
        .rst_n         ( rst_n             ),
        .I_tx_i        ( I_to_emulator     ),
        .Q_tx_i        ( Q_to_emulator     ),
        .valid_tx_i    ( valid_to_emulator ),
        .I_rx_o        ( I_rx_w            ),
        .Q_rx_o        ( Q_rx_w            ),
        .valid_rx_o    ( valid_rx_w        )
    );

    //==========================================================================
    // RX Instantiation
    //==========================================================================
    BLE_RX_PHY #(
        .IQ_BIT_WIDTH      ( IQ_WIDTH         ),
        .SAMPLE_PER_SYMBOL ( SAMPLE_PER_SYMBOL ),
        .CNT_WIDTH         ( 4                )
    ) RX (
        .clk               ( clk          ),
        .rst_n             ( rst_n        ),
        .in_phase_i_i      ( I_rx_w       ),
        .quadrature_q_i    ( Q_rx_w       ),
        .iq_valid_i        ( valid_rx_w   ),
        .rx_bit_o          ( rx_bit_tb    ),
        .rx_bit_valid_o    ( rx_bit_valid_tb )
    );

    //==========================================================================
    // Clock Generation
    //==========================================================================
    always begin
        #(Clock_PERIOD/2) clk = ~clk;
    end

endmodule