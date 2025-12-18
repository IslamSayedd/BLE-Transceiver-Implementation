`timescale 1ns/1ps
module VCO_tb ();

parameter OUT_WIDTH     = 12;
parameter DATA_WIDTH    = 8;
parameter OUT_SIZE      = 8;
parameter Clock_PERIOD  = 20;

reg                         reset_n;
reg                         clk;
reg  signed [OUT_WIDTH-1:0] gauss_filter_o_tb;
reg                         gaussian_filter_out_valid_o_tb;

wire [OUT_SIZE-1:0]         Quadrature_Phase_o_tb;
wire [OUT_SIZE-1:0]         In_Phase_o_tb;
wire                        Phase_Valid_o_tb;

initial begin

 // System Functions
 $dumpfile("VCO.vcd");
 $dumpvars;

 // Lookup table for sine & cosine estimate (inside IQ_Wave_Genarator inside VCO)
 $readmemh("sin_lut.txt", Dut.u_iq_wave_generator.sin_mem);
 $readmemh("cos_lut.txt", Dut.u_iq_wave_generator.cos_mem);

 initialize();

 @(negedge clk);

 reset();

 // Drive some Gaussian filter samples (signed 12-bit)
 @(negedge clk);
 input_driven( 12'sd25 , 1'b1 );

 @(negedge clk);
 input_driven( 12'sd40 , 1'b1 );

 @(negedge clk);
 input_driven( 12'sd70 , 1'b1 );

 // Example: a negative sample
 @(negedge clk);
 input_driven( -12'sd15 , 1'b1 );

@(negedge clk);
 input_driven( -12'sd200 , 1'b1 );

 // Example: gap (valid = 0)
 @(negedge clk);
 input_driven( 12'sd0 , 1'b0 );

 #(10 * Clock_PERIOD)

 $stop;

end

/////////////////////////Tasks/////////////////////////////////////

task initialize ;
 begin
  reset_n                         = 1'b1;
  clk                             = 1'b0;
  gauss_filter_o_tb                = 'b0;
  gaussian_filter_out_valid_o_tb   = 1'b0;
 end
endtask

task reset ;
 begin
  #(Clock_PERIOD)
  reset_n  = 1'b0;
  #(Clock_PERIOD)
  reset_n  = 1'b1;
 end
endtask

task input_driven (
    input signed [OUT_WIDTH-1:0] sample,
    input                        in_valid
);
 begin
  gauss_filter_o_tb              = sample;
  gaussian_filter_out_valid_o_tb = in_valid;
  #(Clock_PERIOD);
 end
endtask

//////////////////////////////DUT/////////////////////////////////

VCO #(
    .OUT_WIDTH (OUT_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .OUT_SIZE  (OUT_SIZE)
) Dut (
    .clk                        (clk),
    .reset_n                    (reset_n),
    .gauss_filter_o             (gauss_filter_o_tb),
    .gaussian_filter_out_valid_o(gaussian_filter_out_valid_o_tb),
    .Quadrature_Phase_o         (Quadrature_Phase_o_tb),
    .In_Phase_o                 (In_Phase_o_tb),
    .Phase_Valid_o              (Phase_Valid_o_tb)
);

////////////////////////clock Generation//////////////////////////

always begin
    #(Clock_PERIOD/2) clk = ~clk;
end

endmodule
