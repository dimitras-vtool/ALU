module csr_APB (
clk,   
rst_n,
addr,
sel,
en,
write,
start_bit,
full_in,
empty_out,
slv_err,
ready,
en_ctrl ,
en_data0,
en_data1,
r_en_out,
w_en_in
);

/*
`include "d_ff_async.v"
`include "d_ff_async_en.v"

*/

parameter ADDRESS_SIZE      = 2;       
parameter REG_NUMBER        = 4;       //How many registers we have.

parameter REG_CTRL          = 0;
parameter REG_0             = 1;
parameter REG_1             = 2;
parameter REG_RES 			= 3;


//APB
input                              clk;   
input                              rst_n;
input [(ADDRESS_SIZE -1):0]        addr;
input                              sel;
input                              en;
input                              write;

//From CS registers
input 							  start_bit;

//from FIFO_IN
input							   full_in;

//From FIFO_OUT
input 							   empty_out;

//APB
output                             slv_err;
output reg                         ready;

//CS Registers and FIFO_OUT
output                			   en_ctrl;
output 							   en_data0;
output							   en_data1;
output							   r_en_out;

//TO FIFO_IN
output 							   w_en_in;




//Ready
wire ready_write;
  
d_ff_async_en #(.SIZE(1),
		        .RESET_VALUE(0))
	 d_ready_write(.clk(clk),
	          .rst(!rst_n),
	          .en(sel),
	          .d(!en),        //There are no wait states
              .q(ready_write));



//2nd register for the extra wait cycle 
wire ready_read;

d_ff_async #(.SIZE(1),
		     .RESET_VALUE(0))
	 d_ready_read(.clk(clk),
	          .rst(!rst_n),
	          .d(ready_write),        //There are no wait states
              .q(ready_read));



//Mux for ready (with a wait state for reading from FIFO_OUT)

always@(*)begin
	case({sel,en,write,slv_err})
		4'b1110: ready = ready_write;
		4'b1100: ready = ready_read;
		default: ready = 1'b0;
	endcase
end



//address for registers

wire addr_0;
wire addr_1;
wire addr_2;
wire addr_3;

assign addr_0 = (addr == REG_CTRL);
assign addr_1 = (addr == REG_0);
assign addr_2 = (addr == REG_1);
assign addr_3 = (addr == REG_RES);


//errors
wire write_err;
assign write_err = ((addr_0 | addr_1 | addr_2) & !write);

wire read_err;
assign read_err = (addr_3 & write);

wire addr_err;
assign addr_err = (addr >= REG_NUMBER);

wire empty_err;
assign empty_err = (empty_out & addr_3 & !write);

wire full_err;
assign full_err = (full_in & (addr_0 | addr_1 | addr_2) & write);

          
//slv_err
assign slv_err_temp = (write_err | read_err | addr_err | full_err | empty_err);


d_ff_async_en #(.SIZE(1),
		     .RESET_VALUE(0))
	 err_reg(.clk(clk),
	         .rst(!rst_n),
			 .en(sel),
	         .d(slv_err_temp),      
             .q(slv_err));
			 
			 

//enable signals for writing in registers
wire en_ctrl;
wire en_data0;
wire en_data1;

assign en_ctrl = (sel & addr_0 & !slv_err_temp);
assign en_data0 = (sel & addr_1 & !slv_err_temp);
assign en_data1 = (sel & addr_2 & !slv_err_temp);



//r_en for FIFO_OUT and for writing in REG_RES

assign r_en_out = (addr_3 & !slv_err_temp & sel);  //also rst for reg_res



//generateing w_en_in for FIFO_IN

d_ff_async #(.SIZE(1),
             .RESET_VALUE(1'b0))
    w_en_in_reg(.clk(clk),
             .rst(!rst_n),
             .d(write & !slv_err & (start_bit == 1)),
             .q(w_en_in));

		 


endmodule
