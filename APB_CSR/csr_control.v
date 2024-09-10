module csr_control (
clk,   
rst_n,
addr,
sel,
en,
write,
ctrl_op,
start_bit,
fifo_out_status,
final_result,
full_in,
empty_out,
slv_err,
ready,
en_ctrl ,
en_data0,
en_data1,
r_en_out,
w_en_in,
rdata
);

//Contol unit of the control_status registers. An APB slave is implemented and the en signals for the registers are produced.       

parameter REG_NUMBER      = 5;       //How many registers we have.

parameter REG_CTRL        = 0;
parameter REG_0           = 1;
parameter REG_1           = 2;
parameter REG_RES         = 3;
parameter REG_STATUS      = 4;

parameter OPERATION_SIZE  = 2;
parameter FIFO_OUT_WIDTH  = 25;

parameter APB_BUS_SIZE    = 32;

//APB
input                              clk;   
input                              rst_n;
input [($clog2(REG_NUMBER) -1):0]  addr;
input                              sel;
input                              en;
input                              write;
input [(OPERATION_SIZE-1) :0]	   ctrl_op;


//From CS registers
input 							   start_bit;
input [(FIFO_OUT_WIDTH-1):0]	   final_result;
input [(FIFO_OUT_WIDTH-1):0] 	   fifo_out_status;


//from FIFO_IN
input							   full_in;

//From FIFO_OUT
input 							   empty_out;

//APB
output                             slv_err;
output reg                         ready;

//CS Registers
output                			   en_ctrl;
output 							   en_data0;
output							   en_data1;

//to FIFO_OUT
output							   r_en_out;

//TO FIFO_IN
output 							   w_en_in;

//APB 
output reg [(APB_BUS_SIZE-1):0]      rdata;



//address for registers

wire addr_0;
wire addr_1;
wire addr_2;
wire addr_3;
wire addr_4;

assign addr_0 = (addr == REG_CTRL);
assign addr_1 = (addr == REG_0);
assign addr_2 = (addr == REG_1);
assign addr_3 = (addr == REG_RES);
assign addr_4 = (addr == REG_STATUS);


//Ready
wire ready_no_wait;
  
d_ff_async_en #(.SIZE(1),
		        .RESET_VALUE(0))
	 d_ready_no_wait(.clk(clk),
	          .rst(!rst_n | !sel),
	          .en(1'b1),
	          .d(1'b1),        //There are no wait states
              .q(ready_no_wait));



//2nd register for the extra wait cycle 
wire ready_wait;

d_ff_async_en #(.SIZE(1),
		     .RESET_VALUE(0))
	 d_ready_wait(.clk(clk),
	          .rst(!rst_n | !sel),
			  .en(1'b1),
	          .d(ready_no_wait),        //There are no wait states
              .q(ready_wait));



//Mux for ready (with a wait state for reading from FIFO_OUT)

wire [4:0] ready_mux_sel;
assign ready_mux_sel = {sel,write,slv_err, addr_3, addr_4};

always@(*)begin
	case(ready_mux_sel)
		5'b11000: ready = ready_no_wait;
		5'b10010: ready = ready_wait;
		5'b10001: ready = ready_no_wait;
		default: ready = 1'b0;
	endcase
end


//errors
wire write_err;
assign write_err = ((addr_3 | addr_4) & write & (en == 1'b1));

wire read_err;
assign read_err = ((addr_1 | addr_2 | addr_3) & !write & (en == 1'b1));

wire addr_err;
assign addr_err = (addr >= REG_NUMBER & (en == 1'b1));

wire empty_err;
assign empty_err = (empty_out & addr_3 & !write & (en == 1'b1));

wire full_err;
assign full_err = (full_in & (addr_0 | addr_1 | addr_2) & write & (en == 1'b1));

wire op_err;
assign op_err = (!(ctrl_op == 2'b01 | ctrl_op == 2'b10) & write & (addr == REG_CTRL) & (en == 1'b1));

          
//slv_err
assign slv_err = (write_err | read_err | addr_err | full_err | empty_err | op_err);

/*
d_ff_async_en #(.SIZE(1),
		     .RESET_VALUE(0))
	 err_reg(.clk(clk),
	         .rst(!rst_n),
			 .en(sel),
	         .d(slv_err_temp),      
             .q(slv_err));
			 
	*/		 

//enable signals for writing in registers

//assign en_ctrl  = (sel & addr_0 & !slv_err_temp);
//assign en_data0 = (sel & addr_1 & !slv_err_temp);
//assign en_data1 = (sel & addr_2 & !slv_err_temp);

posedge_detector 
    en_ctrl_posedg_detect(.clk(clk),
                          .rst_n(rst_n),
                          .sig_to_detect(addr_0 & !slv_err & en),
                          .positive_edge(en_ctrl));

posedge_detector 
    en_data0_posedg_detect(.clk(clk),
                           .rst_n(rst_n),
                           .sig_to_detect(addr_1 & !slv_err & en),
                           .positive_edge(en_data0));
posedge_detector 
    en_data1_posedg_detect(.clk(clk),
                           .rst_n(rst_n),
                           .sig_to_detect(addr_2 & !slv_err & en),
                           .positive_edge(en_data1));

//r_en for FIFO_OUT and for writing in REG_RES

assign r_en_out = ((addr_3 | addr_4) & !slv_err & sel & !write);  //also rst for reg_res



//generateing w_en_in for FIFO_IN

d_ff_async_en #(.SIZE(1),
             .RESET_VALUE(1'b0))
    w_en_in_reg(.clk(clk),
             .rst(!rst_n),
			 .en(1'b1),
             .d(!full_in & (start_bit == 1)),
             .q(w_en_in));

		 
//MUX for rdata

wire [4:0] mux_sel;
assign mux_sel = {sel, write, addr_3, addr_4, slv_err};

always@(*)begin
	case(mux_sel)
		5'b10100 : rdata = final_result;
		5'b10010 : rdata = fifo_out_status;
	default: rdata = {FIFO_OUT_WIDTH{1'b0}};
	endcase
end

endmodule
