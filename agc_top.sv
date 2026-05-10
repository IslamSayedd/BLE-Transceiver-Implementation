module agc_top #(
    parameter IQ_WIDTH      = 12,               // TX/RX native width (12-bit)
    parameter AGC_IQ_WIDTH  = 16,               // Internal AGC width for math precision
    parameter AVG_LOG2      = 4,   
    parameter POWER_TARGET  = 33'd4294967296,   // 2^32
    parameter STEP_SIZE     = 3,
    parameter POWER_WIDTH   = 2*AGC_IQ_WIDTH + 1,   // 33 bits
    parameter GAIN_WIDTH    = POWER_WIDTH + 1        // 34 bits
)(
    input  wire                        clk,
    input  wire                        rst_n,

    // IQ baseband input — 12-bit native width
    input  wire                        valid_in_i,
    input  wire signed [IQ_WIDTH-1:0]  I_in_i,
    input  wire signed [IQ_WIDTH-1:0]  Q_in_i,

    // Corrected IQ output — 12-bit native width
    output reg  signed [IQ_WIDTH-1:0]  I_out_o,
    output reg  signed [IQ_WIDTH-1:0]  Q_out_o,
    output reg                         valid_out_o
);

    /////////////////////////////////////////////
    //////////////Internal signals//////////////
    /////////////////////////////////////////////
    wire [GAIN_WIDTH-1:0]       gain_o;
    wire                        gain_valid_o;

    // Sign-extend 12-bit → 16-bit for internal math precision
    wire signed [AGC_IQ_WIDTH-1:0] I_ext;
    wire signed [AGC_IQ_WIDTH-1:0] Q_ext;

    assign I_ext = {{(AGC_IQ_WIDTH-IQ_WIDTH){I_in_i[IQ_WIDTH-1]}}, I_in_i};
    assign Q_ext = {{(AGC_IQ_WIDTH-IQ_WIDTH){Q_in_i[IQ_WIDTH-1]}}, Q_in_i};

    wire [POWER_WIDTH-1:0]  raw_power_w;
    wire                    raw_power_valid_w;

    wire [POWER_WIDTH-1:0]  avg_power_w;
    wire                    avg_power_valid_w;

    // Gain application internals
    // Product: 12-bit × 34-bit = 46-bit
    wire signed [IQ_WIDTH + GAIN_WIDTH - 1 : 0] I_product;
    wire signed [IQ_WIDTH + GAIN_WIDTH - 1 : 0] Q_product;

    // Clip constants — 12-bit signed range
    localparam signed [IQ_WIDTH-1:0] CLIP_MAX = { 1'b0, {(IQ_WIDTH-1){1'b1}} };  // +2047
    localparam signed [IQ_WIDTH-1:0] CLIP_MIN = { 1'b1, {(IQ_WIDTH-1){1'b0}} };  // -2048

    wire signed [IQ_WIDTH-1:0] I_gained;
    wire signed [IQ_WIDTH-1:0] Q_gained;
    wire signed [IQ_WIDTH-1:0] I_clipped;
    wire signed [IQ_WIDTH-1:0] Q_clipped;

    ////////////////////////////////////////////
    //////////////Power Estimator//////////////
    ///////////////////////////////////////////
    
    Power_Estimator #(
        .N          ( AGC_IQ_WIDTH  )       // 16-bit for math precision
    ) u_power_estimator (
        .clk        ( clk               ),
        .rst_n      ( rst_n             ),
        .valid_in   ( valid_in_i        ),
        .I_in       ( I_ext             ),  // 16-bit sign-extended
        .Q_in       ( Q_ext             ),  // 16-bit sign-extended
        .power_out  ( raw_power_w       ),
        .valid_out  ( raw_power_valid_w )
    );

    ////////////////////////////////////////////
    ///////////////Average Filter///////////////
    ////////////////////////////////////////////
   
    avgerage_filter #(
        .DATA_WIDTH ( POWER_WIDTH   ),
        .N_LOG2     ( AVG_LOG2      )
    ) u_avg_filter (
        .clk        ( clk               ),
        .rst        ( rst_n             ),
        .valid_in_i ( raw_power_valid_w ),
        .data_in_i  ( raw_power_w       ),
        .avg_out_o  ( avg_power_w       ),
        .valid_out_o( avg_power_valid_w )
    );

    ////////////////////////////////////////////
    ////////////////Gain Control////////////////
    ////////////////////////////////////////////
    
    Gain_Control #(
        .POWER_TARGET ( POWER_TARGET    ),
        .STEP_SIZE    ( STEP_SIZE       ),
        .IN_SIZE      ( POWER_WIDTH     ),  // 33
        .OUT          ( GAIN_WIDTH      )   // 34
    ) u_gain_control (
        .clk          ( clk               ),
        .rst_n        ( rst_n             ),
        .power_i      ( avg_power_w       ),
        .power_valid_i( avg_power_valid_w ),
        .gain_o       ( gain_o            ),
        .gain_valid_o ( gain_valid_o      )
    );

    ////////////////////////////////////////////
    ////////////// Apply Gain //////////////////
    ////////////////////////////////////////////

    // Multiply 12-bit I/Q by gain word G (Q8 format)
    // Product: 12-bit × 34-bit = 46-bit
    assign I_product = $signed(I_in_i) * $signed({1'b0, gain_o});
    assign Q_product = $signed(Q_in_i) * $signed({1'b0, gain_o});

    // Extract bits [19:8] — >> 8 then take 12 bits (Q8 fixed-point)
    assign I_gained = I_product[19:8];
    assign Q_gained = Q_product[19:8];

    // Clip to 12-bit signed range [-2048, +2047]
    assign I_clipped = ($signed(I_gained) > $signed(CLIP_MAX)) ? CLIP_MAX :
                       ($signed(I_gained) < $signed(CLIP_MIN)) ? CLIP_MIN : I_gained;
    assign Q_clipped = ($signed(Q_gained) > $signed(CLIP_MAX)) ? CLIP_MAX :
                       ($signed(Q_gained) < $signed(CLIP_MIN)) ? CLIP_MIN : Q_gained;

    // Output register — 12-bit corrected I/Q to BLE_RX_PHY
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            I_out_o     <= 0;
            Q_out_o     <= 0;
            valid_out_o <= 0;
        end else begin
            I_out_o     <= I_clipped;
            Q_out_o     <= Q_clipped;
            valid_out_o <= valid_in_i & gain_valid_o;
        end
    end

endmodule