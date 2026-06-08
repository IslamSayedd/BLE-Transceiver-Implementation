package PHY_sb_pkg;
import PHY_seq_item_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"

class PHY_sb extends uvm_scoreboard;
    `uvm_component_utils (PHY_sb);
    uvm_analysis_export #(PHY_seq_item) sb_export;
    uvm_tlm_analysis_fifo #(PHY_seq_item) sb_fifo;
    PHY_seq_item seq_item_sb;
    
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

    // AGC derived parameters
    localparam IQ_WIDTH    = VCO_OUT_SIZE;
    localparam POWER_WIDTH = 2 * AGC_IQ_WIDTH;
    localparam GAIN_WIDTH  = POWER_WIDTH + 1;

    // RSSI parameters
    parameter RSSI_N               = 16;
    parameter RSSI_DATA_WIDTH      = 16;
    parameter RSSI_N_LOG2          = 4;
    parameter RSSI_WIDTH           = 32;
    parameter RSSI_NO_BITS         = 5;
    parameter RSSI_FRAC_BITS       = 8;
    parameter RSSI_THRESHOLD       = 16'd1843;


    logic [VCO_OUT_SIZE-1:0]        Quadrature_Phase_AGC_o_ref;
    logic [VCO_OUT_SIZE-1:0]        In_Phase_AGC_o_ref;
    logic                           rx_bit_o_ref;
    logic                           rx_bit_valid_o_ref;
    logic                           signal_flag_o_ref;

    int correct_count = 0;
    int error_count = 0 ;
    int i;


    logic                           bit_upsample;
    logic                           bit_upsample_valid;

    logic [SAMPLE_PER_SYMBOL-1:0] bit_upsample_reg [NRZ_DATA_WIDTH-1:0];
    int counter_out;
    int loop_out;
    int counter_in;


    logic signed [TAP_WIDTH-1:0]        gauss_filter_tap0;
    logic signed [TAP_WIDTH-1:0]        gauss_filter_tap1;
    logic signed [TAP_WIDTH-1:0]        gauss_filter_tap2;
    logic signed [TAP_WIDTH-1:0]        gauss_filter_tap3;
    logic signed [TAP_WIDTH-1:0]        gauss_filter_tap4;
    logic signed [TAP_WIDTH-1:0]        gauss_filter_tap5;
    logic signed [TAP_WIDTH-1:0]        gauss_filter_tap6;
    logic signed [TAP_WIDTH-1:0]        gauss_filter_tap7;
    logic signed [TAP_WIDTH-1:0]        gauss_filter_tap8;

    logic signed [TAP_WIDTH-1:0]           tap0_addr0;
    logic signed [TAP_WIDTH-1:0]           tap1_addr1;
    logic signed [TAP_WIDTH-1:0]           tap2_addr2;
    logic signed [TAP_WIDTH-1:0]           tap3_addr3;
    logic signed [TAP_WIDTH-1:0]           tap4_addr4;
    logic signed [TAP_WIDTH-1:0]           tap5_addr5;
    logic signed [TAP_WIDTH-1:0]           tap6_addr6;
    logic signed [TAP_WIDTH-1:0]           tap7_addr7;
    logic signed [TAP_WIDTH-1:0]           tap8_addr8;
    logic signed [TAP_WIDTH-1:0]           tap7_addr9;
    logic signed [TAP_WIDTH-1:0]           tap6_addr10;
    logic signed [TAP_WIDTH-1:0]           tap5_addr11;
    logic signed [TAP_WIDTH-1:0]           tap4_addr12;
    logic signed [TAP_WIDTH-1:0]           tap3_addr13;
    logic signed [TAP_WIDTH-1:0]           tap2_addr14;
    logic signed [TAP_WIDTH-1:0]           tap1_addr15;
    logic signed [TAP_WIDTH-1:0]           tap0_addr16;

    logic [15:0]                    bit_upsample_store;

    logic                           gaussian_filter_valid;
    logic [GAUS_OUT_WIDTH-1:0]      gaussian_filter_out;


    logic signed [AGC_IQ_WIDTH-1:0]   in_phase_i_0;
    logic signed [AGC_IQ_WIDTH-1:0]   in_phase_i_1;
    logic signed [AGC_IQ_WIDTH-1:0]   quadrature_q_0;
    logic signed [AGC_IQ_WIDTH-1:0]   quadrature_q_1;
    logic signed [2*AGC_IQ_WIDTH:0]   decision;
    logic [2:0]                       valid_pipe;
    logic                             demod_signal;
    logic                             demod_signal_valid;

    logic [3:0] downsample_cnt;
    
    // RX Pipeline delay queues
    logic signed [AGC_IQ_WIDTH-1:0] in_phase_pipe  [0:2];
    logic signed [AGC_IQ_WIDTH-1:0] quad_phase_pipe [0:2];
    logic                            valid_pipe_d    [0:2];
    logic signed [2*AGC_IQ_WIDTH:0]  decision_pipe;
    logic                            demod_pipe      [0:1];

    // AGC variables
    logic signed [AGC_IQ_WIDTH-1:0]  I_ext, Q_ext;
    logic [2*AGC_IQ_WIDTH-1:0]       agc_raw_power;
    logic [2*AGC_IQ_WIDTH-1:0]       agc_avg_buffer [0:15];
    logic [2*AGC_IQ_WIDTH-1:0]       agc_sum;
    logic [3:0]                       agc_wr_ptr;
    logic [2*AGC_IQ_WIDTH:0]         agc_gain;
    logic signed [IQ_WIDTH+GAIN_WIDTH-1:0] I_product, Q_product;

    // RSSI variables
    logic [15:0]                      rssi_power_16;
    logic [15:0]                      rssi_avg_buffer [0:15];
    logic [15:0]                      rssi_sum;
    logic [3:0]                       rssi_wr_ptr;
    real                              rssi_real;
    logic [15:0]                      rssi_fixed;

    // Virtual interface
    virtual BLE_PHY_if BLE_PHY_vif;

    // VCO variables
    logic [15:0]                      sin_lut [0:255];
    logic [15:0]                      cos_lut [0:255];
    logic signed [15:0]               vco_accumulator;
    logic [7:0]                       vco_phase_index;
    logic signed [15:0]               vco_sin_out;
    logic signed [15:0]               vco_cos_out;
    logic signed [11:0]               vco_I_12;
    logic signed [11:0]               vco_Q_12;
    logic                             vco_valid;
    bit                               lut_loaded;

    // AGC cycle-accurate pipeline state
    // Stage 1: Power Estimator
    logic signed [AGC_IQ_WIDTH-1:0]   agc_I_ext_pipe;
    logic signed [AGC_IQ_WIDTH-1:0]   agc_Q_ext_pipe;
    logic [2*AGC_IQ_WIDTH-1:0]        agc_raw_power_pipe;
    logic                             agc_valid_pipe1;

    // Stage 2: Average Filter
    logic [2*AGC_IQ_WIDTH-1:0]        agc_avg_buf [0:15];
    logic [2*AGC_IQ_WIDTH-1:0]        agc_avg_sum;
    logic [3:0]                       agc_avg_ptr;
    logic [2*AGC_IQ_WIDTH-1:0]        agc_avg_out;
    logic                             agc_valid_pipe2;

    // Stage 3+4: Gain Control (2 cycles)
    logic [2*AGC_IQ_WIDTH:0]          agc_gain_ref;
    logic [2*AGC_IQ_WIDTH:0]          agc_gain_old_ref;
    logic [2*AGC_IQ_WIDTH:0]          agc_gain_temp_ref;
    logic                             agc_done_ref;
    logic                             agc_valid_pipe3;
    logic                             agc_valid_pipe4;

    // Stage 5: Output Register
    logic signed [IQ_WIDTH-1:0]       agc_I_out_ref;
    logic signed [IQ_WIDTH-1:0]       agc_Q_out_ref;
    logic signed [IQ_WIDTH-1:0]       agc_I_out_ref_d;
    logic signed [IQ_WIDTH-1:0]       agc_Q_out_ref_d;
    logic                             agc_valid_pipe5;

    // VCO input delayed by 1 cycle for AGC multiply
    logic signed [IQ_WIDTH-1:0]       vco_I_12_agc;
    logic signed [IQ_WIDTH-1:0]       vco_Q_12_agc;

    // Gain delayed by 1 cycle
    logic [2*AGC_IQ_WIDTH:0]          agc_gain_ref_d;

    // RX downsampler reference
    logic                            demod_at_sample;
    logic [3:0]                      rx_downsample_cnt;

    // Input pipeline to AGC (VCO output delayed to match AGC latency)
    logic signed [IQ_WIDTH-1:0]       agc_I_in_pipe [0:4];
    logic signed [IQ_WIDTH-1:0]       agc_Q_in_pipe [0:4];

    // VCO pipeline delay
    logic signed [15:0]               vco_accumulator_d1;
    logic [7:0]                       vco_phase_index_d1;
    logic signed [11:0]               vco_I_12_d1;
    logic signed [11:0]               vco_Q_12_d1;
    logic                             vco_valid_d1;
    logic signed [11:0]               vco_I_12_d2;
    logic signed [11:0]               vco_Q_12_d2;
    logic                             vco_valid_d2;

    function new(string name = "PHY_sb" , uvm_component parent = null);
        super.new(name , parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_export = new("sb_export" , this);
        sb_fifo = new("sb_fifo" , this);
        $readmemh("sin_lut.txt", sin_lut);
        $readmemh("cos_lut.txt", cos_lut);

        begin
            PHY_config_pkg::PHY_config cfg;
            if(!uvm_config_db #(PHY_config_pkg::PHY_config)::get(this, "", "vif", cfg))
                `uvm_fatal("build_phase", "Scoreboard - Unable to get config object");
            BLE_PHY_vif = cfg.BLE_PHY_vif;
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        sb_export.connect(sb_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
            // Thread 1: Transaction-based checking (signal_flag + rx_bit)
            forever begin
                sb_fifo.get(seq_item_sb);
                ref_model(seq_item_sb);

                // Check signal_flag_o
                if (seq_item_sb.rst_n && rssi_wr_ptr >= 16 && 
                    signal_flag_o_ref !== seq_item_sb.signal_flag_o) begin
                    error_count++;
                    `uvm_error("run_phase", $sformatf({"Error Detected at time = %0t,\n",
                                "signal_flag_o Received: %0b Expected: %0b"},
                                $time,
                                seq_item_sb.signal_flag_o, signal_flag_o_ref))
                end
                else begin
                    correct_count++;
                end
            end

            // Thread 2: Cycle-accurate AGC pipeline checking
            forever begin
                @(posedge BLE_PHY_vif.clk);
                #1ps;
                if (!BLE_PHY_vif.rst_n) begin
                    // Reset all AGC pipeline stages
                    agc_I_ext_pipe      = 'd0;
                    agc_Q_ext_pipe      = 'd0;
                    agc_raw_power_pipe  = 'd0;
                    agc_valid_pipe1     = 1'b0;
                    agc_avg_sum         = 'd0;
                    agc_avg_ptr         = 'd0;
                    agc_avg_out         = 'd0;
                    agc_valid_pipe2     = 1'b0;
                    agc_gain_ref        = 'd0;
                    agc_gain_old_ref    = 'd0;
                    agc_gain_temp_ref   = 'd0;
                    agc_done_ref        = 1'b0;
                    agc_valid_pipe3     = 1'b0;
                    agc_valid_pipe4     = 1'b0;
                    agc_I_out_ref       = 'd0;
                    agc_Q_out_ref       = 'd0;
                    agc_I_out_ref_d     = 'd0;
                    agc_Q_out_ref_d     = 'd0;
                    agc_valid_pipe5     = 1'b0;
                    vco_I_12_agc        = 'd0;
                    vco_Q_12_agc        = 'd0;
                    agc_gain_ref_d      = 'd0;
                    demod_at_sample    = 1'b0;
                    rx_downsample_cnt  = 'd0;
                    for(int k=0; k<16; k++) agc_avg_buf[k] = 'd0;
                    for(int k=0; k<5; k++) begin
                        agc_I_in_pipe[k] = 'd0;
                        agc_Q_in_pipe[k] = 'd0;
                    end
                    // Reset VCO accumulator
                    vco_accumulator     = 'd0;
                    vco_accumulator_d1  = 'd0;
                    vco_phase_index     = 'd0;
                    vco_phase_index_d1  = 'd0;
                    vco_I_12            = 'd0;
                    vco_I_12_d1         = 'd0;
                    vco_I_12_d2         = 'd0;
                    vco_Q_12            = 'd0;
                    vco_Q_12_d1         = 'd0;
                    vco_Q_12_d2         = 'd0;
                    vco_valid           = 1'b0;
                    vco_valid_d1        = 1'b0;
                    vco_valid_d2        = 1'b0;
                end
                else begin
                    // ─── Save previous cycle output FIRST ───────────
                    agc_I_out_ref_d  = agc_I_out_ref;
                    agc_Q_out_ref_d  = agc_Q_out_ref;

                    // ─── Read current cycle values ────────────────────
                    vco_I_12  = $signed(BLE_PHY_vif.In_Phase_12_w);
                    vco_Q_12  = $signed(BLE_PHY_vif.Quadrature_Phase_12_w);
                    vco_valid = BLE_PHY_vif.Phase_Valid_w;

                    // ─── AGC: Read output directly from DUT ──────────
                    agc_valid_pipe5 = BLE_PHY_vif.agc_valid_w;
                    agc_I_out_ref   = $signed(BLE_PHY_vif.agc_I_out_w);
                    agc_Q_out_ref   = $signed(BLE_PHY_vif.agc_Q_out_w);

                    // ─── Compare AGC output ──────────────────────────
                    if (agc_valid_pipe5 && !$isunknown(BLE_PHY_vif.In_Phase_AGC_o)) begin
                        if (agc_I_out_ref !== $signed(BLE_PHY_vif.In_Phase_AGC_o) ||
                            agc_Q_out_ref !== $signed(BLE_PHY_vif.Quadrature_Phase_AGC_o)) begin
                            error_count++;
                            `uvm_error("run_phase", $sformatf({"AGC Mismatch at time = %0t,\n",
                                        "In_Phase_AGC_o Received: %0h Expected: %0h,\n",
                                        "Quadrature_Phase_AGC_o Received: %0h Expected: %0h"},
                                        $time,
                                        BLE_PHY_vif.In_Phase_AGC_o, agc_I_out_ref,
                                        BLE_PHY_vif.Quadrature_Phase_AGC_o, agc_Q_out_ref))
                        end
                        else begin
                            correct_count++;
                        end
                    end

                    // ─── Track downsampler counter ───────────────────
                    if (BLE_PHY_vif.demod_valid_w) begin
                        if (rx_downsample_cnt == SAMPLE_PER_SYMBOL - 1) begin
                            rx_downsample_cnt = 0;
                            demod_at_sample   = BLE_PHY_vif.demod_signal_w;
                        end
                        else begin
                            rx_downsample_cnt = rx_downsample_cnt + 1;
                        end
                    end

                    // ─── Compare RX bit output ───────────────────────
                    if (BLE_PHY_vif.rx_bit_valid_o && !$isunknown(BLE_PHY_vif.rx_bit_o)) begin
                        if (demod_at_sample !== BLE_PHY_vif.rx_bit_o) begin
                            error_count++;
                            `uvm_error("run_phase", $sformatf({"RX Bit Mismatch at time = %0t,\n",
                                        "rx_bit_o Received: %0b Expected: %0b"},
                                        $time,
                                        BLE_PHY_vif.rx_bit_o, demod_at_sample))
                        end
                        else begin
                            correct_count++;
                        end
                    end
                end
            end
        join
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info("Report Phase" ,$sformatf("Total Correct:%0d",correct_count),UVM_MEDIUM);
        `uvm_info("Report Phase" ,$sformatf("Total Errors:%0d",error_count),UVM_MEDIUM);
    endfunction

    task ref_model(PHY_seq_item seq_item_chk);
        if(!seq_item_chk.rst_n) begin
            
            // TX Signals
            Quadrature_Phase_AGC_o_ref  = 'd0;
            In_Phase_AGC_o_ref          = 'd0;

            bit_upsample_valid          = 1'b0;
            bit_upsample                = 1'b0;
            counter_in                  =   0;

            bit_upsample_store          = 16'b0;

            gauss_filter_tap0           = 'd0;
            gauss_filter_tap1           = 'd0;
            gauss_filter_tap2           = 'd0;
            gauss_filter_tap3           = 'd0;
            gauss_filter_tap4           = 'd0;
            gauss_filter_tap5           = 'd0;
            gauss_filter_tap6           = 'd0;
            gauss_filter_tap7           = 'd0;
            gauss_filter_tap8           = 'd0;

            gaussian_filter_valid       = 1'b0;
            gaussian_filter_out         = 'd0;

            // VCO Reset
            vco_accumulator             = 'd0;
            vco_accumulator_d1          = 'd0;
            vco_phase_index             = 'd0;
            vco_phase_index_d1          = 'd0;
            vco_sin_out                 = 'd0;
            vco_cos_out                 = 'd0;
            vco_I_12                    = 'd0;
            vco_I_12_d1                 = 'd0;
            vco_I_12_d2                 = 'd0;
            vco_Q_12                    = 'd0;
            vco_Q_12_d1                 = 'd0;
            vco_Q_12_d2                 = 'd0;
            vco_valid                   = 1'b0;
            vco_valid_d1                = 1'b0;
            vco_valid_d2                = 1'b0;

            // AGC Reset
            I_ext                       = 'd0;
            Q_ext                       = 'd0;
            agc_raw_power               = 'd0;
            agc_sum                     = 'd0;
            agc_wr_ptr                  = 'd0;
            agc_gain                    = 'd0;
            I_product                   = 'd0;
            Q_product                   = 'd0;
            for(int k = 0; k < 16; k++) agc_avg_buffer[k] = 'd0;

            // RSSI Reset
            rssi_power_16               = 'd0;
            rssi_sum                    = 'd0;
            rssi_wr_ptr                 = 'd0;
            rssi_real                   = 0.0;
            rssi_fixed                  = 'd0;
            signal_flag_o_ref           = 'd0;
            for(int k = 0; k < 16; k++) rssi_avg_buffer[k] = 'd0;

            // RX Signals
            rx_bit_o_ref                = 'd0;
            rx_bit_valid_o_ref          = 'd0;

            in_phase_i_0                = 'd0;
            in_phase_i_1                = 'd0;
            quadrature_q_0              = 'd0;
            quadrature_q_1              = 'd0;
            decision                    = 'd0;
            valid_pipe                  = 3'b0;
            demod_signal                = 1'b0;
            demod_signal_valid          = 1'b0;

            downsample_cnt              = 'd0;

            // RX Pipeline reset
            for(int k = 0; k < 3; k++) begin
                in_phase_pipe[k]   = 'd0;
                quad_phase_pipe[k] = 'd0;
                valid_pipe_d[k]    = 1'b0;
            end
            decision_pipe  = 'd0;
            demod_pipe[0]  = 1'b0;
            demod_pipe[1]  = 1'b0;

        end

        else begin

            // Load tap values from seq_item
            case(seq_item_chk.tap_address_i)
                0: gauss_filter_tap0 = seq_item_chk.tap_value_i;
                1: gauss_filter_tap1 = seq_item_chk.tap_value_i;
                2: gauss_filter_tap2 = seq_item_chk.tap_value_i;
                3: gauss_filter_tap3 = seq_item_chk.tap_value_i;
                4: gauss_filter_tap4 = seq_item_chk.tap_value_i;
                5: gauss_filter_tap5 = seq_item_chk.tap_value_i;
                6: gauss_filter_tap6 = seq_item_chk.tap_value_i;
                7: gauss_filter_tap7 = seq_item_chk.tap_value_i;
                8: gauss_filter_tap8 = seq_item_chk.tap_value_i;
            endcase

            //////////////////////////////////////////////////////////////
            ///////////////////Transmitter Golden Model///////////////////
            //////////////////////////////////////////////////////////////

            if (seq_item_chk.bit_valid_i) begin

                bit_upsample_valid = 1'b1;

                if (counter_in != NRZ_DATA_WIDTH) begin
                    bit_upsample_reg[counter_in] = {SAMPLE_PER_SYMBOL{seq_item_chk.phy_bit_i}};
                    counter_in++;
                end else begin
                    counter_in = 0;
                end

                counter_out = 0;
                loop_out    = 0;

                while (counter_out != NRZ_DATA_WIDTH) begin

                    if (loop_out != SAMPLE_PER_SYMBOL - 1) begin
                        bit_upsample       = bit_upsample_reg[counter_out][loop_out];
                        bit_upsample_valid = 1'b1;
                        loop_out++;
                    end 
                    else begin
                        bit_upsample       = bit_upsample_reg[counter_out][loop_out];
                        bit_upsample_valid = 1'b1;
                        loop_out           = 0;
                        counter_out++;
                    end

                    if (bit_upsample_valid) begin

                        gaussian_filter_valid = 1'b1;

                        tap0_addr0  = bit_upsample            ? gauss_filter_tap0 : -gauss_filter_tap0;
                        tap1_addr1  = bit_upsample_store[0]   ? gauss_filter_tap1 : -gauss_filter_tap1;
                        tap2_addr2  = bit_upsample_store[1]   ? gauss_filter_tap2 : -gauss_filter_tap2;
                        tap3_addr3  = bit_upsample_store[2]   ? gauss_filter_tap3 : -gauss_filter_tap3;
                        tap4_addr4  = bit_upsample_store[3]   ? gauss_filter_tap4 : -gauss_filter_tap4;
                        tap5_addr5  = bit_upsample_store[4]   ? gauss_filter_tap5 : -gauss_filter_tap5;
                        tap6_addr6  = bit_upsample_store[5]   ? gauss_filter_tap6 : -gauss_filter_tap6;
                        tap7_addr7  = bit_upsample_store[6]   ? gauss_filter_tap7 : -gauss_filter_tap7;
                        tap8_addr8  = bit_upsample_store[7]   ? gauss_filter_tap8 : -gauss_filter_tap8;
                        tap7_addr9  = bit_upsample_store[8]   ? gauss_filter_tap7 : -gauss_filter_tap7;
                        tap6_addr10 = bit_upsample_store[9]   ? gauss_filter_tap6 : -gauss_filter_tap6;
                        tap5_addr11 = bit_upsample_store[10]  ? gauss_filter_tap5 : -gauss_filter_tap5;
                        tap4_addr12 = bit_upsample_store[11]  ? gauss_filter_tap4 : -gauss_filter_tap4;
                        tap3_addr13 = bit_upsample_store[12]  ? gauss_filter_tap3 : -gauss_filter_tap3;
                        tap2_addr14 = bit_upsample_store[13]  ? gauss_filter_tap2 : -gauss_filter_tap2;
                        tap1_addr15 = bit_upsample_store[14]  ? gauss_filter_tap1 : -gauss_filter_tap1;
                        tap0_addr16 = bit_upsample_store[15]  ? gauss_filter_tap0 : -gauss_filter_tap0;

                        bit_upsample_store = {bit_upsample_store[14:0], bit_upsample};

                        gaussian_filter_out =   tap0_addr0  + tap1_addr1  + tap2_addr2  + tap3_addr3  +
                                                tap4_addr4  + tap5_addr5  + tap6_addr6  + tap7_addr7  +
                                                tap8_addr8  + tap7_addr9  + tap6_addr10 + tap5_addr11 +
                                                tap4_addr12 + tap3_addr13 + tap2_addr14 + tap1_addr15 +
                                                tap0_addr16;
                    end 
                    else begin
                        gaussian_filter_valid = 1'b0;
                    end
                end

                //////////////////////////////////////////////////////////////
                ////////////////////VCO + AGC Golden Model///////////////////
                //////////////////////////////////////////////////////////////

                if (gaussian_filter_valid) begin

                    // VCO Stage 1: Accumulator (registered - 1 cycle delay)
                    vco_accumulator_d1  = vco_accumulator;
                    vco_accumulator     = vco_accumulator + $signed(gaussian_filter_out);
                    vco_phase_index_d1  = vco_accumulator_d1[15:8];
                    vco_valid_d1        = 1'b1;

                    // VCO Stage 2: LUT lookup (registered - 1 more cycle delay)
                    vco_I_12_d2  = vco_I_12_d1;
                    vco_Q_12_d2  = vco_Q_12_d1;
                    vco_valid_d2 = vco_valid_d1;

                    vco_sin_out  = $signed(sin_lut[vco_phase_index_d1]);
                    vco_cos_out  = $signed(cos_lut[vco_phase_index_d1]);
                    vco_I_12_d1  = vco_cos_out[11:0];
                    vco_Q_12_d1  = vco_sin_out[11:0];

                    // Use 2-cycle delayed output for AGC
                    vco_I_12 = vco_I_12_d2;
                    vco_Q_12 = vco_Q_12_d2;
                    vco_valid = vco_valid_d2;

                    if (vco_valid) begin
                        // AGC: Sign extend 12-bit to 16-bit
                        I_ext = $signed({{(AGC_IQ_WIDTH-IQ_WIDTH){vco_I_12[IQ_WIDTH-1]}}, vco_I_12});
                        Q_ext = $signed({{(AGC_IQ_WIDTH-IQ_WIDTH){vco_Q_12[IQ_WIDTH-1]}}, vco_Q_12});

                        // AGC: Power Estimator
                        agc_raw_power = (I_ext * I_ext) + (Q_ext * Q_ext);

                        // AGC: Average Filter
                        agc_sum = agc_sum - agc_avg_buffer[agc_wr_ptr] + agc_raw_power;
                        agc_avg_buffer[agc_wr_ptr] = agc_raw_power;
                        agc_wr_ptr = agc_wr_ptr + 1;

                        // AGC: Gain Control
                        agc_gain = agc_gain + 
                                   (($signed({1'b0, AGC_POWER_TARGET}) - 
                                     $signed({1'b0, agc_sum >> AGC_AVG_LOG2})) >>> AGC_STEP_SIZE);

                        // AGC: Apply gain and scale Q8
                        I_product = $signed(vco_I_12) * $signed({1'b0, agc_gain});
                        Q_product = $signed(vco_Q_12) * $signed({1'b0, agc_gain});

                        // AGC: Clip to 12-bit signed limits
                        begin
                            logic signed [IQ_WIDTH-1:0] I_gained_ref, Q_gained_ref;
                            logic signed [IQ_WIDTH-1:0] CLIP_MAX, CLIP_MIN;

                            CLIP_MAX = {1'b0, {(IQ_WIDTH-1){1'b1}}};
                            CLIP_MIN = {1'b1, {(IQ_WIDTH-1){1'b0}}};

                            I_gained_ref = $signed(I_product >>> 8);
                            Q_gained_ref = $signed(Q_product >>> 8);

                            In_Phase_AGC_o_ref =
                                ($signed(I_gained_ref) > $signed(CLIP_MAX)) ? CLIP_MAX :
                                ($signed(I_gained_ref) < $signed(CLIP_MIN)) ? CLIP_MIN :
                                I_gained_ref;

                            Quadrature_Phase_AGC_o_ref =
                                ($signed(Q_gained_ref) > $signed(CLIP_MAX)) ? CLIP_MAX :
                                ($signed(Q_gained_ref) < $signed(CLIP_MIN)) ? CLIP_MIN :
                                Q_gained_ref;
                        end
                    end
                end

            end

            else begin
                bit_upsample_valid = 'b0;
                bit_upsample       = 'b0;
            end

            //////////////////////////////////////////////////////////////
            ////////////////////RSSI Golden Model/////////////////////////
            //////////////////////////////////////////////////////////////

            if (seq_item_chk.RX_Valid_i) begin

                // Power Estimator: I^2 + Q^2 then take upper 16 bits
                begin
                    logic [2*VCO_OUT_SIZE-1:0] rssi_raw_power_full;
                    logic [15:0]               rssi_abs_I, rssi_abs_Q;

                    rssi_abs_I = seq_item_chk.In_Phase_RX_i[VCO_OUT_SIZE-1] ?
                                -seq_item_chk.In_Phase_RX_i :
                                seq_item_chk.In_Phase_RX_i;

                    rssi_abs_Q = seq_item_chk.Quadrature_Phase_RX_i[VCO_OUT_SIZE-1] ?
                                -seq_item_chk.Quadrature_Phase_RX_i :
                                seq_item_chk.Quadrature_Phase_RX_i;

                    rssi_raw_power_full = (rssi_abs_I * rssi_abs_I) + 
                                        (rssi_abs_Q * rssi_abs_Q);

                    // Truncate to upper 16 bits [31:16]
                    rssi_power_16 = rssi_raw_power_full[2*VCO_OUT_SIZE-1 : VCO_OUT_SIZE];
                end

                // Average Filter: sliding window of 16 samples
                rssi_sum = rssi_sum - rssi_avg_buffer[rssi_wr_ptr] + rssi_power_16;
                rssi_avg_buffer[rssi_wr_ptr] = rssi_power_16;
                rssi_wr_ptr = rssi_wr_ptr + 1;

                // Log10 using real math (functional equivalent of LUT-based log10)
                begin
                    logic [15:0] avg_rssi;
                    logic [31:0] avg_rssi_32;

                    avg_rssi    = rssi_sum >> RSSI_N_LOG2;
                    avg_rssi_32 = {16'b0, avg_rssi};

                    rssi_real  = (avg_rssi_32 == 0) ? 0.0 : 
                                10.0 * $log10(real'(avg_rssi_32));

                    // Convert to Q8.8 fixed point (multiply by 256)
                    rssi_fixed = int'(rssi_real * 256.0);
                end

                // Signal flag: compare with threshold
                signal_flag_o_ref = (rssi_fixed >= RSSI_THRESHOLD) ? 1'b1 : 1'b0;

            end 

            //////////////////////////////////////////////////////////////
            ////////////////////Receiver Golden Model/////////////////////
            //////////////////////////////////////////////////////////////

            // Simple delay model - store previous IQ sample
            // DUT: decision = (I_prev * Q_curr) - (I_curr * Q_prev)
            in_phase_i_0   = in_phase_i_1;
            quadrature_q_0 = quadrature_q_1;

            if (seq_item_chk.RX_Valid_i) begin
                in_phase_i_1   = $signed(seq_item_chk.In_Phase_RX_i);
                quadrature_q_1 = $signed(seq_item_chk.Quadrature_Phase_RX_i);

                decision = ($signed(in_phase_i_0) * $signed(quadrature_q_1)) -
                           ($signed(in_phase_i_1) * $signed(quadrature_q_0));

                demod_signal = (decision > 0) ? 1'b1 : 1'b0;
                demod_signal_valid = 1'b1;
            end
            else begin
                demod_signal_valid = 1'b0;
                demod_signal       = 1'b0;
            end

            // Shift demod pipeline
            demod_pipe[1] = demod_pipe[0];
            demod_pipe[0] = demod_signal;

            // Bit downsampler — independent counter matching DUT exactly
            rx_bit_valid_o_ref = 1'b0;
            rx_bit_o_ref       = 1'b0;

            if (demod_signal_valid) begin
                if (downsample_cnt == SAMPLE_PER_SYMBOL - 1) begin
                    downsample_cnt     = 0;
                    rx_bit_o_ref       = demod_pipe[1];
                    rx_bit_valid_o_ref = 1'b1;
                end
                else begin
                    downsample_cnt = downsample_cnt + 1;
                end
            end

        end
    endtask

endclass
endpackage