module upsample #
(
  parameter SAMPLE_PER_SYMBOL = 8, //number for repeatition
            DATA_WIDTH = 11 //number of bits from the mux
) (
  input wire clk,
  input wire rst_n,

  input wire phy_bit_i,
  input wire bit_valid_i,
  
  output reg [ SAMPLE_PER_SYMBOL -1 : 0] bit_upsample_o,
  output reg bit_upsample_valid_o
);

integer counter = 'b0;
integer i;
integer count_loop ='b0;
reg [ DATA_WIDTH - 1 : 0] phy_bit_reg_in;
reg [ SAMPLE_PER_SYMBOL -1 : 0] bit_upsample_reg [DATA_WIDTH - 1 : 0];
reg done;
wire valid;
wire flag_done;

always @ (posedge clk or negedge rst_n) 
  begin

    if (!rst_n) 
      begin
        bit_upsample_o <= 'b0;
        bit_upsample_valid_o <= 'b0;
        counter <= 'b0;
        phy_bit_reg_in <= 'b0;
        count_loop <= 'b0;
      end 
    else 
      begin
        if (bit_valid_i) // for taking input if we will send 2 frames consecutive we must leave a clock cycle between them
          begin 
            if (counter != DATA_WIDTH ) 
              begin 
                   
                  phy_bit_reg_in [counter] <=  phy_bit_i; //to store all the input (of DATA_WIDTH size) 
                  counter <= counter + 'b1;
               end
            else 
              begin
               counter <= 'b0; 
              end
         end 
        else
          begin
              counter <= 'b0; 
           end 

    if(flag_done) 
      begin
        if(count_loop != DATA_WIDTH) 
          begin
            bit_upsample_o <= bit_upsample_reg [count_loop];  //output pass each symbol individually
            count_loop <= count_loop +1;
          end
        else 
          begin
            count_loop <= 'b0 ;
          end 
      end
    else 
          begin
            count_loop <= 'b0 ;
          end   

    bit_upsample_valid_o <= flag_done;
    end    
end


always @(*) 
  begin
    if (valid) 
      begin
        for(i = 0; i <= DATA_WIDTH - 'b1; i = i + 'b1 ) //Loop on the DATA_WIDTH
          begin 
           
              bit_upsample_reg [i] <= {SAMPLE_PER_SYMBOL{phy_bit_reg_in [i]}}; // +ve deviation (1) is 1 and -ve deviation is 0 (-1)
            
          end
         done = 'b1; //after the upsample operation assign done to 1 to start passing the output
      end
    else 
      begin
        done = 'b0;
      end
  end

assign  flag_done = ((done || count_loop != 'b0) && (count_loop != DATA_WIDTH ))? 'b1 :'b0 ; // to ensure that the flag is 1 first when the done is 1 and then until i send all the data
assign valid = (counter == DATA_WIDTH )? 'b1: 'b0 ; // I already received the full frame

endmodule

                
