module accumulator# (parameter OUT_WIDTH = 12; outputparameter DATA_WIDTH = 8)(
    input logic signed [OUT_WIDTH - 1 : 0] gauss_filter_o,  // Gaussian filter output
    input logic gaussian_filter_out_valid_o,                // Valid signal for the Gaussian filter output
    output logic [DATA_WIDTH - 1 : 0] Phase_index_i,        // Phase index output
    output logic phase_valid_i                              // Phase valid output
);

    logic signed [OUT_WIDTH - 1 : 0] accumulator_reg; 
    
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            accumulator_reg <= 0;
            phase_valid_i <= 0;
        end 
        else if (gaussian_filter_out_valid_o) begin
            // Accumulate the Gaussian filter output
            accumulator_reg <= accumulator_reg + gauss_filter_o;
            phase_valid_i <= 1;  // Assert valid when accumulation happens
        end 
        else begin
            phase_valid_i <= 0;  // Deassert valid when no new data
        end
    end
    
    // Convert accumulator value to an 8-bit phase index
    assign Phase_index_i = accumulator_reg[DATA_WIDTH-1:0];  // Use the lower 8 bits for the phase index

endmodule
