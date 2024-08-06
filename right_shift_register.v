module right_shift_register(
clk,
rst_n,
en,
shift_load,
d,
d_shift,
q);

//A roght shift register, loading data in parallel and shifting them right, based on the input shift-load.

parameter DATA_SIZE  = 8;

input clk; 
input rst_n;
input en;
input shift_load;   //1->shift, 0-> load
input [(DATA_SIZE-1):0] d;
input d_shift;

output reg [(DATA_SIZE-1):0] q;


//shift right or load
wire [(DATA_SIZE-1):0] d_in; 

always@(posedge clk, negedge rst_n) begin
    if(!rst_n)
        q <= {DATA_SIZE{1'b0}};
    else begin
        if(en) begin
          if(shift_load)
              q <= {d_shift, q[(DATA_SIZE-1):1]};
        else if(!shift_load)
            q <= d;
        end
    end
end



endmodule
