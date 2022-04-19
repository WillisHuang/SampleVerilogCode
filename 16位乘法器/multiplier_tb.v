//multiplier test bench
`timescale 1ns/1ps

module multiplier_tb();

reg clk;
reg rst_n;
reg start;
reg [15:0] ain;
reg	[15:0] bin;

wire [31:0]	yout;
wire done;

multiplier uut(
	.clk(clk),
	.rst_n(rst_n),
	.start(start),
	.ain(ain),
	.bin(bin),
	.yout(yout),
	.done(done)
);

initial begin
	clk = 0;
	forever
	#10 clk = ~clk;	 //產生50MHz時鐘
end

initial begin
	rst_n = 1'b0;
	start = 1'b0;
	ain = 16'd0;
	bin = 16'd0;
	#1000;
	rst_n = 1'b1; 	//上電後1us復位信號
	
	#1000;
	ain = 16'd89;
	bin = 16'd33;
	#100;
	start = 1'b1;
	#4500;
	start = 1'b0;
	#1000_000;
	$stop;
end
endmodule