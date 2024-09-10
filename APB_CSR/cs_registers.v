module cs_registers (
clk,
rst_n,
en_ctrl,
en_data0,
en_data1,
w_en_in,
full_out,
empty_out,
wdata,
csr_data,
fifo_out_data,
r_en_out,
start_bit,
final_result,
fifo_out_status
);

//The registers of the CSR unit. Any control signals are produced in csr_control.v

parameter OPERATION_BIT   = 1; 
parameter OPERATION_SIZE  = 2; 
parameter ID_SIZE         = 8;
parameter ID_BIT          = 8;

parameter APB_BUS_SIZE    = 32;
parameter DATA_SIZE       = 16;
parameter FIFO_OUT_WIDTH  = 25;
parameter FIFO_IN_WIDTH = ((2*DATA_SIZE) + ID_SIZE + OPERATION_SIZE);


input                             clk;
input                             rst_n;

//From csr_control
input	 						  en_ctrl;
input 							  en_data0;
input 							  en_data1;
input 							  r_en_out;
input 						      w_en_in;

//From FIFO_IN
input full_out;
input empty_out;


//From APB ports
input [(APB_BUS_SIZE-1):0]	          wdata;

//from FIFO_OUT
input [(FIFO_OUT_WIDTH-1):0]	  fifo_out_data;


//to FIFO_IN
output 	[(FIFO_IN_WIDTH-1):0]     csr_data;	
	

//to csr_control
output start_bit;


output [(FIFO_OUT_WIDTH-1):0]	  final_result;
output [(FIFO_OUT_WIDTH-1):0] 	  fifo_out_status;

//Register CTRL  

wire [(ID_SIZE-1):0] id_out;

//id Register
d_ff_async_en #(.SIZE(ID_SIZE),
             .RESET_VALUE(0))
    id_reg(.clk(clk),
             .rst(!rst_n),
			 .en(en_ctrl),
             .d(wdata[ID_BIT +: ID_SIZE]),
             .q(id_out));

//operation Register

wire [(OPERATION_SIZE-1):0] op_out;

d_ff_async_en #(.SIZE(OPERATION_SIZE),
             .RESET_VALUE(0))
    operation_reg(.clk(clk),
             .rst(!rst_n),
			 .en(en_ctrl),
             .d(wdata[OPERATION_BIT +: OPERATION_SIZE]),
             .q(op_out));


//start bit register 
	
wire clear_start;
		 
d_ff_async_en #(.SIZE(1),
             .RESET_VALUE(0))
    start_reg(.clk(clk),
				  .rst(!rst_n | clear_start),
				  .en(en_ctrl),
				  .d(wdata[0]),
				  .q(start_bit));
              
   

//for self-clearing the start bit

d_ff_async_en #(.SIZE(1),
             .RESET_VALUE(1'b0))
    w_en_in_dly_reg(.clk(clk),
             .rst(!rst_n),
			 .en(1'b1),
             .d(w_en_in),
             .q(clear_start));
   
		 

//Register DATA_0

wire [(APB_BUS_SIZE-1):0] data_0_out;

d_ff_async_en #(.SIZE(APB_BUS_SIZE),
             .RESET_VALUE(0))
    data0_reg(.clk(clk),
              .rst(!rst_n),
			  .en(en_data0),
              .d(wdata),
              .q(data_0_out));




//Register DATA_1

wire [(APB_BUS_SIZE-1):0] data_1_out;

d_ff_async_en #(.SIZE(APB_BUS_SIZE),
             .RESET_VALUE(0))
    data1_reg(.clk(clk),
              .rst(!rst_n),
			  .en(en_data1),
              .d(wdata),
              .q(data_1_out));
     
	 

//Output data to FIFO_IN

assign csr_data = {data_1_out[0 +:DATA_SIZE], data_0_out[0 +:DATA_SIZE], id_out, op_out};



//Register RESULT


d_ff_async_en #(.SIZE(FIFO_OUT_WIDTH),
             .RESET_VALUE(0))
    res_reg(.clk(clk),
            .rst(!rst_n | !r_en_out),
			.en(1'b1),
            .d(fifo_out_data),
            .q(final_result));
			 
	
//Register monitor

wire [(FIFO_OUT_WIDTH-1) : 0] fifo_out_status_in;
assign fifo_out_status_in = {{(FIFO_OUT_WIDTH - 2){1'b0}},full_out, empty_out};

d_ff_async_en #(.SIZE(FIFO_OUT_WIDTH),
             .RESET_VALUE(0))
    monitor_reg(.clk(clk),
            .rst(!rst_n),
			.en(1'b1),
            .d(fifo_out_status_in),
            .q(fifo_out_status));
			
			
endmodule


