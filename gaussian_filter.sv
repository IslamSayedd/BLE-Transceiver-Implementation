module gaussian_filter #(
    parameter WIDTH = 8 , 
    parameter OUT_WIDTH = WIDTH + 4 ,
    parameter N = 8
) (
    input  logic clk,
    input  logic rst_n,

    input  logic bit_upsample_valid_i,
    input  logic signed [WIDTH - 1 : 0] bit_upsample_i,

    input  logic signed [WIDTH - 1 : 0] tap_value_i,

    output logic signed [OUT_WIDTH - 1  : 0] gaussian_filter_o,
    output logic gaussian_filter_out_valid_o
);

integer i , 
        j ,
        k ,
        l ;

logic signed [WIDTH - 1 : 0] store_taps [N-1 : 0];
logic signed [WIDTH - 1 : 0] pre_accum_taps [(2*N)-1 : 0];
logic signed [OUT_WIDTH - 1  : 0] accum_sum;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        for (i = 0; i < N; i++) begin
            store_taps[i] <= '0;
        end

        for (j = 0; j < (2*N) ; j++) begin
            pre_accum_taps[j] <= '0;
        end

        gaussian_filter_o <= 'd0;
        gaussian_filter_out_valid_o <= 'b0;
        accum_sum <= 'd0;

    end 

    else begin

        if (bit_upsample_valid_i) begin

            gaussian_filter_out_valid_o <= 'b1;

            for (i = N-1 ; i > 0 ; i-- ) begin
                store_taps[i] <= store_taps[i-1];
            end

            store_taps[0] <= tap_value_i;

            for (j = 0; j < N; j++) begin

                if (bit_upsample_i [j]) begin
                    pre_accum_taps [j] <= store_taps [j];
                end
                else begin
                    pre_accum_taps [j] <= -store_taps [j];
                end 
                
            end 
            
            for (k = N; k < 2*N; k++) begin
                
                if (bit_upsample_i [k]) begin
                    pre_accum_taps [k] <= store_taps [2*N - k - 1];
                end
                else begin
                    pre_accum_taps [k] <= -store_taps [2*N - k - 1];
                end 

            end 

            accum_sum <= 'd0;
            
            for (l = 0; l < 2*N; l++) begin
                accum_sum <= accum_sum + pre_accum_taps[l];
            end

            gaussian_filter_o <= accum_sum;
        end
    end
end    

endmodule
