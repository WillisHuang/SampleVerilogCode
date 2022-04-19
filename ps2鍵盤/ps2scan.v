//ps2_scan
`timescale 1ns/1ps

module ps2_scan(
	clk, rst_n, ps2k_clk, ps2k_data,
	ps2_byte, ps2_state
);

input clk;				//50MHz
input rst_n;			//reset signal , active low
input ps2k_clk;			//PS2 接口時鐘信號
input ps2k_data;		//PS2 接口數據信號
output [7:0] ps2_byte;	//1byte鍵值，只做簡單按鍵掃描
output ps2_state;		//鍵盤當前狀態。1 : 按鍵被按下

//----------------------------------------------------------------
reg ps2k_clk_r0, ps2k_clk_r1, ps2k_clk_r2;		//ps2k_clk狀態暫存器

//wire pos_ps2k_clk;		//ps2k_clk上升沿標誌位
wire neg_ps2k_clk;		//ps2k_clk下降沿標誌位

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		ps2k_clk_r0 <= 1'b0;
		ps2k_clk_r1 <= 1'b0;
		ps2k_clk_r2 <= 1'b0;
	end
	else begin			//鎖存狀態，進行濾波
		ps2k_clk_r0 <= ps2k_clk;
		ps2k_clk_r1 <= ps2k_clk_r0;
		ps2k_clk_r2 <= ps2k_clk_r1;
	end
end

assign neg_ps2k_clk = ~ps2k_clk_r1 & ps2k_clk_r2;		//下降沿

//----------------------------------------------------------------
reg [7:0] ps2_byte_r;		//PC接收來自PS2的一個自結數據存儲器
reg [7:0] temp_data;		//當前接收數據暫存器
reg [3:0] num;				//計數暫存器

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		num <= 4'd0;
		temp_data <= 8'd0;
	end
	else if(neg_ps2k_clk) begin		//檢測到ps2k_clk的下降沿
		case(num)
			4'd0:	num <= num + 1'b1;
			4'd1:	begin
						num <= num + 1'b1;
						temp_data[0] <= ps2k_data;	 	//bit0
					end
			4'd2:	begin
						num <= num + 1'b1;
						temp_data[1] <= ps2k_data;	 	//bit1
					end
			4'd3:	begin
						num <= num + 1'b1;
						temp_data[2] <= ps2k_data;	 	//bit2
					end
			4'd4:	begin
						num <= num + 1'b1;
						temp_data[3] <= ps2k_data;	 	//bit3
					end
			4'd5:	begin
						num <= num + 1'b1;
						temp_data[4] <= ps2k_data;	 	//bit4
					end
			4'd6:	begin
						num <= num + 1'b1;
						temp_data[5] <= ps2k_data;	 	//bit5
					end
			4'd7:	begin
						num <= num + 1'b1;
						temp_data[6] <= ps2k_data;	 	//bit6
					end
			4'd8:	begin
						num <= num + 1'b1;
						temp_data[7] <= ps2k_data;	 	//bit7
					end
			4'd9:	begin
						num <= num + 1'b1;				//奇偶校驗位，不處理
					end
			4'd10:	begin
						num <= 4'd0;					//num清零
					end
			default: ;
		endcase
	end
end

reg key_f0;	//釋放鍵標示位，1:表示接收到數據8'hf0,再接收到下一個數據後清零
reg ps2_state_r;	//鍵盤當前狀態，ps2_state_r = 1表示有鍵被按下

always@(posedge clk or negedge rst_n)	//接收數據的相應處理
begin
	if(!rst_n) begin
		key_f0 <= 1'b0;
		ps2_state_r <= 1'b0;
	end
	else if(num == 4'd10) begin		//剛送完一個字節數據
		if(temp_data == 8'hf0) key_f0 <= 1'b1;
		else begin
			if(!key_f0) begin		//說明有鍵按下
				ps2_state_r <= 1'b1;
				ps2_byte_r <= temp_data;	//鎖存當前鍵值
			end
			else begin
				ps2_state_r <= 1'b0;
				key_f0 <= 1'b0;
			end
		end
	end
end

reg [7:0] ps2_asci;		//接收數據的相應ASCII碼

always@(ps2_byte_r)
begin
	case(ps2_byte_r)	//鍵值轉換為ASCII碼，只處理字母
		8'h15: ps2_asci <= 8'h51;	//Q
		8'h1d: ps2_asci <= 8'h57;	//W
		8'h24: ps2_asci <= 8'h45;	//E
		8'h2d: ps2_asci <= 8'h52;	//R
		8'h2c: ps2_asci <= 8'h54;	//T
		8'h35: ps2_asci <= 8'h59;	//Y
		8'h3c: ps2_asci <= 8'h55;	//U
		8'h43: ps2_asci <= 8'h49;	//I
		8'h44: ps2_asci <= 8'h4f;	//O
		8'h4d: ps2_asci <= 8'h50;	//P
		8'h1c: ps2_asci <= 8'h41;	//A
		8'h1b: ps2_asci <= 8'h53;	//S
		8'h23: ps2_asci <= 8'h44;	//D
		8'h2b: ps2_asci <= 8'h46;	//F
		8'h34: ps2_asci <= 8'h47;	//G
		8'h33: ps2_asci <= 8'h48;	//H
		8'h3b: ps2_asci <= 8'h4a;	//J
		8'h42: ps2_asci <= 8'h4b;	//K
		8'h4b: ps2_asci <= 8'h4c;	//L
		8'h1a: ps2_asci <= 8'h5a;	//Z
		8'h22: ps2_asci <= 8'h58;	//X
		8'h21: ps2_asci <= 8'h43;	//C
		8'h2a: ps2_asci <= 8'h56;	//V
		8'h32: ps2_asci <= 8'h42;	//B
		8'h31: ps2_asci <= 8'h4e;	//N
		8'h3a: ps2_asci <= 8'h4d;	//M
		default: ;		
	endcase
end

assign ps2_byte = ps2_asci;
assign ps2_state = ps2_state_r;

endmodule
