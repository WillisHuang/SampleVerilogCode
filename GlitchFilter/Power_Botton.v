module Power_Botton
(
	input CLK,
	input RESET_n,
	// power botton and register
	input i_FP_PWR_BTN_N,
	input i_BMC_PWR_BTN,
	output wire  o_FM_PCH_PWRBTN_N,
	
	// watchdog timer
	input i_PCH_WD_RST,	//watchdog reset pulse
	input i_WD_timeout_rst, 	// 0: watchdog timeout to reset (default)
								// 1: watchdog timeout to NMI
								
	// reset button and register
	input i_FP_RSTBTN_N,
	input i_BMC_RST,
	output wire o_RESET_PLD_N
);

//------------------------------------------------------------------------
// instance GlitchFilter #1

GlitchFilter # 
(
	.NUMBER_OF_SIGNALS(1),
	.RST_VALUE(0)
)
FP_FP_PWR_BTN_N_GlitchFilter
(
	.iClk(CLK),	//clock input
	.iARst_n(RESET_n),	//Asynchronous reset
	.iSRst_n(1'b1),	//Synchronous reset
	.iEna(1'b1),		//enable signal(active high)
	.iSignal({i_FP_PWR_BTN_N}),		// input signal
	.oFilterSignals({o_FM_PCH_PWRBTN_N})	//Glitchless signal
);

wire FP_RSTBTN_N_FF;

//------------------------------------------------------------------------
// instance GlitchFilter #2

GlitchFilter # 
(
	.NUMBER_OF_SIGNALS(1),
)
FP_RSTBTN_N_GlitchFilter
(
	.iClk(CLK),	//clock input
	.iARst_n(RESET_n),	//Asynchronous reset
	.iSRst_n(1'b1),	//Synchronous reset
	.iEna(1'b1),		//enable signal(active high)
	.iSignal({i_FP_RSTBTN_N}),		// input signal
	.oFilterSignals({FP_RSTBTN_N_FF})	//Glitchless signal
);


assing o_RESET_PLD_N = FP_RSTBTN_N_FF & ~(i_PCH_WD_RST & ~i_WD_timeout_rst) & (~i_BMC_RST) ? 1'b1 : 1'b0;

endmodule