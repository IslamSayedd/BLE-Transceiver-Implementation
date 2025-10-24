module IQ_Wave_Genarator #(parameter DATA_WIDTH = 8 , OUT_SIZE = 8) (

input	wire							clk					,
input	wire							rst_n				,
input	wire	[DATA_WIDTH-1 : 0]		Phase_index_i		,
input	wire							phase_valid_i		,

output	reg		[OUT_SIZE-1 : 0]		Quadrature_Phase_o	,	//  sin (phase)
output	reg		[OUT_SIZE-1 : 0]		In_Phase_o			,	//  cos (phase)
output	reg								Phase_Valid_o		

	);

reg [ OUT_SIZE-1 : 0 ] sin_mem [ (1 << DATA_WIDTH) - 1 : 0 ];  //memory to get sin estimate values from loookup table
reg [ OUT_SIZE-1 : 0 ] cos_mem [ (1 << DATA_WIDTH) - 1 : 0 ];  //memory to get cos estimate values from loookup table

always @(posedge clk or negedge rst_n) 
	begin
		if (!rst_n) 
			begin
				Quadrature_Phase_o	<= 'b0	;
				In_Phase_o			<= 'b0	;
				Phase_Valid_o		<= 'b0	;
			end
		else if (phase_valid_i) 
			begin
				Quadrature_Phase_o	<= sin_mem [Phase_index_i]	;
				In_Phase_o			<= cos_mem [Phase_index_i]	;
				Phase_Valid_o		<= 1'b1	;
			end
		else 
			begin
				Phase_Valid_o		<= 1'b0	;
			end	
	end








endmodule