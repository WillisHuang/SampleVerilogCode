/*-----------------------------------------------------
7段顯示器說明:

數字/字符	|	0	1	2	3	4	5	6	7
編碼(16進制)|	3f  06	5b	4f	66	6d	7d	07
數字/字符	|	8	9	A	B	C	D	E	F
編碼(16進制)|	7f	6f	77	7c	39	5e	79	71

-----------------------------------------------------*/


module led_seg7(
	clk,rst_n,
	sm_cs1_n,sm_cs2_n,sm_db
);

input	clk;	//50MHz
input	rst_n;	//復位信號,低有效
output	sm_cs1_n,sm_cs2_n;	//選擇7段顯示器
output	[6:0]	sm_db;	//7段顯示器顯示的LED(不含小數點)

reg	[24:0]	cnt;	//計數器,最大可以計數到2^25 * 20ns = 640ms

always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) cnt <= 25'd0;
	else cnt <= cnt + 1'b1;		//循環計數
end


reg [3:0] num;		//顯示數值

always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n) num <= 4'd0;
	else if(cnt == 25'h1ffffff) num <= num + 1'b1;		//每640ms 增加1
end
//----------------------------------------------------------------------
/* 	共陰極	:  不帶小數點

				0	1	2	3	4	5	6	7
		db		3f  06	5b	4f	66	6d	7d	07
				8	9	A	B	C	D	E	F	滅
		db		7f	6f	77	7c	39	5e	79	71	00
*/

parameter	seg0	= 7'h3f,
			seg1	= 7'h06,
			seg2	= 7'h5b,
			seg3	= 7'h4f,
			seg4	= 7'h66,
			seg5	= 7'h6d,
			seg6	= 7'h7d,
			seg7	= 7'h07,
			seg8	= 7'h7f,
			seg9	= 7'h6f,
			sega	= 7'h77,
			segb	= 7'h7c,
			segc	= 7'h39,
			segd	= 7'h5e;
			sege	= 7'h79;
			segf	= 7'h71;

reg	[6:0] sm_dbr;	//7段顯示器(不含小數點)
always @ (num)
begin
	case(num)	//num值顯示在7段顯示器上
		4'h0:sm_dbr <= seg0;
		4'h1:sm_dbr <= seg1;
		4'h2:sm_dbr <= seg2;
		4'h3:sm_dbr <= seg3;
		4'h4:sm_dbr <= seg4;
		4'h5:sm_dbr <= seg5;
		4'h6:sm_dbr <= seg6;
		4'h7:sm_dbr <= seg7;
		4'h8:sm_dbr <= seg8;
		4'h9:sm_dbr <= seg9;
		4'ha:sm_dbr <= sega;
		4'hb:sm_dbr <= segb;
		4'hc:sm_dbr <= segc;
		4'hd:sm_dbr <= segd;
		4'he:sm_dbr <= sege;
		4'hf:sm_dbr <= segf;
		default:	;
	endcase
end

assign sm_db = sm_dbr;
assign sm_cs1_n = 1'b0;	//1號7段顯示器常開
assign sm_cs2_n = 1'b0; //2號7段顯示器常開


endmodule