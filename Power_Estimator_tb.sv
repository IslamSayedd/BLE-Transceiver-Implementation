`timescale 1ns/1ps
module Power_Estimator_tb ();

parameter N = 16;
parameter Clock_PERIOD = 20;

//==================== Signals ====================//

reg                     clk;
reg                     rst_n;
reg                     valid_in;

reg signed [N-1:0]      I_in;
reg signed [N-1:0]      Q_in;

wire [2*N-1:0]          power_out;
wire                    valid_out;

//==================== Initial Block ====================//

initial begin

    // Dump waves
    $dumpfile("Power_Estimator.vcd");
    $dumpvars;

    initialize();

    @(negedge clk);
    reset();

    //==================== Test Cases ====================//

    @(negedge clk);
    input_driven(16'd0,    16'd0,    1'b1);   // TC1: zero input

    @(negedge clk);
    input_driven(16'd10,   16'd0,    1'b1);   // TC2: only I

    @(negedge clk);
    input_driven(16'd0,    16'd10,   1'b1);   // TC3: only Q

    @(negedge clk);
    input_driven(16'd5,    16'd5,    1'b1);   // TC4: equal small

    @(negedge clk);
    input_driven(-16'd5,   16'd5,    1'b1);   // TC5: negative I

    @(negedge clk);
    input_driven(16'd5,   -16'd5,    1'b1);   // TC6: negative Q

    @(negedge clk);
    input_driven(-16'd8,  -16'd8,    1'b1);   // TC7: both negative

    @(negedge clk);
    input_driven(16'd100, 16'd50,    1'b1);   // TC8: different magnitudes

    @(negedge clk);
    input_driven(16'd255, 16'd255,   1'b1);   // TC9: large values

    @(negedge clk);
    input_driven(16'd32767, 16'd32767, 1'b1); // TC10: max positive

    // Wait some cycles
    #(10 * Clock_PERIOD);

    $stop;
end

//==================== Tasks ====================//

task initialize;
begin
    clk      = 0;
    rst_n    = 1;
    valid_in = 0;
    I_in     = 0;
    Q_in     = 0;
end
endtask

//------------------------------------------------//

task reset;
begin
    #(Clock_PERIOD);
    rst_n = 0;
    #(Clock_PERIOD);
    rst_n = 1;
end
endtask

//------------------------------------------------//

task input_driven (
    input signed [N-1:0] I,
    input signed [N-1:0] Q,
    input                in_valid
);
begin
    I_in     = I;
    Q_in     = Q;
    valid_in = in_valid;
    #(Clock_PERIOD);
end
endtask

//==================== DUT ====================//

Power_Estimator #( .N(N) ) Dut (
    .clk        (clk),
    .rst_n      (rst_n),
    .valid_in   (valid_in),
    .I_in       (I_in),
    .Q_in       (Q_in),
    .power_out  (power_out),
    .valid_out  (valid_out)
);

//==================== Clock ====================//

always begin
    #(Clock_PERIOD/2) clk = ~clk;
end

endmodule