module gaussian_filter # (
    parameter IN_WIDTH = 8 ,
    parameter TAP_WIDTH = 12 , 
    parameter OUT_WIDTH = 14 , //13 For Value 1 For Sign
    parameter ADDRESS_WIDTH = 4 ,
    parameter NUM_OF_TAPS = 17 //Taken From another File
) (
    input  logic clk,
    input  logic rst_n,

    input  logic bit_upsample_valid_i,                     //From Upsample Block (Take 8 1's or 8 0's)
    input  logic [IN_WIDTH - 1 : 0] bit_upsample_i,        //From Upsample Block

    input  logic [TAP_WIDTH - 1 : 0] tap_value_i,           //Interface Input
    input  logic [ADDRESS_WIDTH - 1 : 0] tap_address_i,     //Interface Input

    output logic signed [OUT_WIDTH - 1  : 0] gaussian_filter_o,
    output logic gaussian_filter_out_valid_o
);

logic [TAP_WIDTH : 0] mapped_value ;

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        gaussian_filter_o <= 'd0;
        gaussian_filter_out_valid_o <= 'b0;
        mapped_value <= 'b0;
    end 

    else begin
        if (bit_upsample_valid_i) begin
            gaussian_filter_out_valid_o <= 1'b1;
            mapped_value  <= (&bit_upsample_i)   ? {1'b0 , tap_value_i} : -tap_value_i;

            // Summation {g(𝑡) = 𝑐(𝑡) ∗ ℎ(𝑡)}
            gaussian_filter_o <= mapped_value + gaussian_filter_o;

        end
        else begin
            gaussian_filter_out_valid_o <= 1'b0;
            gaussian_filter_o  <= 'd0;
            mapped_value <= 'b0;
        end
    end
end  


endmodule