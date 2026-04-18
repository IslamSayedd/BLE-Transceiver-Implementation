module RSSI_TOP #(

    // Power Estimator
    parameter N                   = 16,

    // Average Filter
    parameter DATA_WIDTH          = 32,
    parameter N_LOG2              = 4,

    // Log block
    parameter WIDTH               = 32,
    parameter NO_BITS             = 5,
    parameter FRAC_BITS           = 8,

    // RSSI Threshold (to be calibrated)
    parameter RSSI_THRESHOLD      = 16'd1843   // <-- adjust to represent -70 dBm

)(
    // Global signals
    input  wire                         clk,
    input  wire                         rst_n,

    // Input I/Q
    input  wire                         valid_i,
    input  wire signed [N-1:0]          I_in,
    input  wire signed [N-1:0]          Q_in,

    // Outputs
    output wire [15:0]                  rssi_out_o,
    output wire                         rssi_valid_o,
    output reg                          signal_flag_o   // 1 = strong, 0 = weak
);

    //==========================================================================
    // Internal Signals
    //==========================================================================

    // Power Estimator → Avg Filter
    wire [2*N-1:0]          power_out;
    wire                    power_valid;

    // Avg Filter → Log
    wire [DATA_WIDTH-1:0]   avg_power;
    wire                    avg_valid;

    // Log → Output
    wire [15:0]             rssi_out;
    wire                    rssi_valid;

    //==========================================================================
    // Module Instantiations
    //==========================================================================

    // Stage 1: Power Estimation (I^2 + Q^2)
    Power_Estimator #(
        .N (N)
    ) u_power_estimator (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_i),
        .I_in       (I_in),
        .Q_in       (Q_in),
        .power_out  (power_out),
        .valid_out  (power_valid)
    );

    // Stage 2: Averaging Filter
    avgerage_filter #(
        .DATA_WIDTH (DATA_WIDTH),
        .N_LOG2     (N_LOG2)
    ) u_avg_filter (
        .clk            (clk),
        .rst            (rst_n),
        .valid_in_i     (power_valid),
        .data_in_i      (power_out),
        .avg_out_o      (avg_power),
        .valid_out_o    (avg_valid)
    );

    // Stage 3: Log10 (RSSI Calculation)
    log10_32bits #(
        .WIDTH      (WIDTH),
        .NO_BITS    (NO_BITS),
        .FRAC_BITS  (FRAC_BITS)
    ) u_log10 (
        .clk            (clk),
        .rst            (rst_n),
        .valid_in_i     (avg_valid),
        .avg_power_i    (avg_power),
        .rssi_out_o     (rssi_out),
        .valid_out_o    (rssi_valid)
    );

    //==========================================================================
    // Output Assignments
    //==========================================================================

    assign rssi_out_o   = rssi_out;
    assign rssi_valid_o = rssi_valid;

    //==========================================================================
    // Signal Strength Flag Logic
    //==========================================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_flag_o <= 1'b0;
        end
        else if (rssi_valid) begin
            // Compare with threshold (-70 dBm equivalent)
            if (rssi_out >= RSSI_THRESHOLD)
                signal_flag_o <= 1'b1;   // Strong signal
            else
                signal_flag_o <= 1'b0;   // Weak signal
        end
    end

endmodule