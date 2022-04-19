//說明:	當3個獨立按鍵的某一個被按下後,相應的LED被點亮，
//		再次按下後，LED熄滅，按鍵控制LED亮滅。

module sw_debounce(
	clk,
	sw1_n,sw2_n,sw3_n,
	led_d1,led_d2,led_d3
);


input clk;			//主時鐘信號,50MHz ~ 20ns
input rst_n;		//reset signal, active low
input sw1_n, sw2_n, sw3_n;		//3個獨立按鍵, low 表示按下
output led_d1, led_d2, led_d3;	//led 由按鍵控制

/*--------------------------------------------------------
// module 1  脈衝邊緣檢測法 -> 偵測按鍵
--------------------------------------------------------*/

/*
key_rst		1 1 1 0 0 1
~key_rst	0 0 0 1 1 0
key_rst_r	  1 1 1 0 0 1
key_an		  0 0 1 0 0 
*/

//利用兩級暫存器來檢測

reg	[2:0] key_rst;

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) key_rst <= 3'b111;
	else	key_rst <= {sw3_n,sw2_n,sw1_n};
end


reg[2:0] key_rst_r; 	//每個時鐘周期的上升沿將low_sw信號鎖存到low_sw_r中

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) key_rst_r <= 3'b111;
	else key_rst_r <= key_rst;
end

//當暫存器key_rst由1變為0時，key_an的值變為高，維持一個時鐘周期
wire [2:0] key_an = key_rst_r & (~key_rst);

//module 1 end -------------------------------------------

/*--------------------------------------------------------
// module 2	 計數器 -> 穩定KEY  / LED的輸出 
--------------------------------------------------------*/

/*
low_sw		111  111  111  110  110  110
~low_sw		000  000  000  001  001  001
low_sw_r	     111  111  111  110  110  110
led_ctrl		 000  000  001  000  000 
*/

reg [19:0]	cnt; //計數暫存器 => 2^20 ~ 10^6 => 20ns * 10^6 => 20ms

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) cnt <= 20'd0;	//異步復位
	else if(key_an)	cnt <= 20'd0;
	else cnt <= cnt + 1'b1;
end

reg	[2:0] low_sw;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)	low_sw <= 3'b111;
	else if (cnt == 20'hfffff)	//每20ms, 將按鍵值鎖存到寄存器low_sw中
		low_sw <= {sw3_n, sw2_n, sw1_n};
end

//--------------------------------------------------------
reg [2:0] low_sw_r;		//每個時鐘週期的上升沿將low_sw信號鎖存到low_sw_r

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) low_sw_r <= 3'b111;
	else	low_sw_r <= low_sw;
end

//當暫存器low_sw由1變0時，led_ctrl的值變為high，並維持一個時鐘週期
wire [2:0] led_ctrl = low_sw_r[2:0] & (~low_sw[2:0]);

reg d1;
reg d2;
reg d3;

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		d1 <= 1'b0;
		d2 <= 1'b0;
		d3 <= 1'b0;
	end
	else begin		//某個按鍵值變化時，LED將做亮滅翻轉
		if(led_ctrl[0]) d1 <= ~d1;
		if(led_ctrl[1]) d2 <= ~d2;
		if(led_ctrl[2]) d3 <= ~d3;
	end
	
end

// LED 翻轉輸出
assign led_d3 = d1 ? 1'b1 : 1'b0;
assign led_d2 = d2 ? 1'b1 : 1'b0;
assign led_d1 = d3 ? 1'b1 : 1'b0;


endmodule






