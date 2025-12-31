module BLE_TX_PHY #(
    // NRZ Upsample parameters
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
    parameter VCO_OUT_SIZE         = 12
)(
    // Global signals
    input  wire                             clk,
    input  wire                             rst_n,
    
    // PHY Layer input
    input  wire                             phy_bit_i,
    input  wire                             bit_valid_i,
    
    // Gaussian Filter configuration interface
    input  wire [TAP_WIDTH - 1 : 0]         tap_value_i,
    input  wire [ADDRESS_WIDTH - 1 : 0]     tap_address_i,
    
    // VCO outputs (I/Q modulated signals)
    output wire [VCO_OUT_SIZE - 1 : 0]      Quadrature_Phase_o,  // Q (sin)
    output wire [VCO_OUT_SIZE - 1 : 0]      In_Phase_o,          // I (cos)
    output wire                             Phase_Valid_o
);

    //==========================================================================
    // Internal Signals
    //==========================================================================
    
    // NRZ Upsample to Gaussian Filter
    wire                                    bit_upsample;
    wire                                    bit_upsample_valid;
    
    // Gaussian Filter to VCO
    wire signed [GAUS_OUT_WIDTH - 1 : 0]    gaussian_filter_out;
    wire                                    gaussian_filter_valid;

    //==========================================================================
    // Module Instantiations
    //==========================================================================
    
    // Stage 1: NRZ Upsampler
    // Converts input PHY bits to upsampled NRZ signal
    NRZ_upsample #(
        .DATA_WIDTH         (NRZ_DATA_WIDTH),
        .SAMPLE_PER_SYMBOL  (SAMPLE_PER_SYMBOL)
    ) u_nrz_upsample (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .phy_bit_i              (phy_bit_i),
        .bit_valid_i            (bit_valid_i),
        .bit_upsample_o         (bit_upsample),
        .bit_upsample_valid_o   (bit_upsample_valid)
    );
    
    // Stage 2: Gaussian Filter
    // Applies Gaussian pulse shaping to upsampled signal
    gaussian_filter #(
        .TAP_WIDTH      (TAP_WIDTH),
        .OUT_WIDTH      (GAUS_OUT_WIDTH),
        .ADDRESS_WIDTH  (ADDRESS_WIDTH),
        .NUM_OF_TAPS    (NUM_OF_TAPS)
    ) u_gaussian_filter (
        .clk                            (clk),
        .rst_n                          (rst_n),
        .bit_upsample_valid_i           (bit_upsample_valid),
        .bit_upsample_i                 (bit_upsample),
        .tap_value_i                    (tap_value_i),
        .tap_address_i                  (tap_address_i),
        .gaussian_filter_o              (gaussian_filter_out),
        .gaussian_filter_out_valid_o    (gaussian_filter_valid)
    );
    
    // Stage 3: VCO (Voltage Controlled Oscillator)
    // Generates I/Q modulated output signals
    VCO #(
        .OUT_WIDTH      (VCO_OUT_WIDTH),
        .DATA_WIDTH     (VCO_DATA_WIDTH),
        .OUT_SIZE       (VCO_OUT_SIZE)
    ) u_vco (
        .clk                            (clk),
        .reset_n                        (rst_n),
        .gauss_filter_o                 (gaussian_filter_out),
        .gaussian_filter_out_valid_o    (gaussian_filter_valid),
        .Quadrature_Phase_o             (Quadrature_Phase_o),
        .In_Phase_o                     (In_Phase_o),
        .Phase_Valid_o                  (Phase_Valid_o)
    );

endmodule