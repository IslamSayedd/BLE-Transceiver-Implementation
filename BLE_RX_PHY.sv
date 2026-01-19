module BLE_RX_PHY #(
    parameter IQ_BIT_WIDTH       = 12,
    parameter SAMPLE_PER_SYMBOL  = 8,
    parameter CNT_WIDTH          = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [IQ_BIT_WIDTH-1:0] in_phase_i_i,
    input  wire [IQ_BIT_WIDTH-1:0] quadrature_q_i,
    input  wire                    iq_valid_i,
    output wire                    rx_bit_o,
    output wire                    rx_bit_valid_o
);

    wire demod_signal;
    wire demod_signal_valid;

    // ===============================
    //   FSK Demodulator
    // ===============================
    fsk_demod #(
        .IQ_BIT_WIDTH (IQ_BIT_WIDTH)
    ) u_fsk_demod (
        .CLK_i                (clk),
        .RST_i                (rst_n),
        .in_phase_i_i         (in_phase_i_i),
        .quadrature_q_i       (quadrature_q_i),
        .iq_valid_i           (iq_valid_i),
        .demod_signal_o       (demod_signal),
        .demod_signal_valid_o (demod_signal_valid)
    );

    // ===============================
    //   Bit Downsampler
    // ===============================
    bit_downsampler #(
        .SAMPLE_PER_SYMBOL (SAMPLE_PER_SYMBOL),
        .CNT_WIDTH         (CNT_WIDTH)
    ) u_bit_downsampler (
        .CLK_i        (clk),
        .RST_i        (rst_n),
        .bit_i        (demod_signal),
        .bit_valid_i  (demod_signal_valid),
        .bit_o        (rx_bit_o),
        .bit_valid_o  (rx_bit_valid_o)
    );

endmodule
