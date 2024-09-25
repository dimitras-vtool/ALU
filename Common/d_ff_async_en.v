module d_ff_async_en (
clk,
rst,
en,
d,
q);

parameter SIZE = 1;
parameter RESET_VALUE = 0;

input clk;
input rst;
input en;
input [(SIZE-1):0] d;
output reg [(SIZE-1):0] q;



always@(posedge clk, posedge rst) begin
	if(rst) 
		q <= RESET_VALUE;
	else if(!rst & en)
		q <= d;
end

endmodule
