module read_address(
clk,
rst_n,
cr_en,
r_ptr);

//This file generates the pointer for reading from the FIFO

parameter MEMORY_DEPTH = 4;
parameter FIFO_ADDRESS_SIZE = 3;

input clk;
input rst_n;
input cr_en;

output [(FIFO_ADDRESS_SIZE):0] r_ptr;


//Counter for r_ptr

wire [(FIFO_ADDRESS_SIZE):0] count_r_in;


d_ff_async_en  #(.SIZE(FIFO_ADDRESS_SIZE+1))
 counter_read_address(.clk(clk),
		      .rst(!rst_n),
		      .en(cr_en),       //the counter increments only during reading operation
		      .d(count_r_in),
		      .q(r_ptr));
	

wire r_max;
assign r_max = (r_ptr == (MEMORY_DEPTH -1));   //for restarting the counter when it reaches the maximum value (the depth of the memory)

assign 	count_r_in = r_ptr + 1'b1;



endmodule
