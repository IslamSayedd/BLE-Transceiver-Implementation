`timescale 1ns/1ps
module IQ_Wave_Genarator_tb ();

parameter DATA_WIDTH 	= 8		;
parameter OUT_SIZE 		= 8		;
parameter Clock_PERIOD 	= 20 	;


reg 	 					rst_n					;
reg 						clk						;
reg 	[DATA_WIDTH-1 : 0]	Phase_index_i_tb		;
reg							phase_valid_i_tb		;

wire	[OUT_SIZE-1 : 0]	Quadrature_Phase_o_tb 	;
wire	[OUT_SIZE-1 : 0]	In_Phase_o_tb			;
wire						Phase_Valid_o_tb		;


initial begin

 // System Functions
 $dumpfile("IQ_PHASE.vcd") ;       
 $dumpvars; 

//Lookup table for sine & cosine estimate
 $readmemh("sin_lut.txt", Dut.sin_mem);
 $readmemh("cos_lut.txt", Dut.cos_mem);

 initialize() ;

 @(negedge clk);

 reset();

 @(negedge clk);
 input_driven( 'd36 , 1'b1 );

 @(negedge clk);
 input_driven('d42 , 1'b1);

 #(10 * Clock_PERIOD)

 $stop;

end

/////////////////////////Tasks/////////////////////////////////////

task initialize ;
 begin
  rst_n  	 		= 'b1;
  clk        		= 'b0;
  phase_valid_i_tb 	= 'b0;
  Phase_index_i_tb 	= 'b0;

 end
 endtask

 task reset ;
 begin
  #(Clock_PERIOD)
  rst_n  = 'b0;
  #(Clock_PERIOD)
  rst_n  = 'b1;
 end
endtask

task input_driven (	input [DATA_WIDTH -1 : 0] 	phase 		,
					input 						in_valid 	);
	begin
		Phase_index_i_tb	 = 	phase 		;
		phase_valid_i_tb	 =	in_valid	;	
		#(Clock_PERIOD);
	end
endtask

//////////////////////////////DUT/////////////////////////////////

IQ_Wave_Genarator #( .DATA_WIDTH(DATA_WIDTH) , .OUT_SIZE(OUT_SIZE) ) Dut (

	.clk(clk),
	.rst_n(rst_n),
	.phase_valid_i(phase_valid_i_tb),
	.Phase_index_i(Phase_index_i_tb),
	.Quadrature_Phase_o(Quadrature_Phase_o_tb),
	.In_Phase_o(In_Phase_o_tb),
	.Phase_Valid_o(Phase_Valid_o_tb)

	);


////////////////////////clock Generation//////////////////////////

always begin
	 #(Clock_PERIOD/2)  clk = ~ clk ;
end


endmodule