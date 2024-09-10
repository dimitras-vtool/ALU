module posedge_detector (
clk,
rst_n,
sig_to_detect,
positive_edge
);


input clk;
input rst_n;
input sig_to_detect;

output positive_edge;

wire sig_dly;


d_ff_async_en #(.SIZE(1'b1),
             .RESET_VALUE(1))
    posedge_reg(.clk(clk),
              .rst(!rst_n),
			  .en(1'b1),
              .d(sig_to_detect),
              .q(sig_dly));

/*
always@(posedge clk, negedge rst_n) begin
    if(!rst_n) 
        sig_dly <= RESET_VALUE;
    else if(en)
        sig_dly <= sig_to_detect;
end
*/

assign positive_edge = (!sig_dly & sig_to_detect);

endmodule
