module HeartBeat # 
(
	parameter DIV = 249999	// based on a 2MHz clock, this value would deliver a 250ms periodic signal
)
(
	input iClk,	//2MHz
	input iRst_n,
	output reg oHeartBeat
	/*----------------------------------------------
	output at DIV * clk_period secs (based on 2MHz)
	clock frequency => 250M * 0.5nsec = 125msec
	----------------------------------------------*/
);

localparam CNT_SIZE = clog2(DIV);
//-------------------------------------------------
function integer clog2;
	input integer value;
	begin
		value = value - 1;
		for(clog2 = 0; value > 0; clog2 = clog2 + 1)
			value = value >> 1;
	end
endfunction


//-------------------------------------------------
reg [CNT_SIZE - 1 : 0] rCnt;	//count for the divider
always@(posedge iClk, negedge iRst_n)
begin
	if(!iRst_n) begin
		oHeartBeat <= 1'b0;
		rCnt <= 0;
	end // end if
	else begin
		if(rCnt == DIV) begin
			oHeartBeat <= ~oHeartBeat;
			rCnt <= 0;
		end // end if
		else begin
			oHeartBeat <= oHeartBeat;
			rCnt <= rCnt + 1'b1;
		end //end else
	end // end else
	
end // end always@


endmodule