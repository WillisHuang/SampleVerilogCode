//8分頻

module div_8(clkdiv);

output clkdiv;

reg [2:0] cnt;

always@(posedge clk or negedge rst_n)
begin	
	if(!rst_n) cnt <= 3'd0;
	else cnt <= cnt + 1'b1;
end	

assign clkdiv = cnt[2];

endmodule