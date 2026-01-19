`timescale 1ns/1ps
module bit_downsampler #(
    parameter SAMPLE_PER_SYMBOL = 8,
    parameter CNT_WIDTH = 4 
)(
    input  wire CLK_i,
    input  wire RST_i,

    input  wire bit_i,
    input  wire bit_valid_i,

    output reg  bit_o,
    output reg  bit_valid_o
);

    reg [CNT_WIDTH-1:0] cnt;

    always @(posedge CLK_i or negedge RST_i) begin
        if (!RST_i) begin
            cnt         <= 0;
            bit_o       <= 0;
            bit_valid_o <= 0;
        end
        else begin
            bit_valid_o <= 0;   // default

            if (bit_valid_i) begin
                if (cnt == SAMPLE_PER_SYMBOL-1) begin
                    cnt         <= 0;
                    bit_o       <= bit_i;
                    bit_valid_o <= 1'b1;
                end
                else begin
                    cnt <= cnt + 1'b1;
                end
            end
        end
    end

endmodule
