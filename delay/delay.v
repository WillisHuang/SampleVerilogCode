module delay #
(
	parameter COUNT = 1
)
(
	input wire iClk,
	input wire iRst,
	input wire iStart,
	input wire iClrCnt,
	output wire oDone
);

localparam TOTAL_BITS = clog2(COUNT);
reg rDone;
reg [(TOTAL_BITS - 1) : 0] rCount;

always @ (posedge iClk or negedge iRst)
begin
	if(~iRst) begin
		rDone <= 1'b0;
		rCount <= {TOTAL_BITS{1'b0}};
	end // end if
	else begin
		if(~iStart || iClrCnt) begin
			rDone <= 1'b0;
			rCount <= {TOTAL_BITS{1'b0}};
		end //end if
		else if(COUNT - 1 > rCount) begin
			rDone <= 1'b0;
			rCount <= rCount + 1'b1;
		end // end else if
		else begin
			rDone <= 1'b1;
			rCount <= rCount;
		end // end else
	end // end else
end // end always

assign oDone = rDone;


//-------------------------------------------------
// base 2 logarithm, run in precompile stage
function integer clog2;
	input integer value;
	begin
		value = (value > 1) ? value -1 : 1; // prevent the clog == 0
		for(clog2 = 0; value > 0 ; clog2 = clog2 + 1)
			value = value >> 1;
	end
endfunction

endmodule