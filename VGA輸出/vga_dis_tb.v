//vga test bench

`timescale 1ns/1ps

module vga_dis_tb();

reg clk;
reg rst_n;
wire hsync;
wire vga_b;
wire vga_g;
wire vga_r;
wire vsync;


vga_dis i1(
	.clk(clk),
	.rst_n(rst_n),
	.hsync(hsync),
	.vsync(vsync),
	.vga_r(vga_r),
	.vga_g(vga_g),
	.vga_b(vga_b)
);

initial begin
	clk = 0;
	forever #10 clk = ~clk;
end

initial begin
	rst_n = 0;
	#1000
	rst_n = 1;
end


endmodule