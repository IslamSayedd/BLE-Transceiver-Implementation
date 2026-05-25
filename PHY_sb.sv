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
    



    function new(string name = "PHY_sb" , uvm_component parent = null);
        super.new(name , parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_export = new("sb_export" , this);
        sb_fifo = new("sb_fifo" , this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        sb_export.connect(sb_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            sb_fifo.get(seq_item_sb);
            ref_model(seq_item_sb);
            if (
            rx_bit_o_ref                    !== seq_item_sb.rx_bit_o              ||
            rx_bit_valid_o_ref              !== seq_item_sb.rx_bit_valid_o        ||
            signal_flag_o_ref               !== seq_item_sb.signal_flag_o         ||
            In_Phase_AGC_o_ref              !== seq_item_sb.In_Phase_AGC_o        ||
            Quadrature_Phase_AGC_o_ref      !== seq_item_sb.Quadrature_Phase_AGC_o  ) begin

            error_count++;
            
            `uvm_error("run_phase" , $sformatf("Error Detected at time = %0t,\n\
            rx_bit_o Received: %0b Expected: %0b,\n\
            rx_bit_valid_o Received: %0b Expected: %0b,\n\
            signal_flag_o Received: %0b Expected: %0b,\n\
            In_Phase_AGC_o Received: %0h Expected: %0h,\n\
            Quadrature_Phase_AGC_o Received: %0h Expected: %0h",
            $time,
            seq_item_sb.rx_bit_o              , rx_bit_o_ref,
            seq_item_sb.rx_bit_valid_o        , rx_bit_valid_o_ref,
            seq_item_sb.signal_flag_o         , signal_flag_o_ref,
            seq_item_sb.In_Phase_AGC_o        , In_Phase_AGC_o_ref,
            seq_item_sb.Quadrature_Phase_AGC_o, Quadrature_Phase_AGC_o_ref))
            end 
            
            else begin
                correct_count ++;
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info("Report Phase" ,$sformatf("Total Correct:%0d",correct_count),UVM_MEDIUM);
        `uvm_info("Report Phase" ,$sformatf("Total Errors:%0d",error_count),UVM_MEDIUM);
    endfunction

    task ref_model(TX_seq_item seq_item_chk);
        if(!seq_item_chk.rst_n) begin
            
            // Tx Signals
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

            


            // Rx Signals
            rx_bit_o_ref                = 'd0;
            rx_bit_valid_o_ref          = 'd0;
            signal_flag_o_ref           = 'd0;

            in_phase_i_0      = 'd0;
            in_phase_i_1      = 'd0;
            quadrature_q_0    = 'd0;
            quadrature_q_1    = 'd0;
            decision          = 'd0;
            valid_pipe        = 3'b0;
            demod_signal      = 1'b0;
            demod_signal_valid = 1'b0;

            downsample_cnt  = 'd0;

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

                // Input side: fill one register per transaction
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
            end

            else begin
                bit_upsample_valid = 'b0;
                bit_upsample = 'b0;
            end













            //////////////////////////////////////////////////////////////
            ////////////////////Receiver Golden Model/////////////////////
            //////////////////////////////////////////////////////////////

            if (seq_item_chk.RX_Valid_i) begin

                valid_pipe         = {valid_pipe[1:0], 1'b1};
                demod_signal_valid = valid_pipe[2];

                in_phase_i_0   = in_phase_i_1;
                in_phase_i_1   = seq_item_chk.In_Phase_RX_i;
                quadrature_q_0 = quadrature_q_1;
                quadrature_q_1 = seq_item_chk.Quadrature_Phase_RX_i;

                decision     = (in_phase_i_0 * quadrature_q_1) - (in_phase_i_1 * quadrature_q_0);
                demod_signal = (decision > 0) ? 1'b1 : 1'b0;

            end 
            else begin
                valid_pipe         = {valid_pipe[1:0], 1'b0};
                demod_signal_valid = valid_pipe[2];
                demod_signal       = 1'b0;
            end


            if (demod_signal_valid) begin
                if (downsample_cnt == SAMPLE_PER_SYMBOL - 1) begin
                    downsample_cnt   = 0;
                    rx_bit_o_ref       = demod_signal;
                    rx_bit_valid_o_ref = 1'b1;
                end 
                else begin
                    downsample_cnt = downsample_cnt + 1;
                end
            end
            else begin
                rx_bit_o_ref       = 1'b0;
                rx_bit_valid_o_ref = 1'b0;
            end


        end
    endtask

endclass
endpackage