module posedge_detector (
clk,
rst_n,
sig_to_detect,
en,
positive_edge
);


input clk;
input rst_n;
input sig_to_detect;
input en;

output positive_edge;

wire sig_dly;

d_ff_async_en #(.SIZE(1'b1),
             .RESET_VALUE(0))
    posedge_reg(.clk(clk),
              .rst(!rst_n),
			  .en(en),
              .d(sig_to_detect),
              .q(sig_dly));

assign positive_edge = (!sig_dly & sig_to_detect);

endmodule
