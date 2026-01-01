module NRZ_upsample # (parameter DATA_WIDTH = 11, 
								SAMPLE_PER_SYMBOL= 8
)(
 input   wire                         clk,
 input   wire                         rst_n,
 input   wire                         phy_bit_i,
 input   wire                         bit_valid_i, 
 output  wire   					  bit_upsample_o,
 output  wire                         		 bit_upsample_valid_o

 );

wire   			 [1 : 0]      		 NRZ_o; 
wire    		 					 NRZ_valid_o;


NRZ # (.DATA_WIDTH(DATA_WIDTH), .SAMPLE_PER_SYMBOL(SAMPLE_PER_SYMBOL)) DUT1 (
.clk(clk),
.rst_n(rst_n),
.phy_bit_i(phy_bit_i), 
.bit_valid_i(bit_valid_i),
.NRZ_o(NRZ_o), 
.NRZ_valid_o(NRZ_valid_o)
);


upsample # (.DATA_WIDTH(DATA_WIDTH), .SAMPLE_PER_SYMBOL(SAMPLE_PER_SYMBOL)) DUT2 (
.clk(clk),
.rst_n(rst_n),
.NRZ_i(NRZ_o),
.NRZ_valid_i(NRZ_valid_o),
.bit_upsample_o(bit_upsample_o), 
.bit_upsample_valid_o(bit_upsample_valid_o)

);

endmodule 