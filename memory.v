module memory(
clk,
rst_n,
cw_en,
cr_en,
wdata,
w_ptr,
r_ptr,
rdata);

parameter MEMORY_WIDTH = 4;
parameter MEMORY_DEPTH = 4;

parameter FIFO_ADDRESS_SIZE = 2;

parameter MEM_IP = 0;


input clk;
input rst_n;
input cw_en;
input cr_en;
input [(MEMORY_WIDTH-1):0] wdata;
input [(FIFO_ADDRESS_SIZE):0] w_ptr;
input [(FIFO_ADDRESS_SIZE):0] r_ptr;


output [(MEMORY_WIDTH-1):0] rdata;

wire [(FIFO_ADDRESS_SIZE-1):0] w_addr; 
assign w_addr = w_ptr[(FIFO_ADDRESS_SIZE-1):0];

wire [(FIFO_ADDRESS_SIZE-1):0] r_addr; 
assign r_addr = r_ptr[(FIFO_ADDRESS_SIZE-1):0];


generate
	if(MEM_IP ==1) begin
		blk_mem_gen_0 //IP memory
     memory_i(.clka(clk),
             .ena(1'b1),
             .wea(cw_en),
             .addra(w_ptr),
             .dina(wdata),
             .clkb(clk),
             .enb(cr_en),
             .addrb(r_ptr),
             .doutb(rdata));
	end
	else if(MEM_IP == 0) begin 
		
		//memory array
		reg [(MEMORY_WIDTH -1) :0] memory [(MEMORY_DEPTH -1) :0];
		
		//Write
		always@(posedge clk) begin
			if(cw_en) begin
				memory[w_addr] <= wdata;		
			end
		end
		
		//Read 

		d_ff_async_en #(.SIZE(MEMORY_WIDTH))
			read_out(.clk(clk),
				.rst(!rst_n),
				.en(cr_en),
				.d(memory[r_addr]),
				.q(rdata));
	end
endgenerate



            
endmodule