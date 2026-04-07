module Power_Estimator #( parameter N = 16 )(

    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     valid_in,

    input  wire signed [N-1:0]      I_in,
    input  wire signed [N-1:0]      Q_in,

    output reg  [2*N:0]             power_out,
    output reg                      valid_out
);

    reg [N-1:0] abs_I, abs_Q;          
    reg [2*N-1:0] I_sq, Q_sq;
    reg [2*N:0]   power_sum;

    reg valid_d;

    integer i;

    always @(*) 
        begin
            abs_I = (I_in[N-1]) ? -I_in : I_in;
            abs_Q = (Q_in[N-1]) ? -Q_in : Q_in;
        end

    always @(*) 
        begin
            I_sq = 0;
            Q_sq = 0;

            for (i = 0; i < N; i = i + 1) 
                begin
                    if (abs_I[i])
                        I_sq = I_sq + (abs_I << i);

                    if (abs_Q[i])
                        Q_sq = Q_sq + (abs_Q << i);
                end
        end

    always @(posedge clk or negedge rst_n) 
        begin
            if (!rst_n) 
                begin
                    power_out <= 0;
                    valid_out <= 0;
                    valid_d   <= 0;
                end 
            else if (valid_in) 
                begin
                    power_sum <= I_sq + Q_sq;
                    power_out <= I_sq + Q_sq;
                    valid_out <= 1'b1;
                end
            else    
                begin
                    valid_out <= 1'b0;
                end
        end

endmodule