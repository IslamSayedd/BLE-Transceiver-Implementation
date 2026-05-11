module NRZ #(
  parameter SAMPLE_PER_SYMBOL = 8,
            DATA_WIDTH = 11
) (
  input wire clk,
  input wire rst_n,
  input wire phy_bit_i,
  input wire bit_valid_i,
  
  output reg signed [1:0] NRZ_o,
  output reg NRZ_valid_o
);
integer j;
integer count_loop;
reg Done;
reg flag_done;
integer counter;
reg signed [1:0] NRZ_reg [DATA_WIDTH - 1 : 0];

integer k; // for reset loop

//Input
always @ (posedge clk or negedge rst_n) 
  begin
    if (!rst_n) 
      begin
        counter  <= 'b0;
        Done     <= 'b0;                  
        for (k = 0; k < DATA_WIDTH; k = k + 1)
          NRZ_reg[k] <= 'b0;              
      end 
    else 
      begin
        if (bit_valid_i)
          begin 
            if (counter != DATA_WIDTH) 
              begin 
                if (phy_bit_i)
                  NRZ_reg[counter] <= 'b1;
                else
                  NRZ_reg[counter] <= -'sd1;
                counter <= counter + 'b1;
                Done    <= 'b1;
              end
          end
        else 
          begin
            counter <= 'b0;
            Done    <= 'b0;
          end
      end
  end

//Output
always@(posedge clk or negedge rst_n)
  begin
    if (!rst_n) 
      begin
        NRZ_o       <= 'b0;
        NRZ_valid_o <= 'b0;
        count_loop  <= 'b0;
      end 
    else 
      begin
        if(flag_done && count_loop != DATA_WIDTH) 
          begin
            NRZ_o       <= NRZ_reg[count_loop];
            NRZ_valid_o <= 'b1;
            count_loop  <= count_loop + 'b1;
          end
        else
          begin
            count_loop  <= 'b0;
            NRZ_valid_o <= 'b0;
          end 
      end       
  end

assign flag_done = ((Done || count_loop != 'b0) && (count_loop != DATA_WIDTH)) ? 'b1 : 'b0;

endmodule 
