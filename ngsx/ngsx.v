module ngsx #
(
	parameter IN_BYTE_REGS = 1,
	parameter OUT_BYTE_REGS = 1
)
(
	input iRst_n,
	input iClk,
	input iLoad,	// Load signal - drive from SGPIO master to capture serial data input in parallel register
	input iSData,	// Serial Data input from SGPIO master
	input [(OUT_BYTE_REGS * 8) - 1 : 0] iPData, // parallel data input 
	output oSData,	// serial data output to SGPIO master
	output reg [(IN_BYTE_REGS * 8) - 1 : 0] oPData // parallel data to internal register (slave)
);

reg [(IN_BYTE_REGS * 8) - 1 : 0] rSToPAcc; 	// serial to parallel accumulator.
											// for serial data from SGPIO master. 
											// Goes to internal registr
reg [(OUT_BYTE_REGS * 8) - 1 : 0] rPDataIn;	//Parallel data input register
											// to latch data before serializing.
											// goes to SGPIO master

assign oSData = rPDataIn[(OUT_BYTE_REGS * 8) - 1];	// serial output is the MSB of the shifted register.

always @ (posedge iClk or negedge iRst_n)
begin
	if(!iRst_n) begin
		rSToPAcc <= {IN_BYTE_REGS * 8 {1'b0}};
		oPData <= {IN_BYTE_REGS * 8 {1'b0}};
		rPDataIn <= {OUT_BYTE_REGS * 8 {1'b0}};
	end //end if
	else begin
		rSToPAcc <= {rSToPAcc[(IN_BYTE_REGS * 8) - 2 : 0], iSData};
		if(!iLoad) begin // parallel data is captured to start serialization for data that goes to SGPIO master
			rPDataIn <= iPData;	//parallel data is captured in shift register to be serialized when load == 0.
			oPData <= rSToPAcc;	//parallel output is driven when load == 0
		end // end if
		else begin	// shift register to serialize parallel input
			rPDataIn[OUT_BYTE_REGS * 8 - 1 : 0] <= {rPDataIn[OUT_BYTE_REGS * 8 - 2 : 0], 1'b0};
		end // end else,
	end// end else
end // end always





endmodule