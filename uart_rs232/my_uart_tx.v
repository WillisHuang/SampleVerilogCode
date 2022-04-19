//uart tx
`timescale 1ns/1ps
module my_uart_tx(
	clk,rst_n,
	rx_data, rx_int, rs232_tx,
	clk_bps, bps_start
);

input clk;		//50MHz
input rst_n;	//reset signal, active low
input clk_bps;	//clk_bps_r高電位為接收數據位的中間採樣點
input [7:0] rx_data;	//接收數據暫存器
input rx_int;	//接收數據中斷信號，接收到數據期間始終為高電位
output rs232_tx;	//RS232發送數據信號
output bps_start;	//接收或發送數據，波特率時鐘啟動信號置位


//---------------------------------------------------------------
reg rx_int0, rx_int1, rx_int2;	//rx_int 信號暫存器，捕捉下降沿濾波
wire neg_rx_int;				//rx_int 下降沿標誌位

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		rx_int0 <= 1'b0;
		rx_int1 <= 1'b0;
		rx_int2 <= 1'b0;
	end
	else begin
		rx_int0 <= rx_int;
		rx_int1 <= rx_int0;
		rx_int2 <= rx_int1;
	end
end	

assign neg_rx_int = ~rx_int1 & rx_int2; //	捕捉到下降沿後

//-------------------------------------------------------------
reg [7:0] tx_data;		//待發送數據暫存器
//-------------------------------------------------------------
reg bps_start_r;
reg tx_en;				//發送數據使能信號，高有效
reg [3:0] num;

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		bps_start_r <= 1'bz;
		tx_en <= 1'b0;
		tx_data <= 8'd0;
	end
	else if(neg_rx_int) begin	//接收數據完畢，準備處理接收到的數據
		bps_start_r <= 1'b1;
		tx_data <= rx_data;		//把收到的書據存入發送數據暫存器
		tx_en <= 1'b1;			//進入發送數據狀態
	end
	else if(num == 4'd11)begin	//數據發送完成，復位
		bps_start_r <= 1'b0;
		tx_en <= 1'b0;
	end
end

assign bps_start = bps_start_r;

//-------------------------------------------------------------
reg rs232_tx_r;

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		num <= 4'd0;
		rs232_tx_r <= 1'b1;
	end
	else if(tx_en) begin
		if(clk_bps) begin
			num <= num + 1'b1;
			case(num)
				4'd0: rs232_tx_r <= 1'b0;		//發送起始位
				4'd1: rs232_tx_r <= tx_data[0];
				4'd2: rs232_tx_r <= tx_data[1];
				4'd3: rs232_tx_r <= tx_data[2];
				4'd4: rs232_tx_r <= tx_data[3];
				4'd5: rs232_tx_r <= tx_data[4];
				4'd6: rs232_tx_r <= tx_data[5];
				4'd7: rs232_tx_r <= tx_data[6];
				4'd8: rs232_tx_r <= tx_data[7];
				4'd9: rs232_tx_r <= 1'b1;		//發送結束位
				default: rs232_tx_r <= 1'b1;
			endcase
		end
		else if(num == 4'd11) num <= 4'd0; 	//復位
	end
end

assign rs232_tx = rs232_tx_r;

endmodule
