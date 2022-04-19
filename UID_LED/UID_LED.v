`timescale 1ns/1ps

module UID_LED(
	input RESET_n,
	input CLK,
	input i_Freq_0P5HZ,
	input i_Freq_01HZ,
	input i_Freq_02HZ,
	input i_Freq_04HZ,
	input i_Freq_08HZ,
	input [1:0] i_BMC_LED_Ctrl,
	input i_UID_BTN_IN_N,	//UID_Button
	output wire o_UID_BTN_OUT,	//UID_Button to BMC
	output wire o_CPLD_UID_LED,	//UID_LED
	output wire o_UID_PRESS_6S,
	output wire o_UID_PRESS_12S
);

GlitchFilter #
(
	.NUMBER_OF_SIGNALS(1),
	.RST_VALUE(1'b1)
);
UID_BTN_GlitchFilter(
	.iClk(CLK),
	.iARst_n(RESET_n),
	.iSRst_n(1'b1),
	.iEna(1'b1),
	.iSignal({i_UID_BTN_IN_N}),
	.oFilteredSignals({o_UID_BTN_OUT})
);

// 1HZ rising pulse
reg Freq_01HZ_1d;
always@(posedge CLK or negedge RESET_n)
begin
	if(!RESET_n)	Freq_01HZ_1d <= #1 1'b0;
	else			Freq_01HZ_1d <= #1 i_Freq_01HZ;
end

wire Freq_01HZ_ris	= i_Freq_01HZ & (~Freq_01HZ_1d);

// UID Button Press Low Counter
reg [3:0] BTN_LOW_cnt;
always@(posedge CLK or negedge RESET_n)
begin
	if(~RESET_n)	BTN_LOW_cnt <= #1 4'd0;
	else if (o_UID_BTN_OUT == 1'b1)	BTN_LOW_cnt <= #1 4'd0;
	else if	(BTN_LOW_cnt == 4'hF)	BTN_LOW_cnt <= #1 BTN_LOW_cnt;
	else if ((o_UID_BTN_OUT == 1'b0) & Freq_01HZ_ris)	BTN_LOW_cnt <= #1 BTN_LOW_cnt + 4'd1;
	else BTN_LOW_cnt <= #1 BTN_LOW_cnt;
end

reg uid_sw_reset_bmc;
assign o_UID_PRESS_6S = uid_sw_reset_bmc;

always@(posedge CLK or negedge RESET_n)
begin
	if(~RESET_n) uid_sw_reset_bmc <= #1 1'b0;
	else if(BTN_LOW_cnt >= 4'd6) uid_sw_reset_bmc <= #1 1'b1;
	else uid_sw_reset_bmc <= #1 1'b0;
end

reg uid_sw_reset_default;
assign o_UID_PRESS_12S = uid_sw_reset_default;

always@(posedge CLK or negedge RESET_n)
begin
	if(~RESET_n) uid_sw_reset_default <= #1 1'b0;
	else if(BTN_LOW_cnt >= 4'd12) uid_sw_reset_default <= #1 1'b1;
	else uid_sw_reset_default <= #1 1'b0;
end // end always

// UID LED
assing o_CPLD_UID_LED = uid_sw_reset_default ? i_Freq_08HZ :
						(uid_sw_reset_bmc 	 ? i_Freq_04HZ :
						((i_BMC_LED_Ctrl[1:0] == 2'b11) ? 1'b1 :
						((i_BMC_LED_Ctrl[1:0] == 2'b10) ? i_Freq_08HZ :
						((i_BMC_LED_Ctrl[1:0] == 2'b01) ? i_Freq_0P5HZ :1'b0))));

endmodule