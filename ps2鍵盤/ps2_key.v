//ps2 top module

/*
ex:
按下SHIFT、按下G、釋放G、釋放SHIFT。
SHIFT的通碼	:8'h12,
G的通碼		:8'h34,
G的斷碼		:8'hF0	8'h34
SHIFT的斷碼	:8'hF0	8'h12

因此，發送到計算機的數據是 :8'h12	8'h34	8'hF0	8'h34	8'hF0	8'h12

*/

module ps2_key(
	clk, rst_n,ps2k_clk,ps2k_data,
	rs232_tx
);
 
input clk;			//50MHz
input rst_n;		//reset signal
input ps2k_clk;		//PS2接口時鐘信號
input ps2k_data;	//PS2接口數據信號
output rs232_tx;	//RS232發送數據信號

wire [7:0]	ps2_byte;	//	1byte鍵值
wire ps2_state;			// 按鍵狀態標誌位

wire bps_start;			//接收到數據後，波特率時鐘啟動信號置位
wire clk_bps;			//clk_bps的高電位為接收或是發送數據位的中間採樣點


ps2scan			ps2scan(
						.clk(clk),
						.rst_n(rst_n),
						.ps2k_clk(ps2k_clk),
						.ps2k_data(ps2k_data),
						.ps2_byte(ps2_byte),
						.ps2_state(ps2_state)
						);

speed_select	speed_select(
							 .clk(clk),
							 .rst_n(rst_n),
							 .bps_start(bps_start),
							 .clk_bps(clk_bps)
							);
							

my_uart_tx		my_uart_tx(
							.clk(clk),
							.rst_n(rst_n),
							.clk_bps(clk_bps),
							.rx_data(ps2_byte),
							.rx_int(ps2_state),
							.rs232_tx(rs232_tx),
							.bps_start(bps_start)
						   );

endmodule