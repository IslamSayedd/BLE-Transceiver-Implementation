`timescale 1ns/1ps
module fsk_demod #(parameter IQ_BIT_WIDTH = 8)  
(
  input wire                           CLK_i,
  input wire                           RST_i,
  input wire signed [IQ_BIT_WIDTH-1:0] in_phase_i_i,
  input wire signed [IQ_BIT_WIDTH-1:0] quadrature_q_i,
  input wire                           iq_valid_i,
  output reg                           demod_signal_o,
  output reg                           demod_signal_valid_o
);

reg signed [IQ_BIT_WIDTH-1:0]   in_phase_i_0;
reg signed [IQ_BIT_WIDTH-1:0]   in_phase_i_1;
reg signed [IQ_BIT_WIDTH-1:0]   quadrature_q_0;
reg signed [IQ_BIT_WIDTH-1:0]   quadrature_q_1;
reg signed [2*IQ_BIT_WIDTH:0]   decision;

reg [2:0] valid_pipe;

always @(posedge CLK_i or negedge RST_i) 
begin
  if (!RST_i) begin
    in_phase_i_0         <= 'b0;
    in_phase_i_1         <= 'b0;
    quadrature_q_0       <= 'b0;
    quadrature_q_1       <= 'b0;
    demod_signal_o       <= 'b0;
    demod_signal_valid_o <= 'b0;
    valid_pipe           <= 'b0;
  end 
  else 
  begin
    valid_pipe           <= {valid_pipe[1:0], iq_valid_i};
    demod_signal_valid_o <= valid_pipe[2];

    if (iq_valid_i) begin
      in_phase_i_1   <= in_phase_i_i;
      in_phase_i_0   <= in_phase_i_1;
      quadrature_q_1 <= quadrature_q_i;
      quadrature_q_0 <= quadrature_q_1;
    end

    decision     <= (in_phase_i_0 * quadrature_q_1) - (in_phase_i_1 * quadrature_q_0);
    demod_signal_o <= (decision > 0)? 1'b1 : 1'b0;
  end
end
endmodule
