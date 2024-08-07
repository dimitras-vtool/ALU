module ABP_CSR_top_module (
clk,
rst_n,
addr,
sel,
en,
write,
wdata,
full_in,
full_out,
empty_out,
slv_err,
ready,
csr_data,
fifo_out_data,
rdata,
r_en_out,
w_en_in
);

//A top module including the control-status registers and their communication via APB or with the rest of the ALU design.   
   
parameter REG_NUMBER = 5;       //How many registers we have.

parameter REG_CTRL   = 0;
parameter REG_0      = 1;
parameter REG_1      = 2;
parameter REG_RES    = 3;
parameter REG_STATUS = 4;

parameter OPERATION_BIT  = 1; 
parameter OPERATION_SIZE = 2; 
parameter ID_SIZE        = 8;
parameter ID_BIT         = 8;

parameter DATA_SIZE      = 16;
parameter FIFO_OUT_WIDTH = 25;

parameter FIFO_IN_WIDTH  = (DATA_SIZE + DATA_SIZE + ID_SIZE + OPERATION_SIZE);

parameter APB_BUS_SIZE   = 32;



////INPUTS
input clk;
input rst_n;

//APB
input [($clog2(REG_NUMBER) -1):0] addr;
input sel;
input en;
input write;

input [(APB_BUS_SIZE-1):0]     wdata;

//From FIFO_IN
input full_in;

//From FIFO_OUT
input [(FIFO_OUT_WIDTH-1):0]	  fifo_out_data;
input 							  empty_out;
input 						      full_out;


////OUTPUTS
output slv_err;
output ready;

//To FIFO_IN
output [(FIFO_IN_WIDTH-1):0]  csr_data;
output 						  w_en_in;

//To FIFO_OUT
output 							  r_en_out;
output	[(APB_BUS_SIZE-1):0]    rdata;

//INTERNAL WIRES

wire en_ctrl;
wire en_data0;
wire en_data1;
wire en_res;

wire start_bit;

wire [(FIFO_OUT_WIDTH-1):0]	  final_result;
wire [(FIFO_OUT_WIDTH-1):0]	  fifo_out_status;

  csr_control#(.APB_BUS_SIZE(APB_BUS_SIZE),
			  .REG_NUMBER(REG_NUMBER),
             .REG_CTRL(REG_CTRL),    
             .REG_0(REG_0),       
             .REG_1(REG_1),
			 .REG_RES(REG_RES),
			 .REG_STATUS(REG_STATUS),
			 .OPERATION_SIZE(OPERATION_SIZE),
			 .FIFO_OUT_WIDTH(FIFO_OUT_WIDTH))
   csr_control_inst(.clk(clk),   
				.rst_n(rst_n),
				.addr(addr),
				.sel(sel),
				.en(en),
				.write(write),
				.ctrl_op(wdata[OPERATION_BIT +:OPERATION_SIZE]),
				.start_bit(start_bit),
				.fifo_out_status(fifo_out_status),
				.final_result(final_result),
				.full_in(full_in),
				.empty_out(empty_out),
				.slv_err(slv_err),
				.ready(ready),
				.en_ctrl(en_ctrl),
				.en_data0(en_data0),
				.en_data1(en_data1),
				.r_en_out(r_en_out),
				.w_en_in(w_en_in),
				.rdata(rdata));


  cs_registers#(.APB_BUS_SIZE(APB_BUS_SIZE),
				.DATA_SIZE(DATA_SIZE),
				.FIFO_OUT_WIDTH(FIFO_OUT_WIDTH),
				.FIFO_IN_WIDTH(FIFO_IN_WIDTH),
			    .OPERATION_BIT (OPERATION_BIT),
			    .OPERATION_SIZE(OPERATION_SIZE),
			    .ID_SIZE(ID_SIZE),
			    .ID_BIT(ID_BIT))
	cs_regs(.clk(clk),
			.rst_n(rst_n),
			.en_ctrl(en_ctrl),
			.en_data0(en_data0),
			.en_data1(en_data1),
			.r_en_out(r_en_out),
			.empty_out(empty_out),
			.full_out(full_out),
			.wdata(wdata),
			.csr_data(csr_data),
			.final_result(final_result),
			.fifo_out_status(fifo_out_status),
			.fifo_out_data(fifo_out_data),
			.start_bit(start_bit),
			.w_en_in(w_en_in));




endmodule
