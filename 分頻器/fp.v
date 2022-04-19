//分頻器

module fp(
	fm,
	clk,
	rst_n
);

input clk;		//clock signal , 50MHz
input rst_n;	//reset signal , active low
output fm;		//beeper , gate signal low -> active , gate signal high -> not active

reg[5:0] cnt;	//counter , count to 50, the first 0~25 : low , the last 26-50 : high -> form a square wave

always @ (posedge clk or negedge rst_n)
begin	
	if(!rst_n)	cnt <= 6'd0;
	else if	(cnt < 6'd49)	cnt <= cnt + 1'b1;
	else cnt <= 6'd0;
end

//the clock form a square signal, the 0~24 -> low   , the 25-50 -> high
assign fm = (cnt <= 6'd24) ? 1'b0 : 1'b1;


endmodule

