module gaussian_filter # (
    parameter TAP_WIDTH = 16 , 
    parameter OUT_WIDTH = 16 ,
    parameter ADDRESS_WIDTH = 4 ,
    parameter NUM_OF_TAPS = 9
) (
    input  logic clk,
    input  logic rst_n,

    input  logic bit_upsample_valid_i,                      //From Upsample Block (Take 8 1's or 8 0's)
    input  logic bit_upsample_i,                            //From Upsample Block

    input  logic [TAP_WIDTH - 1 : 0] tap_value_i,           //Interface Input
    input  logic [ADDRESS_WIDTH - 1 : 0] tap_address_i,     //Interface Input

    output logic signed [OUT_WIDTH - 1  : 0] gaussian_filter_o,
    output logic gaussian_filter_out_valid_o
);

localparam NUM_SAMPLES = (NUM_OF_TAPS - 1) * 2 ;         //If 9 taps --> 16 (0---->15)
localparam NUM_PRE_ACC_TAPS = (NUM_OF_TAPS * 2) - 1 ;    //If 9 taps --> 17 (0---->16)

int i ;
int k ;
int j ;

logic signed [OUT_WIDTH-1:0] acc_comb;

//Shift register for input samples
logic [NUM_SAMPLES - 1 : 0] samples ;

//A memory to store the values of the Taps
logic [TAP_WIDTH - 1 : 0] store_taps [NUM_OF_TAPS - 1 : 0]; 
//Mem of Variables to map the tap values to positive or negative
logic signed [TAP_WIDTH - 1 : 0] pre_accum_tap [NUM_PRE_ACC_TAPS - 1 : 0]; 


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        for (i = 0; i < NUM_OF_TAPS; i++) begin
            store_taps[i] <= 'd0;
        end
        samples   <= 'd0;
        gaussian_filter_o <= 'd0;
        gaussian_filter_out_valid_o <= 'b0;
    end 

    else begin
        store_taps [tap_address_i]  <= tap_value_i;
        if (bit_upsample_valid_i) begin
            //Any new sample stored in [0] and others shift
            samples [ NUM_SAMPLES - 1 : 1 ] <= samples [ NUM_SAMPLES - 2 : 0];
            samples [0] <= bit_upsample_i;

            gaussian_filter_out_valid_o <= 1'b1;

            // Summation {g(𝑡) = 𝑐(𝑡) ∗ ℎ(𝑡)}
            gaussian_filter_o  <= acc_comb;
        end

        else begin
            gaussian_filter_out_valid_o <= 1'b0;
            gaussian_filter_o  <= 'd0;
        end
    end
end  

//Mapping
always @(*) begin
    // g(𝑡) = 𝑐(𝑡) ∗ ℎ(𝑡)        ℎ(𝑡) ---> taps      𝑐(𝑡) ---> Input (1/0)
    pre_accum_tap [0]  = (bit_upsample_i)   ? store_taps [0] : -store_taps [0];

    for (k = 1 ; k < NUM_OF_TAPS ; k = k + 1 ) begin
        pre_accum_tap[k] = (samples[k-1]) ? store_taps[k] : -store_taps[k];
    end

    for (j = NUM_OF_TAPS ; j < NUM_PRE_ACC_TAPS ; j = j + 1) begin
        pre_accum_tap[j] = (samples[j-1]) ? store_taps[ (NUM_PRE_ACC_TAPS - 1) - j ] : -store_taps[ (NUM_PRE_ACC_TAPS - 1) - j ];
    end
end

always @(*) begin
    acc_comb = '0;
    for (i = 0; i < NUM_PRE_ACC_TAPS; i++) begin
        acc_comb = acc_comb + pre_accum_tap[i];
    end
end

endmodule