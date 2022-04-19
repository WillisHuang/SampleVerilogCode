//uart rx
`timescale 1ns/1ps

module my_uart_rx(
	clk, rst_n,
	rs232_rx, rx_data,rx_int,
	clk_bps,bps_start
);

input clk;		//50MHz
input rst_n;	//reset clk, active low
input rs232_rx;	//RS232接收數據信號
input clk_bps;	//clk_bps的高電位為接收或是發送數據位的中間採樣點
output bps_start;	//接收到數據後，波特率時鐘啟動信號置位
output [7:0] rx_data;	//接收數據暫存器，保存到下一個數據到來
output rx_int;		//接收數據中斷信號，接收到數據期間始終為高電位

//----------------------------------------------------------------
reg rs232_rx0,rs232_rx1,rs232_rx2,rs232_rx3; //接收數據暫存器
wire neg_rs232_rx;	//表示數據線接收到下降沿

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		rs232_rx0 <= 1'b0;
		rs232_rx1 <= 1'b0;
		rs232_rx2 <= 1'b0;
		rs232_rx3 <= 1'b0;
	end
	else begin
		rs232_rx0 <= rs232_rx;
		rs232_rx1 <= rs232_rx0;
		rs232_rx2 <= rs232_rx1;
		rs232_rx3 <= rs232_rx2;
	end
end

//下面的下降沿檢測可以濾掉<20ns ~ 40ns的毛刺(包括高脈衝和低脈衝
//這裡就是用資源換穩定(前提是我們對時間的要求不苛刻)
//當然我們的有效低脈衝信號是遠大於40ns的

assign neg_rs232_rx = rs232_rx3 & rs232_rx2 & ~rs232_rx1 & ~rs232_rx0;

//-------------------------------------------------------------------
reg bps_start_r;
reg [3:0] num;		//移位次數
reg rx_int;		//接收數據中斷信號，接收到數據期間始終為高電位

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		bps_start_r <= 1'bz;
		rx_int <= 1'b0;
	end
	else if(neg_rs232_rx)begin		//接收到串口接收線rs232_rx的
		bps_start_r <= 1'b1;		//啟動串口準備數據接收
		rx_int <= 1'b1;				//接收數據中斷信號使能
	end
	else if(num == 4'd12)begin		//接收完有用數據信息
		bps_start_r <= 1'b0;		//數據接收完畢後，釋放波特率啟動
		rx_int <= 1'b0;				//接收數據中斷信號關閉
	end
end

assign bps_start = bps_start_r;
//-------------------------------------------------------------------
reg [7:0] rx_data_r;	//串口接收數據暫存器，保存直到下一個數據
//-------------------------------------------------------------------

reg	[7:0] rx_temp_data;	//當前接收數據暫存器

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		rx_temp_data <= 8'd0;
		num <= 4'd0;
		rx_data_r <= 8'd0;
	end
	else if(rx_int) begin	//接收數據處理
		if(clk_bps) begin	//讀取並保存數據，接收數據為一個起始位
			num <= num + 1'b1;
			case(num)
				4'd1: rx_temp_data[0] <= rs232_rx;
				4'd2: rx_temp_data[1] <= rs232_rx;
				4'd3: rx_temp_data[2] <= rs232_rx;
				4'd4: rx_temp_data[3] <= rs232_rx;
				4'd5: rx_temp_data[4] <= rs232_rx;
				4'd6: rx_temp_data[5] <= rs232_rx;
				4'd7: rx_temp_data[6] <= rs232_rx;
				4'd8: rx_temp_data[7] <= rs232_rx;
				default: ;
			endcase
		end
		else if(num == 4'd12) begin
			num <= 4'd0;
			rx_data_r <= rx_temp_data;
		end
	end
end

assign rx_data = rx_data_r;

endmodule
