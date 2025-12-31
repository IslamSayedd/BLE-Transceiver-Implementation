module upsample #
(
  parameter SAMPLE_PER_SYMBOL = 8, //number for repeatition
            DATA_WIDTH = 11 //number of bits from the mux
) (
  input wire clk,
  input wire rst_n,

  input wire [1:0] NRZ_i,
  input wire       NRZ_valid_i,
  
  output reg bit_upsample_o,
  output reg bit_upsample_valid_o
);

integer counter;
integer i;
integer counter_out;
integer loop_out;

reg                             phy_bit_reg_in;
reg [ SAMPLE_PER_SYMBOL -1 : 0] bit_upsample_reg [DATA_WIDTH - 1 : 0];
reg done;
wire valid;
wire out_flag;
reg flag_done;

always @ (posedge clk or negedge rst_n) 
  begin

    if (!rst_n) 
      begin
        bit_upsample_o <= 'b0;
        bit_upsample_valid_o <= 'b0;
        counter <= 'b0;
        phy_bit_reg_in <= 'b0;
        loop_out <= 'b0;
        counter_out <= 'b0;
        flag_done <='b0;
        
      end 
    else 
      begin
        if (NRZ_valid_i) // for taking input if we will send 2 frames consecutive we must leave a clock cycle between them
          begin 
            bit_upsample_reg [counter] <= {SAMPLE_PER_SYMBOL{!NRZ_i[1]}};  
            if(counter == DATA_WIDTH) begin
             counter <= 'b0;
            end
            else counter <= counter + 'b1;
        end
        else counter <= 'b0;

     
        
        if(out_flag) 
          begin
            if(counter_out != DATA_WIDTH) begin
              if(loop_out != SAMPLE_PER_SYMBOL - 1) begin
                bit_upsample_o <= bit_upsample_reg [counter_out] [loop_out];
                loop_out <= loop_out + 'b1;
                bit_upsample_valid_o <= 'b1;
              end
            else
              begin
                loop_out <= 'b0;
                counter_out <= counter_out + 1;
                bit_upsample_valid_o <= 'b1;
              end
          end
        else 
          begin
            counter_out <= 'b0;
            bit_upsample_valid_o <= 'b0;
          end
      end 


    end    
end


//assign valid = ((NRZ_valid_i)  )? 'b1 : 'b0;
assign out_flag = ((NRZ_valid_i && counter !=0 )|| counter_out!= 'b0) && !(counter_out == DATA_WIDTH && loop_out == 1) ? 'b1:'b0;
endmodule