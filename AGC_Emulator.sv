// =============================================================================
// Channel Emulator + AGC Wrapper
// =============================================================================
// Sits between BLE_TX_PHY and BLE_RX_PHY.
// 1. Scales TX I/Q by α to simulate channel attenuation / amplification
// 2. Feeds scaled I/Q into agc_top which handles:
//      - Sign extension 12-bit → 16-bit internally for math precision
//      - Power estimation, averaging, gain control
//      - Gain application and clipping back to 12-bit
// 3. Drives corrected 12-bit I/Q into BLE_RX_PHY
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
    // α = 490  → gain 1.91 (strong / maximum recoverable)
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
    input  wire                       clk,
    input  wire                       rst_n,

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
    // Stage 2 — AGC Top
    // agc_top sign-extends 12-bit → 16-bit internally for math precision.
    // Applies gain G, clips back to 12-bit, outputs corrected I/Q directly.
    // =========================================================================

    wire signed [IQ_WIDTH-1:0]     I_agc_out;
    wire signed [IQ_WIDTH-1:0]     Q_agc_out;
    wire                           valid_agc_out;

    agc_top #(
        .IQ_WIDTH       ( IQ_WIDTH      ),
        .AGC_IQ_WIDTH   ( AGC_IQ_WIDTH  ),
        .AVG_LOG2       ( AVG_LOG2      ),
        .POWER_TARGET   ( POWER_TARGET  ),
        .STEP_SIZE      ( STEP_SIZE     )
    ) u_agc_top (
        .clk            ( clk           ),
        .rst_n          ( rst_n         ),
        .valid_in_i     ( valid_tx_i    ),
        .I_in_i         ( I_scaled      ),
        .Q_in_i         ( Q_scaled      ),
        .I_out_o        ( I_agc_out     ),
        .Q_out_o        ( Q_agc_out     ),
        .valid_out_o    ( valid_agc_out )
    );

    // =========================================================================
    // Stage 3 — Output Register
    // agc_top outputs corrected 12-bit I/Q — pass directly to BLE_RX_PHY
    // =========================================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            I_rx_o     <= 0;
            Q_rx_o     <= 0;
            valid_rx_o <= 0;
        end else begin
            I_rx_o     <= I_agc_out;
            Q_rx_o     <= Q_agc_out;
            valid_rx_o <= valid_agc_out;
        end
    end

endmodule