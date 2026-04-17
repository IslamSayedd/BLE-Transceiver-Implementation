`timescale 1ns/1ps

module tb_log10_32bits;

    parameter WIDTH = 32;
    parameter FRAC_BITS = 8;

    reg clk;
    reg rst;
    reg valid_in;
    reg [WIDTH-1:0] avg_power;

    wire [15:0] rssi_out;
    wire valid_out;

    // DUT
    log10_32bits dut (
        .clk(clk),
        .rst(rst),
        .valid_in_i(valid_in),
        .avg_power_i(avg_power),
        .rssi_out_o(rssi_out),
        .valid_out_o(valid_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reference model (real math)
    real real_rssi;
    real expected;

    function real calc_rssi(input longint unsigned x);
        real tmp;
        begin
            if (x == 0)
                x = 1;
            tmp = 10.0 * $log10(x);
            return tmp;
        end
    endfunction

    // Test
    longint unsigned i;

    initial begin
        clk = 0;
        rst = 0;
        valid_in = 0;
        avg_power = 0;

        // Reset
        #20;
        rst = 1;

        // Wait
        #20;

        // Apply test vectors
        for (i = 1; i <= 32'hFFFFFFF; i = i * 2) begin
            @(posedge clk);

            avg_power = i;
            valid_in = 1;

            @(posedge clk);
            valid_in = 0;

            // Wait for output
            @(posedge clk);

            if (valid_out) begin
                expected = calc_rssi(i);

                // convert fixed-point Q8.8 → real
                real_rssi = rssi_out / 256.0;

                $display("Input=%0d | HW=%0f dB | REF=%0f dB | ERROR=%0f",
                          i, real_rssi, expected, real_rssi - expected);
            end
        end

        // Edge cases
        test_case(0);
        test_case(1);
        test_case(2);
        test_case(1024);
        test_case(65535);
        test_case(32'hFFFFFFFF);

        #100;
        $finish;
    end

    // Task for test
    task test_case(input longint unsigned val);
        begin
            @(posedge clk);
            avg_power = val;
            valid_in = 1;

            @(posedge clk);
            valid_in = 0;

            @(posedge clk);

            if (valid_out) begin
                expected = calc_rssi(val);
                real_rssi = rssi_out / 256.0;

                $display("TEST | Input=%0d | HW=%0f | REF=%0f | ERROR=%0f",
                          val, real_rssi, expected, real_rssi - expected);
            end
        end
    endtask

endmodule
