module adder(
clk,
rst_n,
add_1,
add_2,
id_add,
c_in,
a_valid_data,
ready_f_res,
sum_written,
a_valid_res,
a_ready_data,
result_add,
start
);

//The adder of the ALU as seen in the top module diagram. Apart from producing the result, this file includes the handshake generation.

parameter DATA_SIZE = 16;
parameter ID_SIZE = 8; 

localparam ADD_COUNTER_SIZE = ($clog2(DATA_SIZE)+1);

localparam IDLE = 0 , /*INITIAL = 1,*/ ADD = 1, SUM = 2;

input clk;
input rst_n;

//From IN_ALU 
input a_valid_data;           //fifo_in has valid availiable data
input [(DATA_SIZE-1) :0] add_1;
input [(DATA_SIZE-1) :0] add_2;
input [(ID_SIZE-1):0]    id_add;
input 					 c_in;

//From OUT_ALU
input ready_f_res;  		 //FIFO_OUT has room to store results
input sum_written;

//To OUT_ALU
output reg  a_valid_res;

//To IN_ALU 
output reg  a_ready_data;
output 		start;

//To OUT_ALU
output [((DATA_SIZE + 1 + ID_SIZE)-1) : 0] result_add;




//Start/stop signals  
wire  [2:0] state;

assign start_temp = ((state == IDLE) & (a_valid_data /*& ready_f_res*/));

d_ff_async_en #(.SIZE(1),
             .RESET_VALUE(1'b0))
       add_start_reg(.clk(clk),
					 .rst(!rst_n),
					 .en(1'b1),
					 .d(start_temp),
					 .q(start));


//Registers where valid data will be loaded at the beginning of the operation

wire [(DATA_SIZE-1) :0] v_add_1;
wire [(DATA_SIZE-1) :0] v_add_2;
wire [(ID_SIZE-1)   :0] id_add_out;

reg en_reg_1;
reg en_reg_2;
reg en_reg_id_a;

d_ff_async_en #(.SIZE(DATA_SIZE), 
             .RESET_VALUE({DATA_SIZE{1'b0}}))      //add_1
      add_1_reg(.clk(clk),
                 .rst(!rst_n),
                 .en(en_reg_1),
                 .d(add_1),
                 .q(v_add_1));

d_ff_async_en #(.SIZE(DATA_SIZE),
             .RESET_VALUE({DATA_SIZE{1'b0}}))      //add_2
      add_2_reg(.clk(clk),
                 .rst(!rst_n),
                 .en(en_reg_2),
                 .d(add_2),
                 .q(v_add_2));  

d_ff_async_en #(.SIZE(ID_SIZE),
             .RESET_VALUE({ID_SIZE{1'b0}}))      //id_add
      id_add_reg(.clk(clk),
                 .rst(!rst_n),
                 .en(en_reg_id_a),
                 .d(id_add),
                 .q(id_add_out));  



//DATA_SIZE bit carry-look ahead adder

wire [(DATA_SIZE-1) :0] sum;
wire c_out;

add_sub #(.DATA_SIZE(DATA_SIZE))
    adder_16bit(.a1(v_add_1),
              .b(v_add_2),
              .cin(1'b0),
              .operation(1'b1),
              .s(sum),
              .cout(c_out));


////FSM 

//State transition
reg  [2:0] next_state;


d_ff_async #(.SIZE(3),
             .RESET_VALUE(IDLE))
       add_fsm_reg(.clk(clk),
                .rst(!rst_n),
                 .d(next_state),
                 .q(state));

 

//next-state combinational logic

always@(*)begin  
      next_state = IDLE;
    case(state) 
        IDLE   : next_state = (start) ? ADD : IDLE;                 
		
        ADD    : next_state = SUM ;

        SUM    : next_state = (sum_written) ? IDLE : SUM;

        default: next_state = IDLE;
    endcase
end




//output logic


always@(*)begin
	   en_reg_1 = 1'b0;
       en_reg_2 = 1'b0;
	   en_reg_id_a = 1'b0;
	   a_valid_res = 1'b0;
	   a_ready_data = 1'b1;
    case(state)
        IDLE: begin
              en_reg_1     = (start_temp);
              en_reg_2     = (start_temp);
			  en_reg_id_a  = (start_temp);
			  a_ready_data = (ready_f_res);
              end
       
        ADD: begin
			 a_ready_data = 1'b0;
			 end
			 
        SUM: begin
			 a_valid_res = 1'b1;
			 a_ready_data = 1'b0;
			 end
		
        default: begin
			    en_reg_1 = 1'b0;
				en_reg_2 = 1'b0;
				en_reg_id_a = 1'b0;
				a_valid_res = 1'b0; 
 	    	    a_ready_data = 1'b1;
                 end
    endcase

end


//data for FIFO_OUT

assign result_add = {id_add_out , c_out ,sum};

endmodule
