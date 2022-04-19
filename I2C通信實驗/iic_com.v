//iic_com
`timescale 1ns/1ps
module iic_com(
	clk, rst_n,
	sw1,sw2,
	scl,sda,
	dis_data
);

input clk;					//50MHz
input rst_n;				//reset signal, active low
input sw1, sw2;				//按鍵1, 2(1:按下執行寫入操作,2:按下執行讀操作)
output scl;					//24C02時鐘端口
inout sda;					//24C02數據端口
output [7:0] dis_data;		//數碼管顯示的數據

//-----------------------------------------------------------------------
//按鍵檢測
reg sw1_r, sw2_r;		//鍵值鎖存暫存器，每20ms檢測一次鍵值
reg [19:0] cnt_20ms;	//20ms計數暫存器

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) cnt_20ms <= 20'd0;
	else cnt_20ms <= cnt_20ms + 1'b1; //不斷計數
end	

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		sw1_r <= 1'b1;	//鍵值暫存器復位，沒有鍵盤按下時，鍵值皆是1
		sw2_r <= 1'b1;
	end
	else if(cnt_20ms == 20'hfffff) begin
		sw1_r <= sw1;	//按鍵1值鎖存
		sw2_r <= sw2;	//按鍵值鎖存
	end
end

//------------------------------------------------------------------------
//分頻部分

reg [2:0] cnt;
/*
cnt=0 : scl 上升沿
cnt=1 : scl 高電位中間,用於數據採樣
cnt=2 : scl 下降沿
cnt=3 : scl 低電位中間,用於數據變化
*/
reg [8:0] cnt_delay;	//500循環計數,產生iic所需要的時鐘
reg scl_r;				//時鐘脈衝暫存器

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) cnt_delay <= 9'd0;
	else if(cnt_delay ==9'd499) cnt_delay <= 9'd0;	//計數到10us為scl的週期
	else cnt_delay <= cnt_delay +1'b1;	//時鐘計數
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) cnt <= 3'd5;
	else begin
		case(cnt_delay)
			9'd124: cnt <= 3'd1;	//cnt=1 : scl 高電位中間,用於數據採樣
			9'd249: cnt <= 3'd2;	//cnt=2 : scl 下降沿
			9'd374: cnt <= 3'd3;	//cnt=3 : scl 低電位中間,用於數據變化
			9'd499: cnt <= 3'd0;	//cnt=0 : scl 上升沿
			default: cnt <=3'd5;
		endcase
	end
end

`define SCL_POS		(cnt==3'd0)		//cnt=0 : scl 上升沿
`define SCL_HIG		(cnt==3'd1)		//cnt=1 : scl 高電位中間,用於數據採樣
`define SCL_NEG		(cnt==3'd2)		//cnt=2 : scl 下降沿
`define SCL_LOW		(cnt==3'd3)		//cnt=3 : scl 低電位中間,用於數據變化


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) scl_r <= 1'b0;
	else if(cnt==3'd0) scl_r <= 1'b1;	//scl信號上升沿
	else if(cnt==3'd2) scl_r <= 1'b0;	//scl信號下降沿
end

assign scl = scl_r;		//產生iic所需要的時鐘

//--------------------------------------------------------------------
//需要寫入24C02的地址和數據
`define DEVICE_READ		8'b1010_0001	//被尋址器件地址(讀操作)
`define DEVICE_WRITE	8'b1010_0000	//被尋址器件地址(寫操作)
`define WRITE_DATA		8'b1101_0001	//寫入EEPROM的數據
`define BYTE_ADDR		8'b0000_0011	//寫入/讀出 EEPROM的地址暫存器

reg [7:0] db_r;		//在IIC上傳送的數據暫存器
reg [7:0] read_data;	//讀出EEPROM的數據暫存器

//---------------------------------------------------------------------
//讀、寫時序 (狀態機的定義)
parameter	IDLE	= 4'd0;
parameter	START1	= 4'd1;
parameter	ADD1	= 4'd2;
parameter	ACK1	= 4'd3;
parameter	ADD2	= 4'd4;
parameter	ACK2	= 4'd5;
parameter	START2	= 4'd6;
parameter	ADD3	= 4'd7;
parameter	ACK3	= 4'd8;
parameter 	DATA	= 4'd9;
parameter	ACK4	= 4'd10;
parameter	STOP1	= 4'd11;
parameter	STOP2	= 4'd12;

reg [3:0] cstate;	//狀態暫存器
reg sda_r;		//輸出數據暫存器
reg sda_link;	//輸出數據sda信號inout方向控制位
reg [3:0] num;	

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		cstate <= IDLE;
		sda_r <= 1'b1;
		sda_link <= 1'b0;
		num <= 4'd0;
		read_data <= 8'b0000_0000;
	end
	else begin
		case(cstate)
			IDLE:	
			begin
				sda_link <= 1'b1;		//數據線sda為input
				sda_r <= 1'b1;
				if(!sw1_r || !sw2_r) begin	//SW1, SW2鍵有一個被按下
					db_r <= `DEVICE_WRITE;	//送器件地址(寫操作)
					cstate <= START1;
				end
				else cstate <= IDLE;		//沒有任何按鍵被按下
			end
			
			START1:
			begin
				if(`SCL_HIG) begin			//sc1為高電位期間
					sda_link <= 1'b1;		//數據線sda為output
					sda_r <= 1'b0;			//拉低數據線sda,產生起始位信號
					cstate <= ADD1;
					num <= 4'd0;			//num計數清零
				end
				else cstate <= START1;		//等待scl高電位中間位置到來
			end
			
			ADD1:
			begin
				if(`SCL_LOW) begin
					if(num == 4'd8) begin
						num <= 4'd0;		//num計數清零
						sda_r <= 1'b1;		
						sda_link <= 1'b0;	//sda置為高阻態
						cstate <= ACK1;		
					end
					else begin
						cstate <= ADD1;
						num <= num + 1'b1;
						case(num)
							4'd0: sda_r <= db_r[7];
							4'd1: sda_r <= db_r[6];
							4'd2: sda_r <= db_r[5];
							4'd3: sda_r <= db_r[4];
							4'd4: sda_r <= db_r[3];
							4'd5: sda_r <= db_r[2];
							4'd6: sda_r <= db_r[1];
							4'd7: sda_r <= db_r[0];
							default: ;
						endcase
						//sda_r <= db_r[4'd7-num];		//送器件地址
					end
				end
				//else if(`SCL_POS) db_r <= {db_r[6:0],1'b0};	//器件地址左移
				else cstate <= ADD1;
			end
			
			ACK1:
			begin
				if(/*!sda*/`SCL_NEG) begin
					cstate <= ADD2;		//slave響應信號
					db_r <= `BYTE_ADDR;	//	1地址
				end
				else cstate <= ACK1;	//等待slave響應
			end
			
			ADD2:
			begin
				if(`SCL_LOW) begin
					if(num==4'd8) begin
						num <= 4'd0;	//num計數清零
						sda_r <= 1'b1;
						sda_link <= 1'b0;//sda置為高阻態
						cstate <= ACK2;
					end
					else begin
						sda_link <= 1'b1;	//sda置為output
						num	<= num + 1'b1;
						case(num)
							4'd0: sda_r <= db_r[7];
							4'd1: sda_r <= db_r[6];
							4'd2: sda_r <= db_r[5];
							4'd3: sda_r <= db_r[4];
							4'd4: sda_r <= db_r[3];
							4'd5: sda_r <= db_r[2];
							4'd6: sda_r <= db_r[1];
							4'd7: sda_r <= db_r[0];
							default: ;
						endcase
						//sda_r <= db_r[4'd7-num];	//	送EEPROM地址
						cstate <= ADD2;
					end
				end
				//else if(`SCL_POS) db_r <= {db_r[6:0], 1'b0}; //器件地址左移
				else cstate <= ADD2;
			end
			
			ACK2:
			begin
				if(/*!sda*/`SCL_NEG) begin		//slave響應信號
					if(!sw1_r) begin
						cstate <= DATA;			//寫操作
						db_r <= `WRITE_DATA;	//寫入數據
					end
					else if(!sw2_r) begin
						db_r <= `DEVICE_READ;	//送器件地址(讀操作)
						cstate <= START2;		//讀操作
					end
				end
				else cstate <= ACK2;			//等待slave響應
			end
			
			START2:
			begin				//讀操作起始位	
				if(`SCL_LOW) begin
					sda_link <= 1'b1;	//sda置為output
					sda_r <= 1'b1;		//拉高數據線sda
					cstate <= START2;
				end
				else if(`SCL_HIG) begin		//sc1為高電位期間
					sda_r <= 1'b0;			//拉低數據線sda,產生起始位信號
					cstate <= ADD3;
				end
				else cstate <= START2;
			end
			
			ADD3:
			begin		//送讀操作地址
				if(`SCL_LOW) begin
					if(num == 4'd8) begin
						num <= 4'd0;	//num計數清零
						sda_r <= 1'b1;
						sda_link <= 1'b0;	//sda置為高阻態
						cstate <= ACK3;
					end
					else begin
						num <= num + 1'b1;
						case(num)
							4'd0: sda_r <= db_r[7];
							4'd1: sda_r <= db_r[6];
							4'd2: sda_r <= db_r[5];
							4'd3: sda_r <= db_r[4];
							4'd4: sda_r <= db_r[3];
							4'd5: sda_r <= db_r[2];
							4'd6: sda_r <= db_r[1];
							4'd7: sda_r <= db_r[0];
							default: ;
						endcase
						//sda_r <= db_r[4'd7-num]; 	//送EEPROM地址
						cstate <= ADD3;
					end
				end
				//else if(`SCL_POS) db_r <= {db_r[6:0],1'b0};	//器件地址左移
				else cstate <= ADD3;
			end
			ACK3:
			begin
				if(/*!sda*/`SCL_NEG) begin
					cstate <= DATA;		//slave響應信號
					sda_link <= 1'b0;
				end
				else cstate <= ACK3;    //等待slave響應
			end
			
			DATA:
			begin
				if(!sw2_r) begin
					if(num <= 4'd7) begin
						cstate <= DATA;
						if(`SCL_HIG) begin
							num <= num + 1'b1;
							case(num)
							4'd0: sda_r <= db_r[7];
							4'd1: sda_r <= db_r[6];
							4'd2: sda_r <= db_r[5];
							4'd3: sda_r <= db_r[4];
							4'd4: sda_r <= db_r[3];
							4'd5: sda_r <= db_r[2];
							4'd6: sda_r <= db_r[1];
							4'd7: sda_r <= db_r[0];
							default: ;
							endcase
							//read_data[4'd7-num] <= sda; 	//讀數據
						end
						//else if(`SCL_NEG) read_data <= {read_data[6:0],1'b0};
					end
					else if( (`SCL_LOW) && (num==4'd8) ) begin
						num <= 4'd0;		//num計數清零
						cstate <= ACK4;
					end
					else cstate <= DATA;
				end
				else if(!sw1_r) begin		//寫操作
					sda_link <= 1'b1;
					if(num <= 4'd7) begin
						cstate <= DATA;
						if(`SCL_LOW) begin
							sda_link <= 1'b1; 	//數據線sda為output
							num <= num + 1'b1;
							case(num)
							4'd0: sda_r <= db_r[7];
							4'd1: sda_r <= db_r[6];
							4'd2: sda_r <= db_r[5];
							4'd3: sda_r <= db_r[4];
							4'd4: sda_r <= db_r[3];
							4'd5: sda_r <= db_r[2];
							4'd6: sda_r <= db_r[1];
							4'd7: sda_r <= db_r[0];
							default: ;
							endcase
							//sda_r <= db_r[4'd7-num];	//寫入數據
						end
						//else if(`SCL_POS) db_r <= {db_r[6:0],1'b0};
					end
					else if( (`SCL_LOW) && (num == 4'd8) )begin
						num <= 4'd0;
						sda_r <= 1'b1;
						sda_link <= 1'b0;	//sda置為高阻態
						cstate <= ACK4;
					end
					else cstate <= DATA;
				end
			end
			
			ACK4:
			begin
				if(/*!sda*/`SCL_NEG) begin
					//sda_r <= 1'b1;
					cstate <= STOP1;
				end
				else cstate <= ACK4;
			end
			
			STOP1:
			begin
				if(`SCL_LOW) begin
					sda_link <= 1'b1;
					sda_r <= 1'b0;
					cstate <= STOP1;
				end
				else if(`SCL_HIG) begin
					sda_r <= 1'b1;	//sc1為高電位期間,sda產生上升沿
					cstate <= STOP2;
				end
				else cstate <= STOP1;
			end
			
			STOP2:
			begin
				if(`SCL_LOW) sda_r <= 1'b1;
				else if(cnt_20ms == 20'hffff0) cstate <= IDLE;
				else cstate <= STOP2;
			end
			default: cstate <= IDLE;			
		endcase
	end
	
	
end

assign sda = sda_link ? sda_r : 1'bz;	//sda_link : 0為輸入(必須為高阻態) 
										//           1為輸出
assign dis_data = read_data;

endmodule

