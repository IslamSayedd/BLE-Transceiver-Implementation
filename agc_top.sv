module agc_top #(
    parameter IQ_WIDTH      = 12,               // TX/RX native width
    parameter AGC_IQ_WIDTH  = 16,               // Internal AGC width
    parameter AVG_LOG2      = 4,
    parameter POWER_TARGET  = 33'd4294967296,  // 2^32
    parameter STEP_SIZE     = 3,

    parameter POWER_WIDTH   = 2*AGC_IQ_WIDTH,
    parameter GAIN_WIDTH    = POWER_WIDTH + 1
)(
    input  wire                        clk,
    input  wire                        rst_n,

    // IQ baseband input
    input  wire                        valid_in_i,
    input  wire signed [IQ_WIDTH-1:0]  I_in_i,
    input  wire signed [IQ_WIDTH-1:0]  Q_in_i,

    // Corrected IQ output
    output reg  signed [IQ_WIDTH-1:0]  I_out_o,
    output reg  signed [IQ_WIDTH-1:0]  Q_out_o,
    output reg                         valid_out_o
);

    /////////////////////////////////////////////
    //////////////Internal signals//////////////
    /////////////////////////////////////////////

    wire [GAIN_WIDTH-1:0] gain_o;
    wire                  gain_valid_o;

    // Sign-extended inputs
    wire signed [AGC_IQ_WIDTH-1:0] I_ext;
    wire signed [AGC_IQ_WIDTH-1:0] Q_ext;

    assign I_ext = $signed({
                    {(AGC_IQ_WIDTH-IQ_WIDTH){I_in_i[IQ_WIDTH-1]}},
                    I_in_i
                  });

    assign Q_ext = $signed({
                    {(AGC_IQ_WIDTH-IQ_WIDTH){Q_in_i[IQ_WIDTH-1]}},
                    Q_in_i
                  });

    // Power estimator outputs
    wire [POWER_WIDTH-1:0] raw_power_w;
    wire                   raw_power_valid_w;

    // Average filter outputs
    wire [POWER_WIDTH-1:0] avg_power_w;
    wire                   avg_power_valid_w;

    /////////////////////////////////////////////
    ///////////// Gain application //////////////
    /////////////////////////////////////////////

    // Product width:
    // IQ_WIDTH x (GAIN_WIDTH+1)
    wire signed [IQ_WIDTH + GAIN_WIDTH - 1 : 0] I_product;
    wire signed [IQ_WIDTH + GAIN_WIDTH - 1 : 0] Q_product;

    reg signed [IQ_WIDTH-1:0] I_gained;
    reg signed [IQ_WIDTH-1:0] Q_gained;

    wire signed [IQ_WIDTH-1:0] I_clipped;
    wire signed [IQ_WIDTH-1:0] Q_clipped;

    // 12-bit signed clipping limits
    localparam signed [IQ_WIDTH-1:0] CLIP_MAX =
        {1'b0, {(IQ_WIDTH-1){1'b1}}};

    localparam signed [IQ_WIDTH-1:0] CLIP_MIN =
        {1'b1, {(IQ_WIDTH-1){1'b0}}};

    ////////////////////////////////////////////
    //////////////Power Estimator///////////////
    ////////////////////////////////////////////

    Power_Estimator #(
        .N (AGC_IQ_WIDTH)
    ) u_power_estimator (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_in_i),
        .I_in       (I_ext),
        .Q_in       (Q_ext),
        .power_out  (raw_power_w),
        .valid_out  (raw_power_valid_w)
    );

    ////////////////////////////////////////////
    ///////////////Average Filter///////////////
    ////////////////////////////////////////////

    avgerage_filter #(
        .DATA_WIDTH (POWER_WIDTH),
        .N_LOG2     (AVG_LOG2)
    ) u_avg_filter (
        .clk         (clk),
        .rst         (rst_n),
        .valid_in_i  (raw_power_valid_w),
        .data_in_i   (raw_power_w),
        .avg_out_o   (avg_power_w),
        .valid_out_o (avg_power_valid_w)
    );

    ////////////////////////////////////////////
    ////////////////Gain Control////////////////
    ////////////////////////////////////////////

    Gain_Control #(
        .POWER_TARGET (POWER_TARGET),
        .STEP_SIZE    (STEP_SIZE),
        .IN_SIZE      (POWER_WIDTH),
        .OUT          (GAIN_WIDTH)
    ) u_gain_control (
        .clk           (clk),
        .rst_n         (rst_n),
        .power_i       (avg_power_w),
        .power_valid_i (avg_power_valid_w),
        .gain_o        (gain_o),
        .gain_valid_o  (gain_valid_o)
    );

    ////////////////////////////////////////////
    ////////////// Apply Gain //////////////////
    ////////////////////////////////////////////

    // Multiply signed IQ by gain
    assign I_product = $signed(I_in_i) *
                       $signed({1'b0, gain_o});

    assign Q_product = $signed(Q_in_i) *
                       $signed({1'b0, gain_o});

    // Scale back from Q8 format
    always @(*) begin
        I_gained = $signed(I_product >>> 8);
        Q_gained = $signed(Q_product >>> 8);
    end

    ////////////////////////////////////////////
    ////////////////// Clipping ////////////////
    ////////////////////////////////////////////

    assign I_clipped =
        ($signed(I_gained) > $signed(CLIP_MAX)) ? CLIP_MAX :
        ($signed(I_gained) < $signed(CLIP_MIN)) ? CLIP_MIN :
        I_gained;

    assign Q_clipped =
        ($signed(Q_gained) > $signed(CLIP_MAX)) ? CLIP_MAX :
        ($signed(Q_gained) < $signed(CLIP_MIN)) ? CLIP_MIN :
        Q_gained;

    ////////////////////////////////////////////
    ////////////// Output Register /////////////
    ////////////////////////////////////////////

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            I_out_o     <= '0;
            Q_out_o     <= '0;
            valid_out_o <= 1'b0;
        end
        else begin
            I_out_o     <= I_clipped;
            Q_out_o     <= Q_clipped;
            valid_out_o <= valid_in_i & gain_valid_o;
        end
    end

endmodule