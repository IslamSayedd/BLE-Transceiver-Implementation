interface BLE_PHY_if(input bit clk);

    ////////////////////////////////////////////////////
    /////////////////////Parameters/////////////////////
    ////////////////////////////////////////////////////

    parameter NRZ_DATA_WIDTH       = 11;
    parameter SAMPLE_PER_SYMBOL    = 8;

    // Gaussian Filter parameters
    parameter TAP_WIDTH            = 16;
    parameter GAUS_OUT_WIDTH       = 16;
    parameter ADDRESS_WIDTH        = 4;
    parameter NUM_OF_TAPS          = 9;

    // VCO parameters
    parameter VCO_OUT_WIDTH        = 16;
    parameter VCO_DATA_WIDTH       = 12;
    parameter VCO_OUT_SIZE         = 12;

    // AGC parameters
    parameter AGC_IQ_WIDTH         = 16;
    parameter AGC_AVG_LOG2         = 4;
    parameter AGC_POWER_TARGET     = 33'd4294967296;
    parameter AGC_STEP_SIZE        = 3;

    // RSSI parameters
    parameter RSSI_N               = 16;
    parameter RSSI_DATA_WIDTH      = 32;
    parameter RSSI_N_LOG2          = 4;
    parameter RSSI_WIDTH           = 32;
    parameter RSSI_NO_BITS         = 5;
    parameter RSSI_FRAC_BITS       = 8;
    parameter RSSI_THRESHOLD       = 16'd1843;

    ///////////////////////////////////////////////
    /////////////////////Ports/////////////////////
    ///////////////////////////////////////////////

    // TX Signals
    logic                            rst_n;
    logic                            phy_bit_i;
    logic                            bit_valid_i;
    logic [TAP_WIDTH-1:0]            tap_value_i;
    logic [ADDRESS_WIDTH-1:0]        tap_address_i;

    // AGC Outputs (TX path)
    logic [VCO_OUT_SIZE-1:0]         Quadrature_Phase_AGC_o;
    logic [VCO_OUT_SIZE-1:0]         In_Phase_AGC_o;

    // RX Signals — Inputs
    logic [VCO_OUT_SIZE-1:0]         Quadrature_Phase_RX_i;
    logic [VCO_OUT_SIZE-1:0]         In_Phase_RX_i;
    logic                            RX_Valid_i;

    // RX Signals — Outputs
    logic                            rx_bit_o;
    logic                            rx_bit_valid_o;

    // RSSI Output
    logic                            signal_flag_o;

    // Internal VCO outputs — for scoreboard cycle-accurate AGC model
    logic [11:0]                     In_Phase_12_w;
    logic [11:0]                     Quadrature_Phase_12_w;
    logic                            Phase_Valid_w;

    // AGC internal gain — for scoreboard cycle-accurate AGC model
    logic [33:0]                     agc_gain_w;
    logic                            agc_valid_w;

    // AGC direct outputs — stable registered values
    logic [11:0]                     agc_I_out_w;
    logic [11:0]                     agc_Q_out_w;

    // NRZ internal signals — for error analysis
    logic                            nrz_valid_w;
    logic                            upsample_valid_w;

    // RX demodulator outputs — for scoreboard cycle-accurate RX checking
    logic                            demod_signal_w;
    logic                            demod_valid_w;

    ///////////////////////////////////////////////////////
    ///////////////Defining Modports///////////////////////
    ///////////////////////////////////////////////////////
    modport DUT (
        input  clk, rst_n, phy_bit_i, bit_valid_i, tap_value_i, tap_address_i,
               Quadrature_Phase_RX_i, In_Phase_RX_i, RX_Valid_i,
        output Quadrature_Phase_AGC_o, In_Phase_AGC_o,
               rx_bit_o, rx_bit_valid_o,
               signal_flag_o,
               In_Phase_12_w, Quadrature_Phase_12_w, Phase_Valid_w,
               agc_gain_w, agc_valid_w,
               agc_I_out_w, agc_Q_out_w,
               nrz_valid_w, upsample_valid_w,
               demod_signal_w, demod_valid_w
    );


endinterface