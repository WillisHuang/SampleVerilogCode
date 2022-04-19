`timescale 1ns/1ps

module fp_tb();

reg eachvec;
reg clk;
reg	rst_n;
wire fm;


fp	i1(
	.fm(fm),
	.clk(clk),
	.rst_n(rst_n)
);

initial begin
	clk = 0;
	forever
		#10 clk = ~clk;	
end

initial begin
	rst_n = 0;
	#1000
	rst_n = 1;
	#5000
	$stop;
end

endmodule