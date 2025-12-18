<<<<<<< HEAD
module accumulator #(parameter OUT_WIDTH  = 12, parameter DATA_WIDTH = 8)(
    input  logic                         clk,
    input  logic                         reset_n,

    input  logic signed [OUT_WIDTH-1:0]  gauss_filter_o,          // Gaussian filter output
    input  logic                         gaussian_filter_out_valid_o,

    output logic        [DATA_WIDTH-1:0] Phase_index_i,           // Phase index (MSBs)
    output logic                         phase_valid_i
=======
module accumulator# (parameter OUT_WIDTH = 12, outputparameter DATA_WIDTH = 8)(
    input logic signed [OUT_WIDTH - 1 : 0] gauss_filter_o,  // Gaussian filter output
    input logic gaussian_filter_out_valid_o,                // Valid signal for the Gaussian filter output
    output logic [DATA_WIDTH - 1 : 0] Phase_index_i,        // Phase index output
    output logic phase_valid_i                              // Phase valid output
>>>>>>> a3abae48121eb90b943fac2c0eceedc3f147f1e7
);

    logic signed [OUT_WIDTH-1:0] accumulator_reg;

    // Accumulator
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            accumulator_reg <= '0;
            phase_valid_i   <= 1'b0;
        end
        else if (gaussian_filter_out_valid_o) begin
            accumulator_reg <= accumulator_reg + gauss_filter_o;
            phase_valid_i   <= 1'b1;
        end
        else begin
            phase_valid_i   <= 1'b0;
        end
    end

    // MSB extraction: use the most significant bits for phase indexing
    // Equivalent to accumulator_reg[OUT_WIDTH-1 : OUT_WIDTH-DATA_WIDTH]
    assign Phase_index_i = accumulator_reg[OUT_WIDTH-1 : OUT_WIDTH-DATA_WIDTH];

endmodule
