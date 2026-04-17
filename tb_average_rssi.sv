`timescale 1ns/1ps

module tb_average_rssi;

    parameter DATA_WIDTH = 16;
    parameter N_LOG2     = 4;
    parameter N          = (1 << N_LOG2);

    reg clk_tb;
    reg rst_tb;
    reg valid_in_tb;
    reg [DATA_WIDTH-1:0] data_in_tb;

    wire [DATA_WIDTH-1:0] avg_out_tb;
    wire valid_out_tb;

    reg [DATA_WIDTH-1:0] sample_history [0:N-1];
    integer wr_ptr_ref;
    integer sample_count;
    integer running_sum;
    integer expected_avg;
    integer i;
    integer pass;
    integer fail;

    avgerage_rssi #(
        .DATA_WIDTH(DATA_WIDTH),
        .N_LOG2(N_LOG2)
    ) dut (
        .clk(clk_tb),
        .rst(rst_tb),
        .valid_in_i(valid_in_tb),
        .data_in_i(data_in_tb),
        .avg_out_o(avg_out_tb),
        .valid_out_o(valid_out_tb)
    );

    always #5 clk_tb = ~clk_tb;

    initial begin
        clk_tb      = 0;
        rst_tb      = 0;
        valid_in_tb = 0;
        data_in_tb  = 0;
        wr_ptr_ref  = 0;
        sample_count = 0;
        running_sum = 0;
        pass = 0;
        fail = 0;

        for (i = 0; i < N; i = i + 1)
            sample_history[i] = 0;

        #15;
        rst_tb = 1;

        send_and_check(120);
        send_and_check(789);
        send_and_check(265);
        send_and_check(12);
        send_and_check(925);
        send_and_check(931);
        send_and_check(182);
        send_and_check(1478);
        send_and_check(14862);
        send_and_check(47862);
        send_and_check(4632);
        send_and_check(120);
        send_and_check(369);
        send_and_check(564);
        send_and_check(14586);
        send_and_check(4811);
        send_and_check(784);
        send_and_check(8945);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(65535);
        send_and_check(120);
        send_and_check(120);
        
        $display("TEST FINISHED: %0d passed, %0d failed", pass, fail);
        if (fail != 0)
            $fatal(1, "Average filter test failed");

        $finish;
    end

    task send_and_check(input [DATA_WIDTH-1:0] sample);
        begin
            @(negedge clk_tb);
            valid_in_tb = 1'b1;
            data_in_tb  = sample;

            @(posedge clk_tb);

            running_sum = running_sum - sample_history[wr_ptr_ref] + sample;
            sample_history[wr_ptr_ref] = sample;
            wr_ptr_ref = (wr_ptr_ref + 1) % N;
            if (sample_count < N)
                sample_count = sample_count + 1;

            expected_avg = running_sum >> N_LOG2;

            @(negedge clk_tb);
            valid_in_tb = 1'b0;
            data_in_tb  = '0;

            @(posedge clk_tb);

            if (!valid_out_tb) begin
                fail = fail + 1;
                $display("FAIL: valid_out_tb was low for sample %0d", sample);
            end else if (avg_out_tb !== expected_avg[DATA_WIDTH-1:0]) begin
                fail = fail + 1;
                $display("FAIL: sample=%0d expected=%0d got=%0d", sample, expected_avg, avg_out_tb);
            end else begin
                pass = pass + 1;
                $display("PASS: sample=%0d avg=%0d", sample, avg_out_tb);
            end
        end
    endtask

endmodule
