module gaussian_filter #(
    parameter WIDTH = 8 , 
    parameter OUT_WIDTH = WIDTH + 4 ,
    parameter ADDRESS_WIDTH = 4 ,
    parameter NUM_OF_TAPS = 8
) (
    input  logic clk,
    input  logic rst_n,

    input  logic bit_upsample_valid_i,
    input  logic [WIDTH - 1 : 0] bit_upsample_i,

    input  logic [WIDTH - 1 : 0] tap_value_i,
    input  logic [ADDRESS_WIDTH - 1 : 0] tap_address_i,

    output logic signed [OUT_WIDTH - 1  : 0] gaussian_filter_o,
    output logic gaussian_filter_out_valid_o
);

integer i , 
        j ,
        k ,
        l ;

logic [WIDTH - 1 : 0] store_taps [NUM_OF_TAPS-1 : 0];
logic signed [WIDTH : 0] pre_accum_tap0;
logic signed [WIDTH : 0] pre_accum_tap1;
logic signed [WIDTH : 0] pre_accum_tap2;
logic signed [WIDTH : 0] pre_accum_tap3;
logic signed [WIDTH : 0] pre_accum_tap4;
logic signed [WIDTH : 0] pre_accum_tap5;
logic signed [WIDTH : 0] pre_accum_tap6;
logic signed [WIDTH : 0] pre_accum_tap7;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        for (i = 0; i < NUM_OF_TAPS; i++) begin
            store_taps[i] <= '0;
        end

        pre_accum_tap0 <= 'd0;
        pre_accum_tap1 <= 'd0;
        pre_accum_tap2 <= 'd0;
        pre_accum_tap3 <= 'd0;
        pre_accum_tap4 <= 'd0;
        pre_accum_tap5 <= 'd0;
        pre_accum_tap6 <= 'd0;
        pre_accum_tap7 <= 'd0;

        gaussian_filter_o <= 'd0;
        gaussian_filter_out_valid_o <= 'b0;

    end 

    else begin

        if (bit_upsample_valid_i) begin

            gaussian_filter_out_valid_o <= 'b1;

            store_taps [tap_address_i] <= tap_value_i;

            if (bit_upsample_i [0]) begin
                pre_accum_tap0 <= {1'b0 , store_taps [0]};
                pre_accum_tap1 <= {1'b0 , store_taps [1]};
                pre_accum_tap2 <= {1'b0 , store_taps [2]};
                pre_accum_tap3 <= {1'b0 , store_taps [3]};
                pre_accum_tap4 <= {1'b0 , store_taps [4]};
                pre_accum_tap5 <= {1'b0 , store_taps [5]};
                pre_accum_tap6 <= {1'b0 , store_taps [6]};
                pre_accum_tap7 <= {1'b0 , store_taps [7]};
            end
            else begin
                pre_accum_tap0 <= -store_taps [0];
                pre_accum_tap1 <= -store_taps [1];
                pre_accum_tap2 <= -store_taps [2];
                pre_accum_tap3 <= -store_taps [3];
                pre_accum_tap4 <= -store_taps [4];
                pre_accum_tap5 <= -store_taps [5];
                pre_accum_tap6 <= -store_taps [6];
                pre_accum_tap7 <= -store_taps [7];
            end  
        
            gaussian_filter_o <= pre_accum_tap0 + pre_accum_tap1 + pre_accum_tap2 + pre_accum_tap3 + pre_accum_tap4 + pre_accum_tap5 + pre_accum_tap6 + pre_accum_tap7  ;
        
        end
    end
end    

endmodule
