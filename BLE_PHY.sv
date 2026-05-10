module BLE_PHY #(
    parameter NRZ_DATA_WIDTH       = 11,
    parameter SAMPLE_PER_SYMBOL    = 8,

    // Gaussian Filter parameters
    parameter TAP_WIDTH            = 16,
    parameter GAUS_OUT_WIDTH       = 16,
    parameter ADDRESS_WIDTH        = 4,
    parameter NUM_OF_TAPS          = 9,

    // VCO parameters
    parameter VCO_OUT_WIDTH        = 16,
    parameter VCO_DATA_WIDTH       = 12,
    parameter VCO_OUT_SIZE         = 12,

    // AGC parameters
    parameter AGC_IQ_WIDTH         = 16,
    parameter AGC_AVG_LOG2         = 4,
    parameter AGC_POWER_TARGET     = 33'd4294967296,
    parameter AGC_STEP_SIZE        = 3,

    // RSSI parameters
    parameter RSSI_N               = 16,
    parameter RSSI_DATA_WIDTH      = 32,
    parameter RSSI_N_LOG2          = 4,
    parameter RSSI_WIDTH           = 32,
    parameter RSSI_NO_BITS         = 5,
    parameter RSSI_FRAC_BITS       = 8,
    parameter RSSI_THRESHOLD       = 16'd1843
) (
    input  wire                            clk,
    input  wire                            rst_n,

    //==========================================================================
    // TX Signals
    //==========================================================================
    input  wire                            phy_bit_i,
    input  wire                            bit_valid_i,

    input  wire [TAP_WIDTH-1:0]            tap_value_i,
    input  wire [ADDRESS_WIDTH-1:0]        tap_address_i,

    output wire [VCO_OUT_SIZE-1:0]         Quadrature_Phase_AGC_o,
    output wire [VCO_OUT_SIZE-1:0]         In_Phase_AGC_o,
    
    //==========================================================================
    // RX Signals
    //==========================================================================
    input wire [VCO_OUT_SIZE-1:0]         Quadrature_Phase_RX_i,
    input wire [VCO_OUT_SIZE-1:0]         In_Phase_RX_i,
    input wire                            RX_Valid_i,

    output wire                           rx_bit_o,
    output wire                           rx_bit_valid_o,


    //==========================================================================
    // RSSI Signals
    //==========================================================================
    output wire                           signal_flag_o
);

    //==========================================================================
    // Internal wires — TX outputs — AGC inputs
    //==========================================================================
    wire [VCO_OUT_SIZE-1:0]         Quadrature_Phase_w;
    wire [VCO_OUT_SIZE-1:0]         In_Phase_w;
    wire                            Phase_Valid_w;

    //==========================================================================
    // Internal wires — AGC 
    //==========================================================================
    wire                            agc_valid_w;


    //==========================================================================
    // Internal wires — RSSI Outputs
    //==========================================================================
    wire [RSSI_N-1:0]               rssi_out_o;
    wire                            rssi_valid_o;


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
    // AGC Instantiation
    //==========================================================================
    agc_top #(
        .IQ_WIDTH       (VCO_OUT_SIZE),
        .AGC_IQ_WIDTH   (AGC_IQ_WIDTH),
        .AVG_LOG2       (AGC_AVG_LOG2),
        .POWER_TARGET   (AGC_POWER_TARGET),
        .STEP_SIZE      (AGC_STEP_SIZE)
    ) u_AGC (
        .clk            (clk),
        .rst_n          (rst_n),
        .valid_in_i     (Phase_Valid_w),
        .I_in_i         (In_Phase_w),
        .Q_in_i         (Quadrature_Phase_w),
        .I_out_o        (In_Phase_AGC_o),
        .Q_out_o        (Quadrature_Phase_AGC_o),
        .valid_out_o    (agc_valid_w)
    );

    //==========================================================================
    // RSSI Instantiation
    //==========================================================================
    RSSI_TOP #(
        .N              (RSSI_N),
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