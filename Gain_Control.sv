module Gain_Control # (parameter POWER_TARGET = 33'd4294967296, //2^32= 0.5((2^33)-1)
								STEP_SIZE = 3, //(u=1/2^3=1/8)
								IN_SIZE = 33,
							 	OUT=34
)(
 input   wire                         clk,
 input   wire                         rst_n,

 input   wire             [ IN_SIZE-1 : 0 ] power_i,
 input   wire                         power_valid_i, 

 output  reg   	[ OUT-1 : 0 ]    	  gain_o,
 output  reg                      	  gain_valid_o

 );
 
 reg signed [ OUT-1 : 0 ] error; 
 reg signed	[ OUT-1 : 0 ] gain_old , gain_temp;
 reg 			 		  Done;


 always @(posedge clk or negedge rst_n) 
 begin 
 	if(~rst_n) 
 		begin

 			gain_o <= 'b0;
 			gain_valid_o <= 'b0;
 			error <='b0;
			gain_temp <= 'b0;
			Done <='b0;
			gain_old <='b0;

 		end 

 	else if(Done) 
 		begin

 			gain_o <= gain_temp;
 			gain_valid_o <= Done;
 			gain_old <= gain_temp ;
 	
 		end
 	else
 		gain_valid_o <= 'b0;
 end

always @(*) begin 
	if(power_valid_i) 
		begin

			error = $signed({1'b0,POWER_TARGET}) - $signed({1'b0,power_i});
 			gain_temp = gain_old + (error >>> STEP_SIZE) ; //Arithmatic shift preserve the sign
 			Done ='b1;

		end 
	else 
		begin

		 	Done = 'b0; 
		 	gain_temp = gain_old;

		end
end

endmodule
