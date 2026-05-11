module gaussian_filter # (
    parameter TAP_WIDTH    = 16,
    parameter OUT_WIDTH    = 16,
    parameter ADDRESS_WIDTH= 4,
    parameter NUM_OF_TAPS  = 9
)(
    input  logic clk,
    input  logic rst_n,

    // From Upsample Block
    input  logic bit_upsample_valid_i,
    input  logic bit_upsample_i,

    // Tap programming interface
    input  logic signed [TAP_WIDTH-1:0] tap_value_i,
    input  logic        [ADDRESS_WIDTH-1:0] tap_address_i,

    // Filter output
    output logic signed [OUT_WIDTH-1:0] gaussian_filter_o,
    output logic                        gaussian_filter_out_valid_o
);

    ////////////////////////////////////////////////////////////
    ////////////////////// Local Params ////////////////////////
    ////////////////////////////////////////////////////////////

    // If 9 taps --> 16 samples
    localparam NUM_SAMPLES = (NUM_OF_TAPS - 1) * 2;

    // If 9 taps --> 17 pre-accum values
    localparam NUM_PRE_ACC_TAPS = (NUM_OF_TAPS * 2) - 1;

    ////////////////////////////////////////////////////////////
    ////////////////////// Internal Signals ////////////////////
    ////////////////////////////////////////////////////////////

    integer i;
    integer j;
    integer k;

    // Accumulator
    logic signed [OUT_WIDTH-1:0] acc_comb;

    // Shift register for incoming bits
    logic [NUM_SAMPLES-1:0] samples;

    // Store Gaussian taps (SIGNED)
    logic signed [TAP_WIDTH-1:0]
        store_taps [NUM_OF_TAPS-1:0];

    // Positive/negative mapped taps
    logic signed [TAP_WIDTH-1:0]
        pre_accum_tap [NUM_PRE_ACC_TAPS-1:0];

    ////////////////////////////////////////////////////////////
    ////////////////////// Sequential Logic ////////////////////
    ////////////////////////////////////////////////////////////

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            for (i = 0; i < NUM_OF_TAPS; i = i + 1) begin
                store_taps[i] <= '0;
            end

            samples                     <= '0;
            gaussian_filter_o           <= '0;
            gaussian_filter_out_valid_o <= 1'b0;
        end

        else begin

            // Load tap values
            store_taps[tap_address_i] <= tap_value_i;

            if (bit_upsample_valid_i) begin

                // Shift samples
                samples[NUM_SAMPLES-1:1]
                    <= samples[NUM_SAMPLES-2:0];

                samples[0] <= bit_upsample_i;

                gaussian_filter_out_valid_o <= 1'b1;

                // FIR output
                gaussian_filter_o <= acc_comb;
            end

            else begin
                gaussian_filter_out_valid_o <= 1'b0;
                gaussian_filter_o           <= '0;
            end
        end
    end

    ////////////////////////////////////////////////////////////
    ////////////////////// Tap Mapping /////////////////////////
    ////////////////////////////////////////////////////////////

    always @(*) begin

        // Current sample
        pre_accum_tap[0] =
            (bit_upsample_i) ?
            store_taps[0] :
            -store_taps[0];

        // Left side taps
        for (k = 1; k < NUM_OF_TAPS; k = k + 1) begin

            pre_accum_tap[k] =
                (samples[k-1]) ?
                store_taps[k] :
                -store_taps[k];
        end

        // Mirrored right side taps
        for (j = NUM_OF_TAPS;
             j < NUM_PRE_ACC_TAPS;
             j = j + 1) begin

            pre_accum_tap[j] =
                (samples[j-1]) ?
                store_taps[(NUM_PRE_ACC_TAPS-1)-j] :
                -store_taps[(NUM_PRE_ACC_TAPS-1)-j];
        end
    end

    ////////////////////////////////////////////////////////////
    ////////////////////// Accumulator /////////////////////////
    ////////////////////////////////////////////////////////////

    always @(*) begin

        acc_comb = '0;

        for (i = 0; i < NUM_PRE_ACC_TAPS; i = i + 1) begin
            acc_comb = acc_comb + pre_accum_tap[i];
        end
    end

endmodule
