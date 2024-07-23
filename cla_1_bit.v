module cla_1_bit(
a1,
a2,
cin,
s,
c_out);


input  a1; 
input  a2;
input cin;

output  s;
output c_out;

wire  g; //generate function
wire  p; //propagate function



 assign g = (a1 & a2);
 assign p = (a1 ^ a2);
        
 assign c_out = (g | (p & cin));
 assign s = (p ^ cin);



endmodule
