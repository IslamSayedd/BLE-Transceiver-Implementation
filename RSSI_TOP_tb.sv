`timescale 1ns/1ps
module RSSI_TOP_tb ();

parameter N              = 16;
parameter Clock_PERIOD   = 20;

// Inputs
reg                     clk;
reg                     rst_n;
reg                     valid_i;
reg signed [N-1:0]      I_in;
reg signed [N-1:0]      Q_in;

// Outputs
wire [15:0]             rssi_out_o;
wire                    rssi_valid_o;
wire                    signal_flag_o;

// DUT
RSSI_TOP DUT (
    .clk            (clk),
    .rst_n          (rst_n),
    .valid_i        (valid_i),
    .I_in           (I_in),
    .Q_in           (Q_in),
    .rssi_out_o     (rssi_out_o),
    .rssi_valid_o   (rssi_valid_o),
    .signal_flag_o  (signal_flag_o)
);

//==============================================================
// Initial Block
//==============================================================

initial begin

    initialize();

    @(negedge clk);
    reset();

    // ===========================
    // Testcases
    // ===========================
    // TC1: No signal
    drive_input(0, 0, 1);

    // TC2: Very weak signal
    drive_input(20, 20, 1);

    // TC3: Weak signal near threshold
    drive_input(800, 800, 1);

     // TC: Strong signal
    drive_input(8, 7, 1);

    // TC4: Around threshold (~ -70 dBm)
    drive_input(1000, 1000, 1);

    // TC5: Slightly above threshold
    drive_input(1300, 1300, 1);

    // TC6: Medium signal
    drive_input(3000, 3000, 1);

    // TC7: Strong signal
    drive_input(8000, 8000, 1);

    // TC8: Negative I/Q values (same power)
    drive_input(-3000, -3000, 1);

    #(20 * Clock_PERIOD);

    $stop;
end

//==============================================================
// Tasks
//==============================================================

task initialize;
begin
    clk     = 0;
    rst_n   = 1;
    valid_i = 0;
    I_in    = 0;
    Q_in    = 0;
end
endtask

task reset;
begin
    #(Clock_PERIOD);
    rst_n = 0;
    #(Clock_PERIOD);
    rst_n = 1;
end
endtask

task drive_input (
    input signed [N-1:0] I_val,
    input signed [N-1:0] Q_val,
    input                valid
);
    begin
          @(posedge clk);
        I_in    = I_val;
        Q_in    = Q_val;
        valid_i = valid;
        @(negedge clk);

        $display("I=%d Q=%d --> RSSI=%d FLAG=%b", I_val, Q_val, rssi_out_o, signal_flag_o);
    end
endtask

//==============================================================
// Clock
//==============================================================

always #(Clock_PERIOD/2) clk = ~clk;

endmodule
