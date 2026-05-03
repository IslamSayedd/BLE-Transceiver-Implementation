interface BLE_PHY_if(clk);

    input bit clk;

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
    logic                            clk;
    logic                            rst_n;
    logic                            phy_bit_i;
    logic                            bit_valid_i;
    logic [TAP_WIDTH-1:0]            tap_value_i;
    logic [ADDRESS_WIDTH-1:0]        tap_address_i;

    
    // RX Signals
    logic                            rx_bit_o;
    logic                            rx_bit_valid_o;


    // RSSI Outputs
    logic [RSSI_N-1:0]               rssi_out_o;
    logic                            rssi_valid_o;
    logic                            signal_flag_o;

    

    ///////////////////////////////////////////////////////
    ///////////////Defining Modports///////////////////////
    ///////////////////////////////////////////////////////
    modport DUT ( input clk , rst_n , phy_bit_i , bit_valid_i , tap_value_i , tap_address_i , 
    output rx_bit_o , rx_bit_valid_o , rssi_out_o , rssi_valid_o , signal_flag_o );

    modport sva ( input clk , rst_n , phy_bit_i , bit_valid_i , tap_value_i , tap_address_i , 
    rx_bit_o , rx_bit_valid_o , rssi_out_o , rssi_valid_o , signal_flag_o );
    
endinterface