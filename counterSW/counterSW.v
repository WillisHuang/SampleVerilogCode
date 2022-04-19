module counterSW #
(
	parameter multiplier = 2,	//input clock frequency (2MHz), for 1msec (unit time is usec)
	parameter UnitTime = 1000	
)
(
	input iClk,
	input iRst_n,
	input enable,
	output reg done 	//done signal given by when max count is done.
);

localparam target = UnitTime * multiplier;
localparam LOW = 1'b0;
localparam HIGH = 1'b1;

reg [19:0] cnt;

always@(posedge iClk, negedge iRst_n)
begin
	if(!iRst_n) begin
		cnt <= 12'h0;
		done <= LOW;
	end
	else begin
		if(enable) begin
			if(cnt<target) begin
				cnt <= cnt +12'h1;
				done <= LOW;
			end //end if
			else begin
				cnt <= 12'h0;
				done <= HIGH;
			end // end else			
		end //end if
		else begin
			cnt <= 12'h0;
			done <= LOW;
		end // end else
	end //end else
end

endmodule