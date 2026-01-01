`timescale 1ns/1ps

module NRZ_tb # ( parameter DATA_WIDTH = 11 ,  SAMPLE_PER_SYMBOL = 8 )();
 reg                          rst_n;
 reg                          clk;
 reg          		          phy_bit_i_tb;
 reg                          bit_valid_i_tb;
 wire		  [1:0]     	  NRZ_o_tb;
 wire                         NRZ_valid_o_tb;

parameter Clock_PERIOD = 20 ;


initial 
 begin
 
 // System Functions
 $dumpfile("upsample_DUMP.vcd") ;       
 $dumpvars; 

 initialize() ;
 @(negedge clk);
 reset();


 @(negedge clk);
 take_input ('b10100010101);


 
 @(negedge clk);
 take_input ('b01001011010);
 





#(30 * Clock_PERIOD)

 $stop;
end

NRZ #(.DATA_WIDTH(DATA_WIDTH),
		  .SAMPLE_PER_SYMBOL(SAMPLE_PER_SYMBOL)) DUT (
		  .clk(clk),
		  .rst_n(rst_n),
		  .phy_bit_i(phy_bit_i_tb),
		  .bit_valid_i(bit_valid_i_tb),
		  .NRZ_o(NRZ_o_tb),
		  .NRZ_valid_o(NRZ_valid_o_tb)
		  );

task initialize ;
 begin
  rst_n  	 = 'b1;
  clk        = 'b0;
  phy_bit_i_tb = 'b0;
  bit_valid_i_tb = 'b0;

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

task take_input (input [DATA_WIDTH + 2 : 0] in);
	integer i;
begin
	for(i=0; i< DATA_WIDTH  ; i=i+1) begin
		phy_bit_i_tb = in[i];
		bit_valid_i_tb ='b1;
		#(Clock_PERIOD);
	end
	//bit_valid_i_tb = 'b0;
	#(Clock_PERIOD);
end
endtask

always begin
	 #(Clock_PERIOD/2)  clk = ~ clk ;
end


endmodule