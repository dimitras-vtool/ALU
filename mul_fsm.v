module mul_fsm(
clk,
rst_n,
a_in,
b_in,
id_mul,
m_valid_data,
ready_f_res,
mul_written,
m_valid_res,
m_ready_data,
result_mul,
start
);

//The multiplier of the ALU. There is a shift and add algorithm implemented. A 16-bit carry look-ahead adder is used.

parameter DATA_SIZE     = 16;
parameter MUL_DATA_SIZE = (DATA_SIZE/2);
parameter ID_SIZE       = 8; 
localparam MUL_COUNTER_SIZE = ($clog2(MUL_DATA_SIZE)+1);  //Counter needs to count MUL_DATA_SIZE times, before the multiplication ends
                                                     //It the number of shifts that have occured 

localparam IDLE = 0, INITIAL = 1, TEST = 2, ADD = 3, SHIFT = 4, SAVE = 5;

input clk;
input rst_n;
input [(MUL_DATA_SIZE-1):0] a_in;
input [(MUL_DATA_SIZE-1):0] b_in;
input [(ID_SIZE-1):0]     id_mul;
input m_valid_data;        //The FIFO providing the data (FIFO_in) has valid data (not empty & operation = multiplication)
input ready_f_res;         //The FIFO were the results will be saved, can store more data (not full)
input mul_written;

output reg m_ready_data;     //Signal, to FIFO in, that the previous multiplication has ended, thus the multiplier is ready to start a new one
output reg m_valid_res;      //Signal that a multiplication has ended and the result is ready to be stored in FIFO out
output [((DATA_SIZE + 1 + ID_SIZE)-1):0] result_mul;
output start;



//Start / stop signals

wire [2:0] state;
wire start_temp;
wire done;
reg  done_temp;
wire stop;

wire [(MUL_COUNTER_SIZE-1):0] counter_out;


assign stop = ((counter_out == MUL_DATA_SIZE) );  //done signal -> the multiplication has finished and it goes low when a new one can begin


assign start_temp = ((state == IDLE) & m_valid_data);  //new data are ready to be read from the FIFO in and FIFO out has availiable space 


//Start/stop signals for the FSM

d_ff_async_en #(.SIZE(1),
             .RESET_VALUE(1'b0))
       start_reg  (.clk(clk),
                 .rst(!rst_n),
				 .en(1'b1),
                 .d(start_temp),
                 .q(start)); 



d_ff_async_en #(.SIZE(1),
             .RESET_VALUE(1'b0))
       done_reg  (.clk(clk),
                 .rst(!rst_n),
				 .en(1'b1),
                 .d(done_temp),
                 .q(done)); 



//Signals between multiplier and the FIFOs 


//reg inputs, outputs and enable signals for load/shift registers, controlled by FSM

wire [(MUL_DATA_SIZE-1):0]  mul_c;             //multiplicant (reg A)
wire [(MUL_DATA_SIZE-1):0]  multiplier_shift;  //multiplier (output of shift reg B)

wire [(MUL_DATA_SIZE-1):0] adder_in;  
wire [(MUL_DATA_SIZE-1):0] adder_out;  
wire [(MUL_DATA_SIZE-1):0] reg_c_out; 

reg shift_load_mul_r_regB;  //control signal for loading or shifting (1-> shift, 0-> load) reg B
reg shift_load_mul_c_regC;  //control signal for loading or shifting (1-> shift, 0-> load) reg C

reg en_regA;   //enable signal for load input a_in in the multiplicant register  (is 0 in IDLE state)
reg en_regB;   //enable signal for the shift register B, for the multiplier b_in (is 0 in IDLE state)
reg en_regC;   //enable signal for the shift register C, for the addition result (is 0 in IDLE state)
reg en_reg_id_m; //for id_reg


//(Shift) Registers

//Register holding multiplicant               (Reg_A)
//(loaded only once, along with reg B, 
//in the beginning of the mul opperation)                                             
         d_ff_async_en #(.SIZE(MUL_DATA_SIZE),
                         .RESET_VALUE({MUL_DATA_SIZE{1'b0}}))
             load_a_reg(.clk(clk),
                        .rst(!rst_n | done),
                        .en(en_regA),
                        .d(a_in),
                        .q(mul_c));



//Shift register for multiplier                (Reg_B)
//(loaded in the beggining of the operation,
//right-shifted every cycle (shift-input => reg_C[lsb]))       
        right_shift_register #(.DATA_SIZE(MUL_DATA_SIZE))
             shift_reg_B(.clk(clk),
                         .rst_n(rst_n ),
                         .en(en_regB),
                         .shift_load(shift_load_mul_r_regB),
                         .d(b_in),
                         .d_shift(reg_c_out[0]),
                         .q(multiplier_shift));


wire carry_out_reg;

//wire [(MUL_DATA_SIZE-1):0] reg_c_in;

//assign reg_c_in = (en_regA) ? a_in : adder_out; //MUX for loading reg_c in the beginnig of the operation and during

reg reg_c_rstn;
//Shift register for addition                  (Reg_C)
//(multiplicant + 0 or mul_c) result
           right_shift_register #(.DATA_SIZE(MUL_DATA_SIZE))
             shift_reg_C(.clk(clk),
                         .rst_n(rst_n & reg_c_rstn),
                         .en(en_regC),
                         .shift_load(shift_load_mul_c_regC),
                         .d(adder_out),
                         .d_shift(carry_out_reg),       //shift value is the carry_out from the previous addition
                         .q(reg_c_out));


//                                             (REG_ID)
wire [(ID_SIZE-1) : 0] id_mul_out;

d_ff_async_en #(.SIZE(ID_SIZE),
             .RESET_VALUE({ID_SIZE{1'b0}}))
      idd_mul_reg(.clk(clk),
                 .rst(!rst_n),
                 .en(en_reg_id_m),
                 .d(id_mul),
                 .q(id_mul_out)); 

//MUX and Adder

assign adder_in = (multiplier_shift[0]) ? mul_c : {MUL_DATA_SIZE{1'b0}};

wire carry_out;

add_sub #(.DATA_SIZE(MUL_DATA_SIZE))
    adder_mul(.a1(adder_in),
              .b(reg_c_out),
              .cin(1'b0),
              .operation(1'b1),
              .s(adder_out),
              .cout(carry_out));


//Register holding carry_out from the above addition
d_ff_async_en #(.SIZE(1),
             .RESET_VALUE(0))
       carry_reg(.clk(clk),
                 .rst(!rst_n),
		 .en(1'b1),
                 .d(carry_out),
                 .q(carry_out_reg)); 
 



//FSM 

//State transition

reg  [2:0] next_state;


d_ff_async_en #(.SIZE(3),
             .RESET_VALUE(IDLE))
       fsm_reg(.clk(clk),
                .rst(!rst_n),
		.en(1'b1),
                .d(next_state),
                .q(state));



//next-state combinational logic

always@(*)begin  
      next_state = IDLE;
    case(state) 
        IDLE   : next_state = (start) ? INITIAL : IDLE;                 

        INITIAL: next_state = TEST;  

        TEST   : next_state = (multiplier_shift[0]) ? ADD : SHIFT;

        ADD    : next_state = SHIFT;

        SHIFT  : next_state = (stop) ? SAVE : TEST;
		
	SAVE   : next_state = (mul_written) ? IDLE : SAVE;

        default: next_state = IDLE;
    endcase
end



//output logic
reg counter_en;


always@(*)begin
	  counter_en  = 1'b0;
      done_temp   = 1'b0;
      en_regA     = 1'b0;
      en_regB     = 1'b0;
      en_regC     = 1'b0;
      reg_c_rstn  = 1'b1;
      shift_load_mul_r_regB   = 1'b0;
      shift_load_mul_c_regC   = 1'b0;
	  m_ready_data = 1'b0;
	  m_valid_res = 1'b0;
	  en_reg_id_m   = 1'b0;
    case(state)
        IDLE: begin
			  m_ready_data = (ready_f_res);
              en_regA = (start);
              en_regB = (start);
			  en_reg_id_m = (start);
	      reg_c_rstn = 1'b0;
              end
        TEST: begin
              en_regC = 1'b1;
              en_regB = (!multiplier_shift[0]);
			  counter_en = (!multiplier_shift[0]);
              shift_load_mul_r_regB   = (!multiplier_shift[0]);
              shift_load_mul_c_regC   = (!multiplier_shift[0]);
              end

        ADD: begin
            en_regC    = 1'b1;
            en_regB    = 1'b1;
			counter_en = 1'b1;
            shift_load_mul_r_regB = 1'b1;
            shift_load_mul_c_regC = 1'b1;
             end

        SHIFT: begin
               done_temp     = (stop);
               end
	SAVE: m_valid_res   = 1'b1;
		
        default: begin
			     counter_en  = 1'b0;
                 done_temp = 1'b0;
                 en_regA   = 1'b0;
                 en_regB   = 1'b0;
                 en_regC   = 1'b0;
	         reg_c_rstn = 1'b1;
                 shift_load_mul_r_regB   = 1'b0;
                 shift_load_mul_c_regC   = 1'b0;      
				 m_ready_data  = 1'b0;
				 m_valid_res   = 1'b0;	
				 en_reg_id_m   = 1'b0;				 
				end

    endcase


end




//Counter for counting the times the values shifted -> MUL_DATA_SIZE times before the operation ends

wire [(MUL_COUNTER_SIZE-1):0] counter_in;

d_ff_async_en #(.SIZE(MUL_COUNTER_SIZE),
             .RESET_VALUE({MUL_COUNTER_SIZE{1'b0}}))
      counter_mul(.clk(clk),
                 .rst(!rst_n | start_temp),
                 .en(counter_en),
                 .d(counter_in),
                 .q(counter_out)); 
 

assign counter_in = (done) ? {MUL_COUNTER_SIZE{1'b0}} : (next_state == SHIFT) ? (counter_out + 1'b1) : counter_out ;



//Result

wire [(DATA_SIZE-1):0] result;

assign result =  {reg_c_out,multiplier_shift};


//fifo_out result 

assign result_mul = {id_mul_out, 1'b0 ,result};


endmodule
