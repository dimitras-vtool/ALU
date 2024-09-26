module alu_top_module(
clk,
rst_n,
sel,
en,
addr,
write,
wdata,
slv_err,
ready,
rdata
);

//CSR parameters
parameter REG_NUMBER     = 5;       //How many registers we have.
parameter ADDRESS_SIZE   = ($clog2(REG_NUMBER));       
parameter REG_CTRL       = 0;
parameter REG_0          = 1;
parameter REG_1          = 2;
parameter REG_RES 		 = 3;
parameter REG_STATUS	 = 4;
parameter DATA_SIZE      = 16;
parameter APB_BUS_SIZE   = 32;

parameter MUL_DATA_SIZE = (DATA_SIZE/2);

//in alu control unit
parameter OPERATION_BIT  = 1;        //16bit -> 1 
parameter OPERATION_SIZE = 2; 		 //16bit -> 2 
parameter ID_SIZE        = 8;		 //16bit -> 2 
parameter ID_BIT         = 8; 		 //16bit -> 8 
parameter DATA0_BIT      = 10;		 //16bit -> 10
parameter DATA1_BIT      = 26;		 //16bit -> 26

//FIFO parameters
parameter FIFO_IN_WIDTH  = (DATA_SIZE + DATA_SIZE + ID_SIZE + OPERATION_SIZE);
parameter FIFO_OUT_WIDTH = (DATA_SIZE + 1 + ID_SIZE);
parameter FIFO_IN_DEPTH  = 4;
parameter FIFO_OUT_DEPTH = 4;
parameter MEM_IP         = 0;

//APB Ports

input clk;
input rst_n;
input sel;
input en;
input [(ADDRESS_SIZE - 1):0] addr;
input write;

input  [(APB_BUS_SIZE-1):0]   wdata;

output slv_err;
output ready;
output [(APB_BUS_SIZE-1):0] rdata;


//Internal wires

///////Generated from:

//CSR
wire w_en_in;
wire r_en_out;
wire [(FIFO_IN_WIDTH-1):0]  csr_data;



//FIFO_IN

wire full_in;
wire empty_in;
wire [(FIFO_IN_WIDTH-1):0]  fifo_in_data;


//in_alu control unit
wire r_en_in;
wire a_valid_data;
wire m_valid_data;

wire [(DATA_SIZE-1):0] add_1;
wire [(DATA_SIZE-1):0] add_2;

wire [((DATA_SIZE/2)-1):0] a_in;
wire [((DATA_SIZE/2)-1):0] b_in;

wire [(ID_SIZE-1):0] id_add;
wire [(ID_SIZE-1):0] id_mul;


//ADD
wire a_ready_data;
wire a_valid_res;
wire [(FIFO_OUT_WIDTH-1):0] result_add;
wire add_start;

//MUL
wire m_ready_data;
wire m_valid_res;
wire [(FIFO_OUT_WIDTH-1):0] result_mul;
wire mul_start;

//out_alu_control_unit

wire [(FIFO_OUT_WIDTH-1):0] fifo_res;      //wdata of FIFO_OUT
wire w_en_out;
wire sum_written;
wire mul_written;


//FIFO_OUT
wire empty_out;
wire full_out;
wire [(FIFO_OUT_WIDTH-1):0] fifo_out_data; //rdata of FIFO_OUT


//CSR

APB_CSR_top_module#(.APB_BUS_SIZE(APB_BUS_SIZE),
					.DATA_SIZE(DATA_SIZE),
                    .REG_NUMBER(REG_NUMBER),   
                    .REG_CTRL(REG_CTRL),      
                    .REG_0(REG_0),         
                    .REG_1(REG_1),
					.REG_RES(REG_RES),
					.REG_STATUS(REG_STATUS),
					.FIFO_OUT_WIDTH(FIFO_OUT_WIDTH),
					.FIFO_IN_WIDTH(FIFO_IN_WIDTH),
					.OPERATION_BIT (OPERATION_BIT),
					.OPERATION_SIZE(OPERATION_SIZE),
					.ID_SIZE(ID_SIZE),
					.ID_BIT(ID_BIT))
		csr_inst(.clk(clk),
				 .rst_n(rst_n),
				 .addr(addr),
				 .sel(sel),
				 .en(en),
				 .write(write),
				 .wdata(wdata),
				 .full_in(full_in),
				 .empty_out(empty_out),
				 .full_out(full_out),
				 .slv_err(slv_err),
				 .ready(ready),
				 .csr_data(csr_data),
				 .w_en_in(w_en_in),
				 .r_en_out(r_en_out),
				 .fifo_out_data(fifo_out_data),
				 .rdata(rdata));



//FIFO_IN (data)

fifo_synch #(.MEM_IP(MEM_IP),
			 .MEMORY_WIDTH(FIFO_IN_WIDTH),
             .MEMORY_DEPTH(FIFO_IN_DEPTH), 
             .FIFO_ADDRESS_SIZE($clog2(FIFO_IN_DEPTH)))    
	fifo_in(.clk(clk),
			.rst_n(rst_n),
			.w_en(w_en_in),
			.r_en(r_en_in),
			.wdata(csr_data),
			.full(full_in),
			.empty(empty_in),
			.rdata(fifo_in_data));



//in_alu_control_unit

in_alu_control_unit#(.FIFO_IN_WIDTH(FIFO_IN_WIDTH),
                     .OPERATION_BIT(OPERATION_BIT),
                     .OPERATION_SIZE(OPERATION_SIZE),
                     .ID_SIZE(ID_SIZE),
                     .ID_BIT(ID_BIT),
                     .DATA0_BIT(DATA0_BIT),  
                     .DATA1_BIT(DATA1_BIT),
					 .DATA_SIZE(DATA_SIZE)) 
	   in_alu_control(.clk(clk),
					  .rst_n(rst_n),
					  .a_ready_data(a_ready_data),
					  .m_ready_data(m_ready_data),
					  .op_start(mul_start | add_start),
					  .fifo_data(fifo_in_data),
					  .empty_in(empty_in),
					  .a_valid_data(a_valid_data),
					  .m_valid_data(m_valid_data),
					  .add_1(add_1),
					  .add_2(add_2),
					  .a_in(a_in),
					  .b_in(b_in),
					  .r_en_in(r_en_in),
					  .id_add(id_add),
					  .id_mul(id_mul));
					  
//ADDER

adder #(.DATA_SIZE(DATA_SIZE),
          .ID_SIZE(ID_SIZE))
	alu_adder(.clk(clk),
			  .rst_n(rst_n),
			  .add_1(add_1),
			  .add_2(add_2),
			  .c_in(1'b0),
			  .id_add(id_add),
			  .a_valid_data(a_valid_data),
			  .ready_f_res(!full_out),
			  .sum_written(sum_written),
			  .a_valid_res(a_valid_res),
			  .a_ready_data(a_ready_data),
			  .result_add(result_add),
			  .start(add_start));
			  
			  
			  
//MULTIPLIER

mul_fsm#(.MUL_DATA_SIZE(MUL_DATA_SIZE),
		 .DATA_SIZE(DATA_SIZE),
		 .ID_SIZE(ID_SIZE))
	alu_mul(.clk(clk),
			.rst_n(rst_n),
			.a_in(a_in),
			.b_in(b_in),
			.id_mul(id_mul),
			.m_valid_data(m_valid_data),
			.ready_f_res(!full_out),
			.mul_written(mul_written),
			.m_valid_res(m_valid_res),
			.result_mul(result_mul),
			.m_ready_data(m_ready_data),
			.start(mul_start));
			


//out_alu_control_unit

out_alu_control_unit#(.FIFO_OUT_WIDTH(FIFO_OUT_WIDTH),
					  .DATA_SIZE(DATA_SIZE),
					  .MUL_DATA_SIZE(MUL_DATA_SIZE),
					  .ID_SIZE(ID_SIZE))
	out_alu_control(.clk(clk),
					.rst_n(rst_n),
					.a_valid_res(a_valid_res),
					.m_valid_res(m_valid_res),
					.result_add(result_add),
					.result_mul(result_mul),
					.ready_f_res(!full_out),
					.fifo_res(fifo_res),
					.sum_written(sum_written),
					.mul_written(mul_written),
					.w_en_out(w_en_out));



			 
			
//FIFO_OUT (result)


fifo_synch #(.MEM_IP(MEM_IP),
			 .MEMORY_WIDTH(FIFO_OUT_WIDTH),
             .MEMORY_DEPTH(FIFO_OUT_DEPTH), 
             .FIFO_ADDRESS_SIZE($clog2(FIFO_IN_DEPTH)))    
	fifo_out(.clk(clk),
			.rst_n(rst_n),
			.w_en(w_en_out),
			.r_en(r_en_out),
			.wdata(fifo_res),
			.full(full_out),
			.empty(empty_out),
			.rdata(fifo_out_data));

	
					
endmodule   
