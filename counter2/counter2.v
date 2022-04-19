module counter2 #
(
	parameter MAX_COUNT = 100 // maximum number of clock cycles to count, iSetCnt should be smaller than this one.
)
(
	input iClk,
	input iRst_n,
	input iCntRst_n,	//synchronous reset
	input iCntEn,
	input iLoad,
	input [logb2(MAX_COUNT) : 0] iSetCnt,
	output oDone,	// it is high when max count has been reached
	output reg [logb2(MAX_COUNT) : 0] oCntr
);

/* --------------------------------------------------------------------------------
Return the floor of the base 2 log of the "size" number, 
we use the return value as the MSB bit in vector size definitions.

//ex
we need 4 bits for the number 13, we need a vector with an index from 3 t0 0.

flogb2(from 8 to 15) = 3,
flogb2(from 7 to 4) = 2
flogb2(from 3 to 2) = 1
--------------------------------------------------------------------------------  */ 

//--------------------------------------------------------------------------------
// logrithm declaration
function automatic integer logb2(input integer size);
	integer size_buf;
	begin
		size_buf = size;
		for(logb2 = -1; size_buf >0; logb2 = logb2 + 1)
			size_buf = size_buf >> 1;
	end
endfunction

// we need latches simply to store bits of information, save the values
// the counter need to reach to assert and output flag.

reg [logb2(MAX_COUNT) : 0] rMaxCnt;
always @ (posedge iClk or negedge iRst_n)
begin
	if(!iRst_n) rMaxCnt <= {{logb2(MAX_COUNT){1'b1}},1'b1}; // all ones.
	else if(iLoad && !iCntEn) rMaxCnt <= iSetCnt;
	else rMaxCnt <= rMaxCnt;
end // end always

always @ (posedge iClk or negedge iRst_n)
begin
	if(!iRst_n) oCntr <= 0;
	else if(!iCntRst_n) oCntr <= 0;
	else begin
		if(oCntr == rMaxCnt) oCntr <= oCntr;
		else if(iCntEn) oCntr <= oCntr + 1'b1;
		else oCntr <= oCntr;
	end //end else
end // end always

assign oDone = (oCntr == rMaxCnt) ? 1'b1 : 1'b0;

endmodule