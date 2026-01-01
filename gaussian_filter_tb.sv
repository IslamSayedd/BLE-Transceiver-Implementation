`timescale 1ns/1ps
module gaussian_filter_tb ();

////////////////PARAMETERS DECLARATIONS////////////////
parameter CLOCK_PERIOD = 5.0 ; 

parameter TAP_WIDTH = 16 ; 
parameter OUT_WIDTH = 16 ; 
parameter ADDRESS_WIDTH = 4 ;
parameter NUM_OF_TAPS = 9 ;

////////////////SIGNALS DECLARATIONS////////////////
logic clk_tb;
logic rst_n_tb;

logic bit_upsample_valid_i_tb;
logic bit_upsample_i_tb;

logic [TAP_WIDTH - 1 : 0] tap_value_i_tb;
logic [ADDRESS_WIDTH - 1 : 0] tap_address_i_tb;

logic signed [OUT_WIDTH - 1  : 0] gaussian_filter_o_tb;
logic gaussian_filter_out_valid_o_tb;

////////////////MEMS DECLARATIONS////////////////
logic [TAP_WIDTH - 1 : 0] taps [NUM_OF_TAPS - 1 : 0];

////////////////Golden Model Signals////////////////
logic signed [TAP_WIDTH : 0] mapped_value_tb ;
logic signed [OUT_WIDTH - 1  : 0] golden_out;

///////////////MAIN INITIAL BLOCK////////////////
initial begin

    // System Functions
    $dumpfile("gaussian_filter.vcd") ;       
    $dumpvars; 

    // Read Input Files
    $readmemh("taps.txt", taps);

    //reset assertion
    assert_reset();
    #(CLOCK_PERIOD)

    //initialize
    initialize();
    #(CLOCK_PERIOD)

    //Load Taps
    
    do_oper();
    #(CLOCK_PERIOD)

    generate_upsample_inputs(1'b1);

    generate_upsample_inputs(1'b1);

    generate_upsample_inputs(1'b0);

    generate_upsample_inputs(1'b0);

    bit_upsample_valid_i_tb = 'b0;

    
    #50
    $stop;
    
end

////////////////TASKS////////////////
task initialize;
    begin
        clk_tb = 0;
        bit_upsample_valid_i_tb = 'd0;
        bit_upsample_i_tb = 'd0;
        tap_value_i_tb = 'd0;
        tap_address_i_tb = 'd0;
        golden_out = 'd0;
        mapped_value_tb = 'd0;
    end
endtask

task assert_reset;
    begin
        rst_n_tb =  1'b1;
        #(CLOCK_PERIOD)
        rst_n_tb  = 1'b0;
        #(CLOCK_PERIOD)
        rst_n_tb  = 1'b1;
    end
endtask

task do_oper;
    integer j;
    begin
        for (j = 0; j < NUM_OF_TAPS; j = j + 1) begin
            tap_address_i_tb = j;
            tap_value_i_tb = taps[j];
            #(CLOCK_PERIOD);
        end
    end
endtask

task generate_upsample_inputs(input logic value);
    begin
        bit_upsample_valid_i_tb = 'b1;
        if (value) begin
            bit_upsample_i_tb = 1'b1;
            #(CLOCK_PERIOD);
            bit_upsample_i_tb = 1'b1;
            #(CLOCK_PERIOD);
            bit_upsample_i_tb = 1'b1;
            #(CLOCK_PERIOD);
            bit_upsample_i_tb = 1'b1;
            #(CLOCK_PERIOD);
            bit_upsample_i_tb = 1'b1;
            #(CLOCK_PERIOD);
            bit_upsample_i_tb = 1'b1;
            #(CLOCK_PERIOD);
            bit_upsample_i_tb = 1'b1;
            #(CLOCK_PERIOD);
            bit_upsample_i_tb = 1'b1;
            #(CLOCK_PERIOD);
        end 
        else begin
            bit_upsample_i_tb = 1'b0;
            #(CLOCK_PERIOD)
            bit_upsample_i_tb = 1'b0;
            #(CLOCK_PERIOD)
            bit_upsample_i_tb = 1'b0;
            #(CLOCK_PERIOD)
            bit_upsample_i_tb = 1'b0;
            #(CLOCK_PERIOD)
            bit_upsample_i_tb = 1'b0;
            #(CLOCK_PERIOD)
            bit_upsample_i_tb = 1'b0;
            #(CLOCK_PERIOD)
            bit_upsample_i_tb = 1'b0;
            #(CLOCK_PERIOD)
            bit_upsample_i_tb = 1'b0;
            #(CLOCK_PERIOD);
        end
    end
endtask

////////////////CLK GENERATION////////////////
always #(CLOCK_PERIOD/2) clk_tb = ~ clk_tb;

////////////////MODULE INSTANTIATION////////////////
gaussian_filter #(.TAP_WIDTH(TAP_WIDTH) , .OUT_WIDTH(OUT_WIDTH) , .NUM_OF_TAPS(NUM_OF_TAPS) , .ADDRESS_WIDTH(ADDRESS_WIDTH)) 
DUT
( 
    .clk(clk_tb), 
    .rst_n(rst_n_tb) , 
    .bit_upsample_valid_i(bit_upsample_valid_i_tb),
    .bit_upsample_i(bit_upsample_i_tb),
    .tap_value_i(tap_value_i_tb),
    .tap_address_i(tap_address_i_tb),
    .gaussian_filter_o(gaussian_filter_o_tb),
    .gaussian_filter_out_valid_o(gaussian_filter_out_valid_o_tb)
);
endmodule