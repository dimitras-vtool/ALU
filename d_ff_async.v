module d_ff_async (
clk,
rst,
d,
q);

parameter SIZE;
parameter RESET_VALUE;

input clk;
input rst;
input [(SIZE-1):0] d;
output reg [(SIZE-1):0] q;



always@(posedge clk, posedge rst) begin
	if(rst) 
		q <= RESET_VALUE;
	else
		q <= d;
end

endmodule
