//uart top

module my_uart_top(
	clk,rst_n,
	rs232_rx,rs232_tx
);

input clk;		//50MHz
input rst_n;	//reset signal , active low

input rs232_rx;	//RS232 接收數據信號
output rs232_tx;	//RS232 發送數據信號

wire bps_start1,bps_start2;	//接收到數據後，波特率時鐘啟動信號置位
wire clk_bps1,clk_bps2;		//clk_bps_r高電位為接收數據位的中間
wire [7:0]	rx_data;		//接收數據暫存器,保存到下一個數據到來
wire rx_int;			//接收數據中斷信號,接收到數據期間始終為高電位

//-----------------------------------------------------------------------
speed_select	speed_rx(						//波特率選擇模塊
						.clk(clk),
						.rst_n(rst_n),
						.bps_start(bps_start1),
						.clk_bps(clk_bps1)
						);

my_uart_rx		my_uart_rx(						//接收數據模組
							.clk(clk),
							.rst_n(rst_n),
							.rs232_rx(rs232_rx),
							.rx_data(rx_data),
							.rx_int(rx_int),
							.clk_bps(clk_bps1),
							.bps_start(bps_start1)
						   );
//////////////////////////////////////////////////////////////////////
speed_select	speed_tx(						//波特率選擇模塊
						.clk(clk),
						.rst_n(rst_n),
						.bps_start(bps_start2),
						.clk_bps(clk_bps2)
						);
						
my_uart_tx		my_uart_tx(						//發送數據模組
							.clk(clk),
							.rst_n(rst_n),
							.rx_data(rx_data),
							.rx_int(rx_int),
							.rs232_tx(rs232_tx),
							.clk_bps(clk_bps2),
							.bps_start(bps_start2)
						   );
						   
						   
endmodule