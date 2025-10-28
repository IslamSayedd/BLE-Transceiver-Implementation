`timescale 1ns/1ps
module gaussian_filter_tb ();

////////////////PARAMETERS DECLARATIONS////////////////
parameter Clock_PERIOD = 5.0 ; 
parameter WIDTH = 8; 
parameter OUT_WIDTH = WIDTH + 4;
parameter ADDRESS_WIDTH = 4 ;
parameter NUM_OF_TAPS = 8;

logic clk_tb;
logic rst_n_tb;

logic bit_upsample_valid_i_tb;
logic [WIDTH - 1 : 0] bit_upsample_i_tb;

logic [WIDTH - 1 : 0] tap_value_i_tb;
logic [ADDRESS_WIDTH - 1 : 0] tap_address_i_tb;

logic signed [OUT_WIDTH - 1  : 0] gaussian_filter_o_tb;
logic gaussian_filter_out_valid_o_tb;

///////////////MAIN INITIAL BLOCK////////////////
initial begin

    // System Functions
    $dumpfile("UART_tx.vcd") ;       
    $dumpvars; 

    //reset assertion
    assert_reset();

    //initialize
    initialize();
    #(Clock_PERIOD)

    bit_upsample_i_tb = {WIDTH{1'b1}};
    #(Clock_PERIOD)

    generate_taps();
    #(Clock_PERIOD);
    #(Clock_PERIOD);

    bit_upsample_i_tb = {WIDTH{1'b0}};
    
    #(Clock_PERIOD);
    
    
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
    end
endtask

task assert_reset;
    begin
        rst_n_tb =  1'b1;
        #(Clock_PERIOD)
        rst_n_tb  = 1'b0;
        #(Clock_PERIOD)
        rst_n_tb  = 1'b1;
    end
endtask

task generate_taps;
    begin

        bit_upsample_valid_i_tb = 1'b1;
        #(Clock_PERIOD)

        tap_address_i_tb  = 'd0;
        tap_value_i_tb    = 'd55;

        #(Clock_PERIOD)

        tap_address_i_tb = 'd1;
        tap_value_i_tb    = 'd96;

        #(Clock_PERIOD)

        tap_address_i_tb = 'd2;
        tap_value_i_tb = 'd135;

        #(Clock_PERIOD)
        tap_address_i_tb = 'd3;
        tap_value_i_tb = 'd151; 

        #(Clock_PERIOD)
        tap_address_i_tb = 'd4;
        tap_value_i_tb = 'd151;

        #(Clock_PERIOD)
        tap_address_i_tb = 'd5;
        tap_value_i_tb    = 'd135;

        #(Clock_PERIOD)
        tap_address_i_tb = 'd6;
        tap_value_i_tb    = 'd96;

        #(Clock_PERIOD)
        tap_address_i_tb = 'd7;
        tap_value_i_tb    = 'd55;
    end
endtask


////////////////CLK GENERATION////////////////
always #(Clock_PERIOD/2) clk_tb = ~ clk_tb;

////////////////MODULE INSTANTIATION////////////////
gaussian_filter #(.WIDTH(WIDTH) , .OUT_WIDTH(OUT_WIDTH) , .NUM_OF_TAPS(NUM_OF_TAPS)) DUT
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
