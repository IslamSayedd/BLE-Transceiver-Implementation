module Accumulator #(
    parameter OUT_WIDTH  = 12,
    parameter DATA_WIDTH = 8
)(
    input  logic                         clk,
    input  logic                         reset_n,

    input  logic signed [OUT_WIDTH-1:0] gauss_filter_o,
    input  logic                        gaussian_filter_out_valid_o,

    output logic [DATA_WIDTH-1:0]       Phase_index_i,
    output logic                        phase_valid_i
);

    logic signed [OUT_WIDTH-1:0] accumulator_reg;

    ////////////////////////////////////////////////////////////
    ////////////////////// Accumulator /////////////////////////
    ////////////////////////////////////////////////////////////

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
            phase_valid_i <= 1'b0;
        end
    end

    ////////////////////////////////////////////////////////////
    ////////////////////// MSB Extraction //////////////////////
    ////////////////////////////////////////////////////////////

    assign Phase_index_i =
        $unsigned(
            accumulator_reg[OUT_WIDTH-1 : OUT_WIDTH-DATA_WIDTH]
        );

endmodule
