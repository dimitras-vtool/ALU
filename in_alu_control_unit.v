module in_alu_control_unit (
clk,
rst_n,
a_ready_data,
m_ready_data,
op_start,
fifo_data,
empty_in,
a_valid_data,
m_valid_data,
add_1,
add_2,
a_in,
b_in,
r_en_in,
id_add,
id_mul
);

// The control unit responsible for the communication between FIFO_IN and CSR module, mainly. For more details read documentation.


//CTRL 
parameter OPERATION_BIT  = 1;    //The lowest bit position storing the operation in CTRL_REG (and also in FIFO, 
						         //since in the fifo memory they are saved as {data1, data0, ctrl}).
parameter OPERATION_SIZE = 2;   //(example: if bits 2 and 1 of ctrl_data are 01 for ADD and 10 for MUL, OPERATION_BIT would be 1).
parameter ID_SIZE        = 8;
parameter ID_BIT         = 8; 	//The lowest bit position storing the ID in CTRL_REG.

parameter DATA0_BIT      = 10;
parameter DATA1_BIT      = 26;					     
parameter DATA_SIZE      = 16;

parameter FIFO_IN_WIDTH  = ((2*DATA_SIZE) + ID_SIZE + OPERATION_SIZE);
  
   
input clk;
input rst_n;   
   
//From ALU
input a_ready_data;
input m_ready_data;
input op_start;

//From FIFO_IN
input [(FIFO_IN_WIDTH-1):0] fifo_data;
input 						empty_in;

//To ALU
output a_valid_data;
output m_valid_data;

////ADD ports
output [(DATA_SIZE-1):0] add_1;
output [(DATA_SIZE-1):0] add_2;
output [(ID_SIZE-1):0] 	 id_add;

////MUL ports
output [((DATA_SIZE/2)-1):0] a_in;
output [((DATA_SIZE/2)-1):0] b_in;
output [(ID_SIZE-1):0] 		 id_mul;

//To FIFO_IN
output r_en_in;



//r_en for reading from FIFO_IN and generating valid_f_data to the ALU					// r_en_in 
//there can only be 1 read at a time -> single pulse

wire data_reg_en;
wire r_en_in_gen;
wire data_reg_en_temp;
wire r_en_in_dly;

wire addition;
wire multiplication;  

assign data_reg_en_temp = ((a_ready_data | m_ready_data) & !empty_in);  //-> reads when there are data on queue -> fix it
		
	d_ff_async_en #(.SIZE(1),
					.RESET_VALUE(1'b0))
		r_en_in_reg(.clk(clk),
					.rst(!rst_n ),
					.en(1'b1),
					.d(data_reg_en_temp),
					.q(data_reg_en));	
									
assign r_en_in = ((a_ready_data | m_ready_data) & !(a_valid_data | m_valid_data) & !empty_in & !r_en_in_dly & !(addition | multiplication));


//registers between FIFO_IN and ALU 

wire [(DATA_SIZE-1):0] opperant_1;

d_ff_async_en #(.SIZE(DATA_SIZE),											    //data0 reg
                .RESET_VALUE(0))
    f_data0_reg(.clk(clk),
              .rst(!rst_n),
			  .en(data_reg_en), 
              .d(fifo_data[DATA0_BIT +:DATA_SIZE]),
              .q(opperant_1));
			  
wire [(DATA_SIZE-1):0] opperant_2;

d_ff_async_en #(.SIZE(DATA_SIZE),												//data1 reg
                .RESET_VALUE(0))
    f_data1_reg(.clk(clk),
              .rst(!rst_n),
			  .en(data_reg_en),  
              .d(fifo_data[DATA1_BIT +:DATA_SIZE]),
              .q(opperant_2));

wire [(ID_SIZE-1):0] id;

d_ff_async_en #(.SIZE(ID_SIZE),													//id reg
                .RESET_VALUE(0))
    id_reg(.clk(clk),
              .rst(!rst_n),
			  .en(data_reg_en),  
              .d(fifo_data[(ID_BIT-6) +:ID_SIZE]),
              .q(id));




//op registers
			  
wire op_bit_add;

assign op_bit_add = ((fifo_data[(OPERATION_BIT-1) +: OPERATION_SIZE] == 2'b01));


d_ff_async_en #(.SIZE(1),
                .RESET_VALUE(0))
    op_en_reg(.clk(clk),
              .rst(!rst_n),																//op_add reg
			  .en(1'b1),
              .d(r_en_in),
              .q(r_en_in_dly));
	

d_ff_async_en #(.SIZE(1),
                .RESET_VALUE(0))
    op_add_reg(.clk(clk),
              .rst(!rst_n | op_start),																//op_add reg
	      .en(r_en_in_dly),
              .d(op_bit_add),
              .q(addition));
	
	
wire op_bit_mul;

assign op_bit_mul = ((fifo_data[(OPERATION_BIT-1) +: OPERATION_SIZE] == 2'b10));

d_ff_async_en #(.SIZE(1),																			//op_mul reg
                .RESET_VALUE(0))
    op_mul_reg(.clk(clk),
              .rst(!rst_n | op_start),
			  .en(r_en_in_dly),
              .d(op_bit_mul),
              .q(multiplication));



//signaling if there are valid data in the register for the ALU

//add

wire a_valid;

assign a_valid = (addition /*& a_ready_data*/);										

d_ff_async_en #(.SIZE(1),
                .RESET_VALUE(1'b0))
      a_valid_data_reg(.clk(clk),
                 .rst(!rst_n),
		 .en(a_ready_data),
                 .d(addition),
                 .q(a_valid_data));
				


//mul
			 
wire m_valid;

assign m_valid = (multiplication /*& m_ready_data*/);							  

d_ff_async_en #(.SIZE(1),
                .RESET_VALUE(1'b0))
      m_valid_data_reg(.clk(clk),
                 .rst(!rst_n | !m_ready_data),
		 .en(1'b1),
                 .d(multiplication),
                 .q(m_valid_data));



//Setting fifo_data direclty as inputs to the ALU

assign add_1 = opperant_1;
assign add_2 = opperant_2;

assign a_in = opperant_1[(DATA_SIZE/2):0];			  //only 8x8 bit multiplication, so FIFO_OUT => 16bit either way (add and mul results)
assign b_in = opperant_2[(DATA_SIZE/2):0];

assign id_add = id;
assign id_mul = id;


endmodule
