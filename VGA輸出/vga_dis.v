/*--------------------------------------------------------------------
VGA display:

VGA 時序表

同步脈衝	後沿	顯示脈衝	後沿	幀長
  120		 67		   800		 52		1039
   6	  	 25		   600		 56		 665
   

//範例為一個刷新頻率60Hz, 分辨率為800*600 , 時鐘頻率為50MHz
顯示背景為藍色,中央顯示一個綠色邊框和一個粉色矩形。

---------------------------------------------------------------------*/

module vga_dis(
	clk, rst_n,
	hsync,vsync,vga_r,vga_g,vga_b
);

input clk;	//50MHz
input rst_n;	//reset signal , active low
output hsync;	//行同步信號
output vsync;	//場同步信號
output vga_r;	
output vga_g;
output vga_b;

//---------------------------------------------------------------------
reg [10:0]	x_cnt;	//行座標
reg [9:0]	y_cnt;	//列座標

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) x_cnt <= 11'd0;
	else if (x_cnt == 11'd1039) x_cnt <= 11'd0;
	else x_cnt <= x_cnt + 1'b1;
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) y_cnt <= 10'd0;
	else if (y_cnt == 10'd665) y_cnt <= 10'd0;
	else if (x_cnt == 11'd1039) y_cnt <= y_cnt + 1'b1;	
end

//---------------------------------------------------------------------
wire valid;		//有效顯示區標誌

assign valid = (x_cnt >= 11'd187) && (x_cnt < 11'd987) 		// 行有效期間 : 987 - 187(120 + 67) = 800
				&& (y_cnt >= 10'd31) && (y_cnt < 10'd631);	// 列有效期間 : 631 - 31(6 + 25) = 600

wire [9:0] xpos,ypos;	//有效顯示區座標

assign xpos = x_cnt - 11'd187; 		//x有效座標為0, 從187的位置歸零
assign ypos = y_cnt - 10'd31;		//y有效座標為0, 從31的位置歸零

//---------------------------------------------------------------------
reg hsync_r, vsync_r;	//同步信號產生

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) hsync_r <= 1'b1;
	else if (x_cnt == 11'd0) hsync_r <= 1'b0;	//產生hsync信號
	else if (x_cnt == 11'd120) hsync_r <= 1'b1;
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) vsync_r <= 1'b1;
	else if(y_cnt == 10'd0) vsync_r <= 1'b0;	//產生vsync信號
	else if(y_cnt == 10'd6) vsync_r <= 1'b1;
end

assign hsync = hsync_r;
assign vsync = vsync_r;

//---------------------------------------------------------------------
//顯示一個矩形框

wire a_dis, b_dis, c_dis, d_dis;	//矩形框顯示區域定位

assign a_dis = ( (xpos>=200) && (xpos<=220) )
				&&( (ypos>=140) && (ypos<=460) );

assign b_dis = ( (xpos>=580) && (xpos<=600) )
				&&( (ypos>=140) && (ypos<=460) );

assign c_dis = ( (xpos>=220) && (xpos<=580) )
				&&( (ypos>=140) && (ypos<=160) );
				
assign d_dis = ( (xpos>=220) && (xpos<=580) )
				&&( (ypos>=440) && (ypos<=460) );
//---------------------------------------------------------------------
//顯示一個小矩形

wire e_rdy;		//矩形的顯示有效矩形區域

assign e_rdy = ( (xpos>=385) && (xpos<=415) )
				&& ( (ypos>=285) && (ypos<=315) );

//---------------------------------------------------------------------
//r, g, b控制液晶顏色顯示，背景為藍色，矩形框顯示紅藍色

assign vga_r = valid ? e_rdy : 1'b0;
assign vga_g = valid ?  (a_dis | b_dis | c_dis | d_dis) : 1'b0;
assign vga_b = valid ? ~(a_dis | b_dis | c_dis | d_dis) : 1'b0;

endmodule