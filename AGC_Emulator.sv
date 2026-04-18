// =============================================================================
// Channel Emulator + AGC Wrapper
// =============================================================================
// Sits between BLE_TX_PHY and BLE_RX_PHY.
// 1. Scales TX I/Q by α to simulate channel attenuation / amplification
// 2. Sign-extends 12-bit I/Q to 16-bit for agc_top
// 3. Feeds scaled I/Q into agc_top to get gain word G
// 4. Applies G to the scaled I/Q and clips back to 12-bit
// 5. Drives corrected I/Q into BLE_RX_PHY
// =============================================================================

module channel_emulator #(
    // -------------------------------------------------------
    // IQ widths
    // -------------------------------------------------------
    parameter IQ_WIDTH      = 12,           // TX / RX native width
    parameter AGC_IQ_WIDTH  = 16,           // agc_top internal width

    // -------------------------------------------------------
    // Channel attenuation factor α (fixed-point Q8)
    // α = 256  → gain 1.0  (no change)
    // α = 26   → gain 0.1  (weak signal)
    // α = 128  → gain 0.5  (medium)
    // α = 512  → gain 2.0  (strong / clipping risk)
    // -------------------------------------------------------
    parameter ALPHA_Q8      = 8'd26,        // default: weak signal (α ≈ 0.1)

    // -------------------------------------------------------
    // AGC parameters (must match agc_top defaults)
    // -------------------------------------------------------
    parameter AVG_LOG2      = 4,
    parameter POWER_TARGET  = 33'd4294967296,
    parameter STEP_SIZE     = 3,

    // -------------------------------------------------------
    // Derived — do not override
    // -------------------------------------------------------
    parameter POWER_WIDTH   = 2*AGC_IQ_WIDTH + 1,  // 33
    parameter GAIN_WIDTH    = POWER_WIDTH + 1        // 34
)(
    input  wire                      clk,
    input  wire                      rst_n,

    // ----- From BLE_TX_PHY -----
    input  wire signed [IQ_WIDTH-1:0] I_tx_i,
    input  wire signed [IQ_WIDTH-1:0] Q_tx_i,
    input  wire                       valid_tx_i,

    // ----- To BLE_RX_PHY -----
    output reg  signed [IQ_WIDTH-1:0] I_rx_o,
    output reg  signed [IQ_WIDTH-1:0] Q_rx_o,
    output reg                        valid_rx_o
);

    // =========================================================================
    // Stage 1 — Channel Attenuation  (α scaling)
    // Multiply 12-bit I/Q by ALPHA_Q8 (Q8 fixed-point) then shift back by 8
    // Product is 12+8 = 20 bits; we keep the top 12 bits after >> 8
    // =========================================================================

    wire signed [IQ_WIDTH+8-1:0] I_scaled_full;
    wire signed [IQ_WIDTH+8-1:0] Q_scaled_full;

    assign I_scaled_full = I_tx_i * $signed({1'b0, ALPHA_Q8});
    assign Q_scaled_full = Q_tx_i * $signed({1'b0, ALPHA_Q8});

    // Shift right by 8 to remove Q8 fractional part → back to IQ_WIDTH
    wire signed [IQ_WIDTH-1:0] I_scaled;
    wire signed [IQ_WIDTH-1:0] Q_scaled;

    assign I_scaled = I_scaled_full >>> 8;
    assign Q_scaled = Q_scaled_full >>> 8;

    // =========================================================================
    // Stage 2 — Sign-extend 12-bit → 16-bit for agc_top
    // =========================================================================

    wire signed [AGC_IQ_WIDTH-1:0] I_ext;
    wire signed [AGC_IQ_WIDTH-1:0] Q_ext;

    assign I_ext = {{(AGC_IQ_WIDTH-IQ_WIDTH){I_scaled[IQ_WIDTH-1]}}, I_scaled};
    assign Q_ext = {{(AGC_IQ_WIDTH-IQ_WIDTH){Q_scaled[IQ_WIDTH-1]}}, Q_scaled};

    // =========================================================================
    // Stage 3 — AGC Top
    // Outputs gain word G (34-bit) based on smoothed power estimate
    // =========================================================================

    wire [GAIN_WIDTH-1:0]  gain_w;
    wire                   gain_valid_w;

    agc_top #(
        .IQ_WIDTH       ( AGC_IQ_WIDTH  ),
        .AVG_LOG2       ( AVG_LOG2      ),
        .POWER_TARGET   ( POWER_TARGET  ),
        .STEP_SIZE      ( STEP_SIZE     )
    ) u_agc_top (
        .clk            ( clk           ),
        .rst_n          ( rst_n         ),
        .valid_in_i     ( valid_tx_i    ),
        .I_in_i         ( I_ext         ),
        .Q_in_i         ( Q_ext         ),
        .gain_o         ( gain_w        ),
        .gain_valid_o   ( gain_valid_w  )
    );

    // =========================================================================
    // Stage 4 — Apply Gain  (I × G, Q × G)
    // gain_w is 34-bit.
    // We treat gain_w as Q8 fixed-point (lower 8 bits = fractional).
    // Product: 12-bit × 34-bit = 46-bit; we take bits [19:8] → 12-bit result.
    // Then clip to signed 12-bit range [-2048, +2047].
    // =========================================================================

    // Full-width products
    wire signed [IQ_WIDTH + GAIN_WIDTH - 1 : 0] I_product;
    wire signed [IQ_WIDTH + GAIN_WIDTH - 1 : 0] Q_product;

    assign I_product = $signed(I_scaled) * $signed({1'b0, gain_w});
    assign Q_product = $signed(Q_scaled) * $signed({1'b0, gain_w});

    // Extract bits [19:8] — equivalent to >> 8 then take 12 bits
    wire signed [IQ_WIDTH-1:0] I_gained;
    wire signed [IQ_WIDTH-1:0] Q_gained;

    assign I_gained = I_product[19:8];
    assign Q_gained = Q_product[19:8];

    // Clip to 12-bit signed [-2048, +2047]
    localparam signed [IQ_WIDTH-1:0] CLIP_MAX =  { 1'b0, {(IQ_WIDTH-1){1'b1}} };  // +2047
    localparam signed [IQ_WIDTH-1:0] CLIP_MIN =  { 1'b1, {(IQ_WIDTH-1){1'b0}} };  // -2048

    wire signed [IQ_WIDTH-1:0] I_clipped;
    wire signed [IQ_WIDTH-1:0] Q_clipped;

    assign I_clipped = (I_gained > CLIP_MAX) ? CLIP_MAX :
                       (I_gained < CLIP_MIN) ? CLIP_MIN : I_gained;

    assign Q_clipped = (Q_gained > CLIP_MAX) ? CLIP_MAX :
                       (Q_gained < CLIP_MIN) ? CLIP_MIN : Q_gained;

    // =========================================================================
    // Stage 5 — Output Register
    // Gate output valid on gain_valid_w so RX only sees corrected samples
    // =========================================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            I_rx_o    <= 0;
            Q_rx_o    <= 0;
            valid_rx_o <= 0;
        end else begin
            I_rx_o     <= I_clipped;
            Q_rx_o     <= Q_clipped;
            valid_rx_o <= valid_tx_i & gain_valid_w;
        end
    end

endmodule