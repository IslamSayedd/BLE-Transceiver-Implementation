module BLE_PHY_verif (BLE_PHY_if.DUT PHY_if);

    //==========================================================================
    // Parameters from Interface
    //==========================================================================
    parameter NRZ_DATA_WIDTH    = PHY_if.NRZ_DATA_WIDTH;
    parameter SAMPLE_PER_SYMBOL = PHY_if.SAMPLE_PER_SYMBOL;

    // Gaussian Filter
    parameter TAP_WIDTH         = PHY_if.TAP_WIDTH;
    parameter GAUS_OUT_WIDTH    = PHY_if.GAUS_OUT_WIDTH;
    parameter ADDRESS_WIDTH     = PHY_if.ADDRESS_WIDTH;
    parameter NUM_OF_TAPS       = PHY_if.NUM_OF_TAPS;

    // VCO — must be 16-bit to match LUT files
    parameter VCO_OUT_WIDTH     = 16;
    parameter VCO_DATA_WIDTH    = 16;
    parameter VCO_OUT_SIZE      = 16;

    // IQ width after truncation to 12-bit
    localparam IQ_WIDTH         = PHY_if.VCO_OUT_SIZE;  // 12

    // AGC
    parameter AGC_IQ_WIDTH      = PHY_if.AGC_IQ_WIDTH;
    parameter AGC_AVG_LOG2      = PHY_if.AGC_AVG_LOG2;
    parameter AGC_POWER_TARGET  = PHY_if.AGC_POWER_TARGET;
    parameter AGC_STEP_SIZE     = PHY_if.AGC_STEP_SIZE;

    // RSSI
    parameter RSSI_N            = PHY_if.RSSI_N;
    parameter RSSI_DATA_WIDTH   = PHY_if.RSSI_DATA_WIDTH;
    parameter RSSI_N_LOG2       = PHY_if.RSSI_N_LOG2;
    parameter RSSI_WIDTH        = PHY_if.RSSI_WIDTH;
    parameter RSSI_NO_BITS      = PHY_if.RSSI_NO_BITS;
    parameter RSSI_FRAC_BITS    = PHY_if.RSSI_FRAC_BITS;
    parameter RSSI_THRESHOLD    = PHY_if.RSSI_THRESHOLD;

    //==========================================================================
    // Logic Signals — Inputs
    //==========================================================================
    logic                            clk;
    logic                            rst_n;
    logic                            phy_bit_i;
    logic                            bit_valid_i;
    logic [TAP_WIDTH-1:0]            tap_value_i;
    logic [ADDRESS_WIDTH-1:0]        tap_address_i;

    // RX Inputs
    logic [VCO_OUT_SIZE-1:0]         Quadrature_Phase_RX_i;
    logic [VCO_OUT_SIZE-1:0]         In_Phase_RX_i;
    logic                            RX_Valid_i;

    //==========================================================================
    // Logic Signals — Outputs
    //==========================================================================
    logic [IQ_WIDTH-1:0]             Quadrature_Phase_AGC_o;
    logic [IQ_WIDTH-1:0]             In_Phase_AGC_o;
    logic                            rx_bit_o;
    logic                            rx_bit_valid_o;
    logic                            signal_flag_o;

    //==========================================================================
    // Interface Assignments — Inputs
    //==========================================================================
    assign clk                  = PHY_if.clk;
    assign rst_n                = PHY_if.rst_n;
    assign phy_bit_i            = PHY_if.phy_bit_i;
    assign bit_valid_i          = PHY_if.bit_valid_i;
    assign tap_value_i          = PHY_if.tap_value_i;
    assign tap_address_i        = PHY_if.tap_address_i;
    assign In_Phase_RX_i        = PHY_if.In_Phase_RX_i;
    assign Quadrature_Phase_RX_i = PHY_if.Quadrature_Phase_RX_i;
    assign RX_Valid_i           = PHY_if.RX_Valid_i;

    //==========================================================================
    // Interface Assignments — Outputs
    //==========================================================================
    assign PHY_if.In_Phase_AGC_o        = In_Phase_AGC_o;
    assign PHY_if.Quadrature_Phase_AGC_o = Quadrature_Phase_AGC_o;
    assign PHY_if.rx_bit_o              = rx_bit_o;
    assign PHY_if.rx_bit_valid_o        = rx_bit_valid_o;
    assign PHY_if.signal_flag_o         = signal_flag_o;

    //==========================================================================
    // Internal wires — TX outputs (16-bit VCO output)
    //==========================================================================
    logic [VCO_OUT_SIZE-1:0]         Quadrature_Phase_w;
    logic [VCO_OUT_SIZE-1:0]         In_Phase_w;
    logic                            Phase_Valid_w;

    //==========================================================================
    // Internal wires — Truncated 12-bit IQ (VCO 16-bit → 12-bit)
    //==========================================================================
    logic signed [IQ_WIDTH-1:0]      Quadrature_Phase_12_w;
    logic signed [IQ_WIDTH-1:0]      In_Phase_12_w;

    assign In_Phase_12_w         = In_Phase_w[IQ_WIDTH-1:0];
    assign Quadrature_Phase_12_w = Quadrature_Phase_w[IQ_WIDTH-1:0];

    //==========================================================================
    // Internal wires — AGC
    //==========================================================================
    logic                            agc_valid_w;

    //==========================================================================
    // Internal wires — RSSI Outputs
    //==========================================================================
    logic [RSSI_N-1:0]               rssi_out_o;
    logic                            rssi_valid_o;

    //==========================================================================
    // TX Instantiation
    //==========================================================================
    BLE_TX_PHY #(
        .NRZ_DATA_WIDTH     (NRZ_DATA_WIDTH),
        .SAMPLE_PER_SYMBOL  (SAMPLE_PER_SYMBOL),
        .TAP_WIDTH          (TAP_WIDTH),
        .GAUS_OUT_WIDTH     (GAUS_OUT_WIDTH),
        .ADDRESS_WIDTH      (ADDRESS_WIDTH),
        .NUM_OF_TAPS        (NUM_OF_TAPS),
        .VCO_OUT_WIDTH      (VCO_OUT_WIDTH),
        .VCO_DATA_WIDTH     (VCO_DATA_WIDTH),
        .VCO_OUT_SIZE       (VCO_OUT_SIZE)
    ) u_TX (
        .clk                (clk),
        .rst_n              (rst_n),
        .phy_bit_i          (phy_bit_i),
        .bit_valid_i        (bit_valid_i),
        .tap_value_i        (tap_value_i),
        .tap_address_i      (tap_address_i),
        .Quadrature_Phase_o (Quadrature_Phase_w),
        .In_Phase_o         (In_Phase_w),
        .Phase_Valid_o      (Phase_Valid_w)
    );

    //==========================================================================
    // AGC Instantiation — takes truncated 12-bit IQ
    //==========================================================================
    agc_top #(
        .IQ_WIDTH       (IQ_WIDTH),
        .AGC_IQ_WIDTH   (AGC_IQ_WIDTH),
        .AVG_LOG2       (AGC_AVG_LOG2),
        .POWER_TARGET   (AGC_POWER_TARGET),
        .STEP_SIZE      (AGC_STEP_SIZE)
    ) u_AGC (
        .clk            (clk),
        .rst_n          (rst_n),
        .valid_in_i     (Phase_Valid_w),
        .I_in_i         (In_Phase_12_w),
        .Q_in_i         (Quadrature_Phase_12_w),
        .I_out_o        (In_Phase_AGC_o),
        .Q_out_o        (Quadrature_Phase_AGC_o),
        .valid_out_o    (agc_valid_w)
    );

    //==========================================================================
    // RSSI Instantiation
    //==========================================================================
    RSSI_TOP #(
        .N              (VCO_OUT_SIZE),
        .DATA_WIDTH     (RSSI_DATA_WIDTH),
        .N_LOG2         (RSSI_N_LOG2),
        .WIDTH          (RSSI_WIDTH),
        .NO_BITS        (RSSI_NO_BITS),
        .FRAC_BITS      (RSSI_FRAC_BITS),
        .RSSI_THRESHOLD (RSSI_THRESHOLD)
    ) u_RSSI (
        .clk            (clk),
        .rst_n          (rst_n),
        .valid_i        (RX_Valid_i),
        .I_in           (In_Phase_RX_i),
        .Q_in           (Quadrature_Phase_RX_i),
        .rssi_out_o     (rssi_out_o),
        .rssi_valid_o   (rssi_valid_o),
        .signal_flag_o  (signal_flag_o)
    );

    //==========================================================================
    // RX Instantiation
    //==========================================================================
    BLE_RX_PHY #(
        .IQ_BIT_WIDTH       (VCO_OUT_SIZE),
        .SAMPLE_PER_SYMBOL  (SAMPLE_PER_SYMBOL),
        .CNT_WIDTH          (4)
    ) u_RX (
        .clk                (clk),
        .rst_n              (rst_n),
        .in_phase_i_i       (In_Phase_RX_i),
        .quadrature_q_i     (Quadrature_Phase_RX_i),
        .iq_valid_i         (RX_Valid_i),
        .rx_bit_o           (rx_bit_o),
        .rx_bit_valid_o     (rx_bit_valid_o)
    );

endmodule