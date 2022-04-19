module genCntr	#
(
	parameter MAX_COUNT = 1000
)
(
	output wire oCntDone,
	output reg [logb2(MAX_COUNT) : 0] oCntr,
	input wire iClk,
	input wire iCntEn,
	input wire iRst_n,
	input wire iCntRst_n
);

//-------------------------------------------------
// logarithm for base 2 
function integer logb2(input integer size);
	integer size_buf;
	begin
		size_buf = size;
		for(logb2 = -1; size_buf > 0; logb2 = logb2 + 1)
			size_buf = size_buf >> 1;
	end
	
endfunction


//-------------------------------------------------
// main sequencial logic
always@(posedge iClk or negedge iRst_n)
begin
	if(!iRst_n)	oCntr <= 0;
	else if (!iCntRst_n) oCntr <= 0;
	else begin
		if(oCntr == MAX_COUNT) oCntr <= oCntr;
		else if(iCntEn) oCntr <= oCntr + 1'b1;
		else oCntr <= oCntr;
	end // end else	
end // end always

assign oCntDone = (oCntr == MAX_COUNT)?1'b1:1'b0;

endmodule