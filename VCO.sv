module VCO #(
    parameter OUT_WIDTH  = 12,
    parameter DATA_WIDTH = 8,
    parameter OUT_SIZE   = 8
)(
    input  wire                         clk,
    input  wire                         reset_n,

    input  wire signed [OUT_WIDTH-1:0]  gauss_filter_o,
    input  wire                         gaussian_filter_out_valid_o,

    output wire        [OUT_SIZE-1:0]   Quadrature_Phase_o,  // sin
    output wire        [OUT_SIZE-1:0]   In_Phase_o,          // cos
    output wire                         Phase_Valid_o
);

    wire [DATA_WIDTH-1:0] Phase_index_i;
    wire                 phase_valid_i;

    // 1) Accumulator: Gaussian filter -> Phase index
    accumulator #(
        .OUT_WIDTH (OUT_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_accumulator (
        .clk                        (clk),
        .reset_n                    (reset_n),
        .gauss_filter_o             (gauss_filter_o),
        .gaussian_filter_out_valid_o(gaussian_filter_out_valid_o),
        .Phase_index_i              (Phase_index_i),
        .phase_valid_i              (phase_valid_i)
    );

    // 2) Phase table: Phase index -> I/Q (cos/sin)
    IQ_Wave_Genarator #(
        .DATA_WIDTH(DATA_WIDTH),
        .OUT_SIZE  (OUT_SIZE)
    ) u_iq_wave_generator (
        .clk                (clk),
        .rst_n              (reset_n),       // same reset, different name
        .Phase_index_i      (Phase_index_i),
        .phase_valid_i      (phase_valid_i),
        .Quadrature_Phase_o (Quadrature_Phase_o),
        .In_Phase_o         (In_Phase_o),
        .Phase_Valid_o      (Phase_Valid_o)
    );

endmodule
