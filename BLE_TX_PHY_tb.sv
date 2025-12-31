`timescale 1ns/1ps

module BLE_TX_PHY_tb ();

    //==========================================================================
    // Parameters
    //==========================================================================
    // NRZ Upsample parameters
    parameter NRZ_DATA_WIDTH       = 11;
    parameter SAMPLE_PER_SYMBOL    = 8;
    
    // Gaussian Filter parameters
    parameter TAP_WIDTH            = 16;
    parameter GAUS_OUT_WIDTH       = 16;
    parameter ADDRESS_WIDTH        = 4;
    parameter NUM_OF_TAPS          = 9;
    
    // VCO parameters
    parameter VCO_OUT_WIDTH        = 16;
    parameter VCO_DATA_WIDTH       = 16;
    parameter VCO_OUT_SIZE         = 16;
    
    // Testbench parameters
    parameter Clock_PERIOD         = 20;  // 50 MHz
    
    //==========================================================================
    // Testbench Signals
    //==========================================================================
    reg                             clk;
    reg                             rst_n;
    reg                             phy_bit_i_tb;
    reg                             bit_valid_i_tb;
    reg  [TAP_WIDTH - 1 : 0]        tap_value_i_tb;
    reg  [ADDRESS_WIDTH - 1 : 0]    tap_address_i_tb;
    
    wire [VCO_OUT_SIZE - 1 : 0]     Quadrature_Phase_o_tb;
    wire [VCO_OUT_SIZE - 1 : 0]     In_Phase_o_tb;
    wire                            Phase_Valid_o_tb;
    
    // Test pattern storage
    reg [NRZ_DATA_WIDTH-1:0]        test_message;
    integer                         bit_index;

    logic [TAP_WIDTH - 1 : 0] taps [NUM_OF_TAPS - 1 : 0];
    
    //==========================================================================
    // Initial Block
    //==========================================================================
    initial begin
        // System Functions
        $dumpfile("BLE_Transmitter.vcd");
        $dumpvars;
        
        // Load LUT tables for VCO (sin/cos lookup tables)
        $readmemh("sin_lut.txt", DUT.u_vco.u_iq_wave_generator.sin_mem);
        $readmemh("cos_lut.txt", DUT.u_vco.u_iq_wave_generator.cos_mem);
        
        // Load Gaussian filter taps from file
        //$readmemh("taps.txt", DUT.u_gaussian_filter.store_taps);
        $readmemh("taps.txt", taps);
        
        initialize();
        
        @(negedge clk);
        reset();

        repeat(5) @(negedge clk);
        do_oper();
        
        // Wait for stable state
        repeat(5) @(negedge clk);
        
        //======================================================================
        // Test Case 1: Alternating Pattern (Maximum Frequency Transitions)
        //======================================================================
        $display("\n========================================");
        $display("Test Case 1: Alternating Pattern");
        $display("Message: 0b10101010101");
        $display("========================================");
        
        test_message = 11'b10101010101;
        send_message(test_message);
        
        // Wait for pipeline to flush
        repeat(100) @(negedge clk);
        
        //======================================================================
        // Test Case 2: All Ones (Maximum Positive Frequency Deviation)
        //======================================================================
        $display("\n========================================");
        $display("Test Case 2: All Ones");
        $display("Message: 0b11111111111");
        $display("========================================");
        
        test_message = 11'b11111111111;
        send_message(test_message);
        
        // Wait for pipeline to flush
        repeat(100) @(negedge clk);
        
        //======================================================================
        // Test Case 3: Preamble Pattern (Realistic BLE Sequence)
        //======================================================================
        $display("\n========================================");
        $display("Test Case 3: Preamble-like Pattern");
        $display("Message: 0b00111100110");
        $display("========================================");
        
        test_message = 11'b00111100110;
        send_message(test_message);
        
        // Wait for all samples to propagate through pipeline
        repeat(150) @(negedge clk);
        
        $display("\n========================================");
        $display("All Test Cases Completed");
        $display("========================================");
        
        $stop;
    end
    
    //==========================================================================
    // Tasks
    //==========================================================================
    
    // Initialize all signals
    task initialize;
        begin
            rst_n           = 1'b1;
            clk             = 1'b0;
            phy_bit_i_tb    = 1'b0;
            bit_valid_i_tb  = 1'b0;
            tap_value_i_tb  = 'b0;
            tap_address_i_tb = 'b0;
            test_message    = 'b0;
            bit_index       = 0;
        end
    endtask
    
    // Reset sequence
    task reset;
        begin
            #(Clock_PERIOD)
            rst_n = 1'b0;
            #(Clock_PERIOD)
            rst_n = 1'b1;
            $display("[%0t] Reset completed", $time);
        end
    endtask
    
    // Send an 11-bit message
    task send_message;
        input [NRZ_DATA_WIDTH-1:0] message;
        integer i;
        begin
            $display("[%0t] Sending message: 0b%b", $time, message);
            
            for (i = NRZ_DATA_WIDTH-1; i >= 0; i = i - 1) begin
                @(negedge clk);
                phy_bit_i_tb   = message[i];
                bit_valid_i_tb = 1'b1;
                $display("  [%0t] Bit[%0d] = %b", $time, (NRZ_DATA_WIDTH-1-i), message[i]);
            end
            
            // Deassert valid after message
            @(negedge clk);
            phy_bit_i_tb   = 1'b0;
            bit_valid_i_tb = 1'b0;
            
            $display("[%0t] Message transmission complete", $time);
        end
    endtask
    
    // Drive single bit (alternative granular control)
    task send_bit;
        input bit_value;
        input valid;
        begin
            phy_bit_i_tb   = bit_value;
            bit_valid_i_tb = valid;
        end
    endtask
    
    //==========================================================================
    // DUT Instantiation
    //==========================================================================
    BLE_TX_PHY #(
        .NRZ_DATA_WIDTH     (NRZ_DATA_WIDTH),
        .SAMPLE_PER_SYMBOL  (SAMPLE_PER_SYMBOL),
        .TAP_WIDTH          (TAP_WIDTH),
        .GAUS_OUT_WIDTH     (GAUS_OUT_WIDTH),
        .ADDRESS_WIDTH      (ADDRESS_WIDTH),
        .NUM_OF_TAPS        (NUM_OF_TAPS),
        .VCO_OUT_WIDTH      (VCO_OUT_WIDTH),
        .VCO_DATA_WIDTH     (VCO_DATA_WIDTH),
        .VCO_OUT_SIZE       (VCO_OUT_SIZE)
    ) DUT (
        .clk                (clk),
        .rst_n              (rst_n),
        .phy_bit_i          (phy_bit_i_tb),
        .bit_valid_i        (bit_valid_i_tb),
        .tap_value_i        (tap_value_i_tb),
        .tap_address_i      (tap_address_i_tb),
        .Quadrature_Phase_o (Quadrature_Phase_o_tb),
        .In_Phase_o         (In_Phase_o_tb),
        .Phase_Valid_o      (Phase_Valid_o_tb)
    );
    
    //==========================================================================
    // Clock Generation
    //==========================================================================
    always begin
        #(Clock_PERIOD/2) clk = ~clk;
    end
    
    //==========================================================================
    // Monitoring (Optional - for debugging)
    //==========================================================================
    always @(posedge clk) begin
        if (Phase_Valid_o_tb) begin
            $display("[%0t] I/Q Output: I=0x%h, Q=0x%h", 
                     $time, In_Phase_o_tb, Quadrature_Phase_o_tb);
        end
    end

task do_oper;
    integer j;
    begin
        for (j = 0; j < NUM_OF_TAPS; j = j + 1) begin
            tap_address_i_tb = j;
            tap_value_i_tb = taps[j];
            #(Clock_PERIOD);
        end
    end
endtask

endmodule