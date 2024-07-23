module write_address(
clk,
rst_n,
cw_en,
w_ptr,
cw_max);

parameter MEMORY_DEPTH = 4;
parameter FIFO_ADDRESS_SIZE = 2;

input clk;
input rst_n;
input cw_en;

output [(FIFO_ADDRESS_SIZE):0] w_ptr;
output cw_max;


//Counter for w_ptr


wire [(FIFO_ADDRESS_SIZE):0] count_w_in;


assign cw_max = (w_ptr == (MEMORY_DEPTH -1));   //for restarting the counter when it reaches the maximum value (the depth of the memory)


d_ff_async_en  #(.SIZE(FIFO_ADDRESS_SIZE+1))
 counter_write_address(.clk(clk),
		       .rst(!rst_n),
		       .en(cw_en),     //the counter increments only during writing operation
		       .d(count_w_in),
		       .q(w_ptr));

assign count_w_in = w_ptr + 1'b1;


endmodule