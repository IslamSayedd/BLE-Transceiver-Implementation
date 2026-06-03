module upsample #
(
  parameter SAMPLE_PER_SYMBOL = 8,
            DATA_WIDTH = 11
) (
  input wire clk,
  input wire rst_n,
  input wire [1:0] NRZ_i,
  input wire       NRZ_valid_i,
  
  output reg bit_upsample_o,
  output reg bit_upsample_valid_o
);

integer counter;
integer counter_out;
integer loop_out;
integer k;
reg [SAMPLE_PER_SYMBOL-1:0] bit_upsample_reg [DATA_WIDTH-1:0];
wire out_flag;

wire [SAMPLE_PER_SYMBOL-1:0] live_sample;
assign live_sample = {SAMPLE_PER_SYMBOL{!NRZ_i[1]}};

wire [SAMPLE_PER_SYMBOL-1:0] current_read;
assign current_read = (counter_out == counter) ? live_sample : bit_upsample_reg[counter_out];

always @ (posedge clk or negedge rst_n) 
  begin
    if (!rst_n) 
      begin
        bit_upsample_o       <= 'b0;
        bit_upsample_valid_o <= 'b0;
        counter              <= 'b0;
        loop_out             <= 'b0;
        counter_out          <= 'b0;
        for (k = 0; k < DATA_WIDTH; k = k + 1)
          bit_upsample_reg[k] <= 'b0;    
      end 
    else 
      begin
        // Input side
        if (NRZ_valid_i)
          begin
            if (counter == DATA_WIDTH)
              counter <= 'b0;
            else
              begin
                bit_upsample_reg[counter] <= live_sample;
                counter <= counter + 'b1;
              end
          end
        else
          begin
            counter <= 'b0;
          end

        // Output side
        if (out_flag)
          begin
            if (counter_out != DATA_WIDTH)
              begin
                bit_upsample_o       <= current_read[loop_out];
                bit_upsample_valid_o <= 'b1;
                if (loop_out == SAMPLE_PER_SYMBOL - 1)
                  begin
                    loop_out    <= 'b0;
                    counter_out <= counter_out + 1;
                  end
                else
                  begin
                    loop_out <= loop_out + 'b1;
                  end
              end
          end
        else
          begin
            counter_out          <= 'b0;
            loop_out             <= 'b0;
            bit_upsample_o       <= 'b0;           
            bit_upsample_valid_o <= 'b0;
          end
      end
  end

assign out_flag = (NRZ_valid_i && counter == 'b0) || 
                  (counter_out == 'b0 && loop_out != 'b0) || 
                  (counter_out != 'b0 && counter_out != DATA_WIDTH) ? 'b1 : 'b0;

endmodule