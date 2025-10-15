`timescale 1ns/1ps
`define CLK_PERIOD 10
module ALU_TB();


//CSR parameters
parameter APB_BUS_SIZE    = 32;
parameter ADDRESS_SIZE   = 2;       
parameter REG_NUMBER     = 4;       //How many registers we have.
parameter REG_CTRL       = 0;
parameter REG_0          = 1;
parameter REG_1          = 2;
parameter REG_RES 		 = 3;
parameter REG_STATUS     = 4;

parameter DATA_SIZE      = 16;
parameter MUL_DATA_SIZE  = (DATA_SIZE/2);

//in alu control unit
parameter OPERATION_BIT  = 1; 		//32bit -> 0   //position in ctrl_data
parameter OPERATION_SIZE = 2; 		//32bit -> 2   
parameter ID_BIT         = 8; 		//32bit -> 2   //position in ctrl_data
parameter ID_SIZE        = 8; 		//32bit -> 8   
parameter DATA0_BIT      = 10; 		//32bit -> 10  //position in csr_data (FIFO_IN)
parameter DATA1_BIT      = 26;		//32bit -> 26  //position in csr_data (FIFO_IN)	     

//FIFO parameters
parameter FIFO_OUT_WIDTH = (DATA_SIZE + 1 + ID_SIZE);
parameter FIFO_IN_WIDTH  = ((2*DATA_SIZE) + ID_SIZE + OPERATION_SIZE);
parameter FIFO_IN_DEPTH  = 4;
parameter FIFO_OUT_DEPTH = 4;
parameter MEM_IP         = 0;


reg clk;
reg rst_n;

reg sel;
reg en;
reg [(ADDRESS_SIZE -1):0] addr;
reg write;

reg  [(APB_BUS_SIZE-1):0]   wdata;

wire slv_err;
wire ready;
wire [(APB_BUS_SIZE-1):0] rdata;


alu_top_module#(.APB_BUS_SIZE(APB_BUS_SIZE),
				.ADDRESS_SIZE(ADDRESS_SIZE),
			    .DATA_SIZE(DATA_SIZE),
				.MUL_DATA_SIZE(MUL_DATA_SIZE),
                .REG_NUMBER(REG_NUMBER),   
                .REG_CTRL(REG_CTRL),      
                .REG_0(REG_0),         
                .REG_1(REG_1),
				.REG_RES(REG_RES),
				.REG_STATUS(REG_STATUS),
				.FIFO_IN_WIDTH (FIFO_IN_WIDTH),
				.FIFO_OUT_WIDTH(FIFO_OUT_WIDTH),
				.FIFO_IN_DEPTH (FIFO_IN_DEPTH),
				.FIFO_OUT_DEPTH(FIFO_OUT_DEPTH),
				.MEM_IP        (MEM_IP),
				.OPERATION_BIT (OPERATION_BIT),
				.OPERATION_SIZE(OPERATION_SIZE),
				.ID_SIZE       (ID_SIZE),
				.ID_BIT        (ID_BIT),
				.DATA0_BIT     (DATA0_BIT),
				.DATA1_BIT     (DATA1_BIT))
	alu_dut(.clk(clk),
			.rst_n(rst_n),
			.sel(sel),
			.en(en),
			.addr(addr),
			.write(write),
			.wdata(wdata),
			.slv_err(slv_err),
			.ready(ready),
			.rdata(rdata));


task init;
begin
	clk   = 1'b0;
	rst_n = 1'b0;
	sel   = 1'b0;
	en    = 1'b0;
	addr  = {ADDRESS_SIZE{1'b0}};
	write = 1'b0;
	wdata = {DATA_SIZE{1'b0}};
end
endtask


initial 
begin

	init();	
	
	#6;
	rst_n = 1'b1;
	
	main;
   
end


always #(`CLK_PERIOD/2)  clk = ~ clk;


task main; 
begin
	Write_32bit;
	#8; //time until start signal goes high (assuming the multiplier is ready as soon as the data are written)
	#300; // time needed for the operation to finish and the data written in the FIFO
	Read;
	#200;
	Read;
	Read;
	#100;
	$stop;
end
endtask


task Write_32bit;
begin
	
    //first operation -> id = 1010_1011
	apb_write(0,32'b0000_0000_0000_0000_1010_1011_0000_0010);  //ctrl_reg with start bit = 0
	apb_write(1,32'b0000_0000_0000_0000_0001_1101_0000_1011);
	apb_write(2,32'b0000_0000_0000_0000_1110_0000_0001_1110);
	apb_write(0,32'b0000_0000_0000_0000_1010_1011_0000_0011);  //ctrl_reg with start bit = 1 (op bit = 01 -> add)     result:1010_1011__0_1111_1101_0010_1001  (64.809)
	
	
	#2;
	//second operation -> id = 1001_1001
	apb_write(1,32'b0000_0000_0000_0000_0001_1101_0000_1011);
	apb_write(2,32'b0000_0000_0000_0000_1110_0000_0001_1110);
	apb_write(0,32'b0000_0000_0000_0000_1001_1001_0000_0101);  //(op bit = 10 -> mul)       result: 1001_1001__0_0000_0001_0100_1010 (330)
	
	#2;
	//third operation -> id = 0111_0011
	apb_write(1,32'b0000_0000_0000_0000_1101_1101_0110_0101); 
	apb_write(0,32'b0000_0000_0000_0000_0111_0011_0000_0101);  //(op bit = 10 -> mul)		result: 0111_0011__0_0000_1011_1101_0110 (3030)
																			  //0111_0011__0000_1111_1101_0110 (4054)
	#2;
	//fourth operation -> id = 1101_1000
	apb_write(2,32'b0000_0000_0000_0000_0011_1101_0101_0111);
	apb_write(0,32'b0000_0000_0000_0000_1101_1000_0000_0101);  //(op bit = 10 -> mul)      result: 1101_1000__0_0010_0010_0101_0011 (8787) 
																				  //0111_0011__0000_1111_1101_0110  (4054) 

	
	
end
endtask

task Write_5bit;
begin

    //first operation -> id = 11
	apb_write(0,5'b11010);  //ctrl_reg with start bit = 0
	apb_write(1,5'b10011);
	apb_write(2,5'b00111);
	apb_write(0,5'b11011);  //ctrl_reg with start bit = 1 (op bit = 01 -> add)     result:11__11010
	
	#2;
	//second operation -> id = 10
	apb_write(1,5'b01001);
	apb_write(2,5'b00110);
	apb_write(0,5'b10101);  //(op bit = 10 -> mul)      result: 10__00010
	
	#2;
	//third operation -> id = 01
	apb_write(1,5'b11110);
	apb_write(0,5'b01101);  //(op bit = 10 -> mul)		result:01__00100
	
	/*#2;
	//fourth operation -> id = 00
	apb_write(2,5'b10101);
	apb_write(0,5'b00101);  //(op bit = 10 -> mul)*/

	
	
end
endtask

task Write_6bit;
begin

    //first operation -> id = 110
	apb_write(0,6'b110100);  //ctrl_reg with start bit = 0
	apb_write(1,6'b100110);
	apb_write(2,6'b001110);
	apb_write(0,6'b110011);  //ctrl_reg with start bit = 1 (op bit = 01 -> add)     result: 110__11_0100
	
	#2;
	//second operation -> id = 101
	apb_write(1,6'b010010);
	apb_write(2,6'b001100);
	apb_write(0,6'b101101);  //(op bit = 10 -> mul)      result: 101__00_1000
	
	#2;
	//third operation -> id = 011
	apb_write(1,6'b111100);
	apb_write(0,6'b011101);  //(op bit = 10 -> mul)	  	 result:011__01_0000
	
	#2;
	//fourth operation -> id = 001
	apb_write(2,6'b101111);
	apb_write(0,6'b001101);  //(op bit = 10 -> mul)      result:001__01_1100

	
	
end
endtask


task apb_write;
input [(ADDRESS_SIZE -1):0] reg_addr_value;
input [(DATA_SIZE-1):0] reg_value;

begin
	//SETUP_PHASE
		@(posedge clk)begin
		#1;
		sel   = 1'b1;
		write = 1'b1;
		addr = reg_addr_value;
		wdata = reg_value;	
		end
		
		//ACCESS_PHASE
		@(posedge clk)begin
		en = 1'b1;	
		end
		
		@(posedge clk)begin
        sel   = 1'b0;
        en    = 1'b0;
        write = 1'b0;
        end

end
endtask


task Read;
begin
	//SETUP_PHASE
		@(posedge clk)begin
		#1;
		sel   = 1'b1;
		write = 1'b0;
		addr = 3;
		end
		
		//ACCESS_PHASE
		@(posedge clk)begin
		en = 1'b1;	
		end
		
		@(posedge clk)begin
		en = 1'b1;	
		end
		
		@(posedge clk) begin
        sel   = 1'b0;
        en    = 1'b0;
        write = 1'b0;
        end
end
endtask



endmodule