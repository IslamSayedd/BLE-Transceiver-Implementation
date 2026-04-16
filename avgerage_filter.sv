module avgerage_filter #(
    parameter DATA_WIDTH = 32,
    parameter N_LOG2     = 4     // window size = 2^N_LOG2 (e.g. 4 -> 16 samples)
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     valid_in_i,
    input  wire [DATA_WIDTH-1:0]    data_in_i,

    output reg  [DATA_WIDTH-1:0]    avg_out_o,
    output reg                      valid_out_o
);

    localparam N = (1 << N_LOG2);

    reg [DATA_WIDTH-1:0] buffer [0:N-1];
    reg [N_LOG2-1:0] wr_ptr;
    reg [DATA_WIDTH + N_LOG2 : 0] sum;

    integer i;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            wr_ptr    <= 0;
            sum       <= 0;
            avg_out_o   <= 0;
            valid_out_o <= 0;

            for (i = 0; i < N; i = i + 1)
                buffer[i] <= 0;

        end else if (valid_in_i) begin

            // Subtract oldest sample
            sum <= sum - buffer[wr_ptr] + data_in_i;

            // Store new sample
            buffer[wr_ptr] <= data_in_i;

            // Update pointer
            wr_ptr <= wr_ptr + 1;

            // Compute average
            avg_out_o <= sum >> N_LOG2;

            valid_out_o <= 1;
        end
    end

endmodule