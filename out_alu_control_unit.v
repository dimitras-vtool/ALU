module out_alu_control_unit(
clk,
rst_n,
a_valid_res,
m_valid_res,
result_add,
result_mul,
ready_f_res,
fifo_res,
w_en_out,
sum_written,
mul_written
);

// The control unit responsible for the communication between FIFO_OUT and ALU module, mainly. For more details read documentation.

parameter FIFO_OUT_WIDTH  = 25;  //saving 8-bit ID together with result

parameter DATA_SIZE       = 16;
parameter MUL_DATA_SIZE   = (DATA_SIZE/2);
parameter ID_SIZE         = 8;
 
input clk;
input rst_n;     
 
//From ALU
input a_valid_res;
input m_valid_res;

////ADD result
input [((FIFO_OUT_WIDTH)-1):0] result_add;

////MUL result
input [((FIFO_OUT_WIDTH)-1):0] result_mul;


//From FIFO_OUT
input ready_f_res;


//To FIFO_OUT
output reg [(FIFO_OUT_WIDTH-1):0] fifo_res;
output w_en_out;


//TO ADDER and MUL  (ALU) 

output sum_written;
output mul_written;




//w_en_out for FIFO_OUT

wire w_en_out_temp;
assign w_en_out_temp = ((a_valid_res | m_valid_res) & ready_f_res);

posedge_detector 
	w_en_out_posedge(
			  .clk(clk),
			  .rst_n(rst_n),
			.sig_to_detect(w_en_out_temp),
			.en(1'b1),
			.positive_edge(w_en_out));


//signals that alert ALU that the results have been written (so that valid_f_res signals fall)

wire a_fifo_out;
assign a_fifo_out = (ready_f_res & a_valid_res);

d_ff_async_en #(.SIZE(1),
             .RESET_VALUE(1'b0))
       sum_write_reg(.clk(clk),
                .rst(!rst_n),
				.en(1'b1),
                .d(a_fifo_out),
                .q(sum_written));
				 
wire m_fifo_out;
assign m_fifo_out = (ready_f_res & !a_valid_res & m_valid_res);  //in case both a/m_valid_res are high, add results take precedence

d_ff_async_en #(.SIZE(1),
             .RESET_VALUE(1'b0))
       mul_write_reg(.clk(clk),
                .rst(!rst_n),
				.en(1'b1),
                .d(m_fifo_out),
                .q(mul_written));

 
 
 
//MUX for storing the correct results based on the valid_f_res signals

always@(*)begin
	case({a_valid_res,m_valid_res})
		2'b10 : fifo_res = result_add;
		2'b01 : fifo_res = result_mul;
		2'b11 : fifo_res = result_add; //in case both a/m_valid_res are high, add results take precedence
		2'b00 : fifo_res = {FIFO_OUT_WIDTH{1'b0}}; //w_en would be zero anyway
	endcase
end
 
 
endmodule
