module NRZ #(
  parameter SAMPLE_PER_SYMBOL = 8, //number for repeatition
            DATA_WIDTH = 11 //number of bits from the mux
) (
  input wire clk,
  input wire rst_n,

  input wire phy_bit_i,
  input wire bit_valid_i,
  
  output reg [1:0] NRZ_o,
  output reg NRZ_valid_o
);

integer i;
integer j;
integer count_loop='b0; //for output
reg Done;
reg flag_done;
integer counter = 'b0;
reg [DATA_WIDTH-1 : 0] store_in;
reg In_valid;
reg [ 1 : 0] NRZ_reg [DATA_WIDTH - 1 : 0];

//Input
always @ (posedge clk or negedge rst_n) 
  begin
    if (!rst_n) 
      begin
        NRZ_o <= 'b0;
        NRZ_valid_o <= 'b0;
        counter <= 'b0;
      end 
    else 
      begin
        if (bit_valid_i) // for taking input if we will send 2 frames consecutive we must leave a clock cycle between them
          begin 
            if (counter != DATA_WIDTH ) 
              begin 
               	store_in [counter] <=  phy_bit_i; //to store all the input (of DATA_WIDTH size) 
                counter <= counter + 'b1;
              end
          end
        else 
          begin
            counter <= 'b0;
          end
  	end
  end

//Output
always@(posedge clk or negedge rst_n)
  begin
    if (!rst_n) 
      begin
        NRZ_o <= 'b0;
        NRZ_valid_o <= 'b0;
        counter <= 'b0;
      end 
    else 
      begin
        if(flag_done && count_loop != DATA_WIDTH) 
          begin
            NRZ_o <= NRZ_reg[count_loop];
            NRZ_valid_o <= 'b1;
            count_loop <= count_loop +'b1;
          end
        else
          begin
            count_loop <= 'b0;
            NRZ_valid_o <= 'b0;
          end 
      end       
  end

//NRZ logic
always@(*) begin
	if (In_valid) begin
        for(i = 0; i < DATA_WIDTH ; i++) begin
        	if(store_in[i])
        		begin
        			NRZ_reg[i] <= 'b1;
        			
        		end
        	else begin
        		NRZ_reg[i] <= -'sd1;
        	end
        end
        Done <= 'b1;
    end
    else begin
        Done <= 'b0;
        
    end
end
assign In_valid = (counter == DATA_WIDTH )? 'b1: 'b0 ; // I already received the full frame
assign  flag_done = ((Done || count_loop != 'b0) && (count_loop != DATA_WIDTH ))? 'b1 :'b0 ; // to ensure that the flag is 1 first when the done is 1 and then until i send all the data

endmodule 
