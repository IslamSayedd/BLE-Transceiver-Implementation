module Gain_Control # (parameter POWER_TARGET = 33'd4294967296,
                                STEP_SIZE = 3,
                                IN_SIZE = 33,
                                OUT = 34
)(
 input   wire                       clk,
 input   wire                       rst_n,
 input   wire       [ IN_SIZE-1:0 ] power_i,
 input   wire                       power_valid_i, 
 output  reg        [ OUT-1:0 ]     gain_o,
 output  reg                        gain_valid_o
);

 reg signed [ OUT-1:0 ] error; 
 reg signed [ OUT-1:0 ] gain_old, gain_temp;
 reg                     Done;


 always @(posedge clk or negedge rst_n) 
 begin 
    if (~rst_n) 
        begin
            error     <= 'b0;
            gain_temp <= 'b0;
            Done      <= 1'b0;
        end 
    else 
        begin
            if (power_valid_i)
                begin
                    error     <= $signed({1'b0, POWER_TARGET}) - $signed({1'b0, power_i});
                    gain_temp <= gain_old + ($signed({1'b0, POWER_TARGET}) - $signed({1'b0, power_i}) >>> STEP_SIZE);
                    Done      <= 1'b1;
                end
            else
                begin
                    error     <= 'b0;
                    gain_temp <= gain_old;
                    Done      <= 1'b0;
                end
        end
 end

=
 always @(posedge clk or negedge rst_n)
 begin
    if (~rst_n)
        begin
            gain_o       <= 'b0;
            gain_valid_o <= 'b0;
            gain_old     <= 'b0;
        end
    else
        begin
            gain_o       <= gain_temp;
            gain_valid_o <= Done;
            gain_old     <= gain_temp;
        end
 end

endmodule