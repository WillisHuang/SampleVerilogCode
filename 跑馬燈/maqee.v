/*--------------------------------------------------------
跑馬燈說明:	
當3個獨立按鍵的某一個被按下後,相應的LED動作
key1 : 控制跑馬燈移動或是不動
key2 : 控制跑馬燈向左移動
key3 : 控制跑馬燈向右移動

//設計步驟
1. LED 閃爍
2. 簡單跑馬燈 
3. 可控跑馬燈
4. 按鍵消抖

--------------------------------------------------------*/
module maqee(
	clk,rst_n,
	led,
	sw1_n, sw2_n, sw3_n
);

input clk;			//主時鐘信號,50MHz ~ 20ns
input rst_n;		//reset signal, active low
output[3:0] led;	//led 由按鍵控制
input sw1_n, sw2_n, sw3_n;		//3個獨立按鍵, low 表示按下

/*
// parameter 是固定值，要能更動，須改為reg
parameter led_dir = 1'b0;	//1'b1 -- left,  1'b0 -- right
parameter led_on = 1'b1;	//1'b1 -- on,  1'b0 -- off
*/
reg led_dir = 1'b0;		//1'b1 -- left,  1'b0 -- right
reg led_on = 1'b1;		//1'b1 -- on,  1'b0 -- off


//----------------------------------------------------
reg [23:0] cnt24;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) cnt <= 24'd0;
	else	cnt24 <= cnt24 + 1'b1;
end

//----------------------------------------------------

reg [3:0] led_r;

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) led_r <= 4'b0001; //LED high active
	else if(cnt24 == 24'hffffff && led_on) begin
		if(led_dir) led_r <= {led_r[0], led_r[3:1]}; 	//左移 
		else led_r <= {led_r[2:0], led_r[3]};			//右移
	end
end

assign led = led_r;



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


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		led_on = 1'b0;
		led_dir = 1'b0;
	end
	else begin		//某個按鍵值變化時，LED將做亮滅翻轉
		if(led_ctrl[0]) led_on <= ~led_on;
		if(led_ctrl[1]) led_dir <= 1'b0;
		if(led_ctrl[2]) led_dir <= 1'b1;
	end
	
end



endmodule






