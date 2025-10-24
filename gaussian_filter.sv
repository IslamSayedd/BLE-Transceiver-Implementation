module gaussian_filter #(
    parameter IN_WIDTH = 8 , 
    parameter OUT_WIDTH = IN_WIDTH + IN_WIDTH ,
    parameter N = 8
) (
    input  logic clk,
    input  logic rst_n,
    input  logic upsample_valid,
    input  logic signed [IN_WIDTH  - 1 : 0] data_i,
    output logic signed [OUT_WIDTH - 1 : 0] data_o
);

integer i;

localparam signed [ IN_WIDTH -1 : 0 ] h [ N-1 : 0 ] = '{ 'd22, 'd30, 'd36, 'd40, 'd40, 'd36, 'd30, 'd22 };

logic signed [IN_WIDTH - 1 : 0] store_in [N-1 : 0];
logic signed [OUT_WIDTH - 1 : 0] acc;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < N; i++) begin
            store_in[i] <= '0;
        end
        data_o <= 'b0;
    end 
    else begin
        if (upsample_valid) begin
            for (i = N-1 ; i > 0 ; i-- ) begin
                store_in[i] <= store_in[i-1];
            end

            store_in[0] <= data_i;

            acc = 'd0;
            
            for (i = 0; i < N; i++) begin
                acc <= acc + store_in[i] * h[i];
            end

            data_o <= acc;
        end
        
    end
end    

endmodule