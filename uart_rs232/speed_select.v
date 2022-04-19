//speed_select

module speed_select(
	clk,rst_n,
	bps_start,clk_bps
);

input clk;		//50MHz
input rst_n;	//reset signal , active low
input bps_start;	//接收到數據後，波特率時鐘啟動信號置位
output clk_bps;		//clk_bps的高電位為接收或發送數據位的中間採樣點

/*
parameter		bps9600		=	5207,	//baud rate 9600bps
				bps19200	=	2603,	//baud rate 19200bps
				bps38400	=	1301,	//baud rate 38400bps
				bps57600	=	867,	//baud rate 57600bps
				bps115200	=	433;	//baud rate 115200bps
				
//計數到一半進行採樣
parameter		bps9600_2	=	2603,	//baud rate 9600bps
				bps19200_2	=	1301,	//baud rate 19200bps
				bps38400_2	=	650,	//baud rate 38400bps
				bps57600_2	=	433,	//baud rate 57600bps
				bps115200_2	=	216;	//baud rate 115200bps
*/

//以下baud rate 分頻計數值可以參照上面的參數進行修改
`define BPS_PARA	5207	//baud rate 9600的分頻計數值
`define BPS_PARA_2	2603	//baud rate 9600的分頻計數值的

reg [12:0] cnt;		//分頻計數
reg clk_bps_r;		//波特率時鐘暫存器

//---------------------------------------------------------------------
reg [2:0] uart_ctrl;	//uart波特率選擇暫存器
//---------------------------------------------------------------------

always@(posedge clk or negedge rst_n)
begin 
	if(!rst_n) cnt <= 13'd0;
	else if ((cnt == `BPS_PARA) || !bps_start ) cnt <= 13'd0;
	else cnt <= cnt + 1'b1;		//波特率時鐘計數啟動
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) clk_bps_r <= 1'b0;
	else if(cnt == `BPS_PARA_2) clk_bps_r <= 1'b1;	//clk_bps_r 高
	else clk_bps_r <= 1'b0;
end

assign clk_bps = clk_bps_r;


endmodule