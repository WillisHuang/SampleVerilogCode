//I2C top
/*
I2C 通信中只涉及兩條信號線，即時鐘線SCL和數據線SDA。
時鐘線的上升沿鎖存數據。
當SCL高電位時，若把SDA由高電位拉到低電位，則表示通信開始；
若把SDA由低電位拉到高電位，則表示通信結束。

最低位R/W表示讀或寫，1:讀 ; 0:寫

`define DEVICE_READ		8'b1010_0001	//被尋址器件地址(讀操作)
`define DEVICE_WRITE	8'b1010_0000	//被尋址器件地址(寫操作)
`define WRITE_DATA		8'b1101_0001	//寫入EEPROM的數據
`define BYTE_ADDR		8'b0000_0011	//寫入/讀出 EEPROM的地址寄存器
*/

module iic_top(
	clk, rst_n,
	sw1, sw2,
	scl, sda,
	sm_cs1_n,sm_cs2_n,sm_db
);

input clk;		//50MHz
input rst_n;	//reset signal, active low
input sw1, sw2;	//按鍵1, 2 (1按下執行寫入操作, 2按下執行讀操作)
output scl;		//24C02的時鐘端口
inout sda;		//24C02的數據端口

output sm_cs1_n,sm_cs2_n;	//7段顯示器選擇信號,active low
output [6:0] sm_db;	//7段顯示LED管，不含小數點

wire [7:0] dis_data;	//在數碼管上顯示的16進制數

iic_com			iic_com(
						.clk(clk),
						.rst_n(rst_n),
						.sw1(sw1),
						.sw2(sw2),
						.scl(scl),
						.sda(sda),
						.dis_data(dis_data)
						);

led_seg7		led_seg7(
						  .clk(clk),
						  .rst_n(rst_n),
						  .dis_data(dis_data),
						  .sm_cs1_n(sm_cs1_n),
						  .sm_cs2_n(sm_cs2_n),
						  .sm_db(sm_db)
						);

endmodule



