module GlitchFilter # 
(
	parameter NUMBER_OF_SIGNALS = 1,
	parameter RST_VALUE = 0
)
(
	input iClk,	//clock input
	input iARst_n,	//Asynchronous reset
	input iSRst_n,	//Synchronous reset
	input iEna,		//enable signal(active high)
	input [NUMBER_OF_SIGNALS - 1 : 0] iSignal,		// input signal
	output [NUMBER_OF_SIGNALS - 1 : 0] oFilterSignals	//Glitchless signal
);

reg [NUMBER_OF_SIGNALS - 1 : 0] rFilter;
reg [NUMBER_OF_SIGNALS - 1 : 0] rFilteredSignals;

integer i;

always @ ()
begin
	if(!iARst_n) begin
		rFilter <= RST_VALUE;
		rFilteredSignals <= RST_VALUE;
	end // end if
	else begin
		if(!iSRst_n) begin
			rFilteredSignals <= RST_VALUE;
			rFilter <= RST_VALUE;
		end // end if
		else if(iEna) begin
			rFilter <= iSignal;
			for(i = 0; i <= NUMBER_OF_SIGNALS - 1; i = i+1)
			begin
				if(iSignal[i] == rFilter[i]) rFilteredSignals[i] <= rFilter[i];
			end // end for
		end // end else if
		else 
			rFilteredSignals <= rFilteredSignals;
	end // end else
end // end always

assign oFilterSignals = rFilteredSignals;

endmodule
