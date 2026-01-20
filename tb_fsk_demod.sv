`timescale 1ns/1ps
module tb_fsk_demod;

  localparam IQ_BIT_WIDTH = 8;
  localparam CLK_PERIOD   = 10;
  localparam TEST_CASES   = 22;

  logic                           CLK_tb;
  logic                           RST_tb;
  logic signed [IQ_BIT_WIDTH-1:0] in_phase_i_tb;
  logic signed [IQ_BIT_WIDTH-1:0] quadrature_q_tb;
  logic                           iq_valid_tb;
  logic                           demod_signal_tb;
  logic                           demod_signal_valid_tb;

  int NUM_ERROR;
  integer i;

  // Reference signal (expected demodulation result)
  logic [TEST_CASES-1:0] demod_signal_tb_ref;

  // Instantiate DUT
  fsk_demod #(.IQ_BIT_WIDTH(IQ_BIT_WIDTH)) DUT (
    .CLK_i                (CLK_tb),
    .RST_i                (RST_tb),
    .in_phase_i_i         (in_phase_i_tb),
    .quadrature_q_i       (quadrature_q_tb),
    .iq_valid_i           (iq_valid_tb),
    .demod_signal_o       (demod_signal_tb),
    .demod_signal_valid_o (demod_signal_valid_tb)
  );

  // Clock generation
  always #(CLK_PERIOD/2) CLK_tb = ~CLK_tb;

  // Initialization
  task initialization();
  begin
    CLK_tb = 0;
    RST_tb = 0;
    in_phase_i_tb = 0;
    quadrature_q_tb = 0;
    iq_valid_tb = 0;
    NUM_ERROR = 0;
    i=0;
  end
  endtask

  // Reset
  task apply_reset();
  begin
    RST_tb = 0;
    repeat(5) @(negedge CLK_tb);
    RST_tb = 1;
  end
  endtask

  // Input stimulus
  task input_generate(input signed [IQ_BIT_WIDTH-1:0] i, input signed [IQ_BIT_WIDTH-1:0] q);
  begin
    @(negedge CLK_tb);
    iq_valid_tb = 1;
    in_phase_i_tb = i;
    quadrature_q_tb = q;
  end
  endtask

  // Output check
  task out_check();
  begin
    @(negedge CLK_tb);
    if (demod_signal_tb !== demod_signal_tb_ref[i]) begin
      NUM_ERROR++;
      $display("[%0t] Error at sample %0d: expected %b, got %b", $time, i, demod_signal_tb_ref[i], demod_signal_tb);
    end
    else
      $display("[%0t] Pass at sample %0d: expected %b, got %b", $time, i, demod_signal_tb_ref[i], demod_signal_tb);
    i=i+1;
  end
  endtask

  // Main simulation
  initial begin
    initialization();
    apply_reset();

    demod_signal_tb_ref = 22'b00_1101_1110_0001_0001_1000;

    input_generate( 50,   59);
        out_check();
    input_generate( 100,  -60);
        out_check();
    input_generate(  -1,  87);
        out_check();
    input_generate(-66,  4);
        out_check();

    input_generate(1,   99);
        out_check();
    input_generate(127, -127);
        out_check();
    input_generate(  5, -18);
        out_check();
    input_generate( 35, -35);
        out_check();

    input_generate( -50,   0);
        out_check();
    input_generate( 35,  35);
        out_check();
    input_generate(  0,  0);
        out_check();
    input_generate(76,  99);
        out_check();

    input_generate(-50,   0);
        out_check();
    input_generate(-35, -35);
        out_check();
    input_generate(  0, -50);
        out_check();
    input_generate( 35, -35);
        out_check();

    input_generate( 54,   -80);
        out_check();
    input_generate( 6,  6);
        out_check();
    input_generate(  0,  50);
        out_check();
    input_generate(20,  -35); 
        out_check();
        out_check();
        out_check();  

    $stop;
  end
  // Debug monitor
  initial begin
    $monitor("[%0t ns] I=%d Q=%d | demod=%b valid=%b", $time, in_phase_i_tb, quadrature_q_tb, demod_signal_tb, demod_signal_valid_tb);
  end
endmodule
