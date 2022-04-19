/*
	output pulse at DIV * clk_period secs
	ex:
	for a 2MHz clock frequency => 250MHz * 500ns = 125msec
*/

module ClkDiv #
(
	parameter DIV = 24999 // base on 2MHz clk, this value would deliver a 125msec periodic signal
)
(
	input iClk,	//2MHz
	input iRst_n,	// active low
	output reg div_clk
);

localparam CNT_SIZE = clog2(DIV);
//---------------------------------------------------------------------------
function integer clog2;
	input integer value;
	begin
		value = value -1;
		for(clog2 = 0; value > 0; clog2 = clog2 + 1)
			value = value >> 1;
	end
endfunction

reg [CNT_SIZE - 1 : 0] rCnt;	//count for the divider
always @ (posedge iClk, negedge iRst_n)
begin
	if(!iRst_n) begin
		div_clk <= 1'b0;
		rCnt <= 0;
	end // end if
	else begin
		if(rCnt == DIV) begin
			div_clk <= 1'b1;
			rCnt <= 0;
		end // end if
		else begin
			div_clk <= 1'b0;
			rCnt <= rCnt + 1'b1;
		end // end else 
	end // end else
end // end always

endmodule