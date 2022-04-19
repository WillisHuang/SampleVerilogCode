module SignalValidationDelay # 
(
	parameter VALUE	= 1'b1,
	parameter TOTAL_BITS = 3'd4,
	parameter MAX_COUNT = 4'd10,
	parameter POL = 1'b1
)
(
	input iClk,
	input iRst,
	input iCE,	//Clock enable
	input [(TOTAL_BITS - 1) : 0] ivMaxCnt,
	input iStart,
	output oDone
);

reg rDone_d;
reg rDone_g;
reg [(TOTAL_BITS - 1) : 0] rvCounter_d;
reg [(TOTAL_BITS - 1) : 0] rvCounter_g;

wire wRst = iRst || (iStart ^ VALUE);

assign oDone = rDone_g;

always@(posedge iClk or posedge wRst) 		//note: here is posedge reset signal
begin
	if(wRst) begin
		rDone_g <= {1'b1{~POL}};
		rvCounter_g <= {TOTAL_BITS{1'b0}};
	end// end if
	else begin
		rDone_g <= rDone_d;
		if(iCE)	rvCounter_g <= rvCounter_d;
		else	rvCounter_g <= rvCounter_g;
	end // end else
end // end always@


always@(*)
begin
	rDone_d = {1'b1{~POL}};
	rvCounter_d = rvCounter_g;
	if(rvCounter_g < ivMaxCnt) begin
		rvCounter_d = rvCounter_g + 1'b1;
	end // end if
	else begin
		rDone_d = {1'b1{POL}};
	end // end else
end

endmodule