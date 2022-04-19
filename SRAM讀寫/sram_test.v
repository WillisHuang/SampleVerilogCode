//SRAM read write

`timescale 1ns/1ps

module sram_test(
	clk,rst_n,led,
	sram_addr,sram_wr_n,sram_data
);

input clk;		//50MHz
input rst_n;	//reset, active low
output led;		//LED1

//CPLD and SRAM 外部接口
output [14:0] sram_addr;	//SRAM地址總線
output sram_wr_n;			//SRAM 寫 enable active low
inout [7:0] sram_data;		//SRAM 數據總線

//---------------------------------------------------------
reg [25:0] delay;		//延時計數器

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) delay <= 26'd0;
	else delay <= delay + 1'b1;		//不斷計數,週期為1.28s
end	

//---------------------------------------------------------
reg [7:0] wr_data;	//SRAM寫入數據總線
reg [7:0] rd_data;	//SRAM讀出數據
reg [14:0] addr_r;	//SRAM地址總線
wire sram_wr_req;	//SRAM寫請求信號
wire sram_rd_req;	//SRAM讀請求信號
reg led_r;			//LED暫存器

assign sram_wr_req = (delay == 26'd9999);	//產生寫請求信號
assign sram_rd_req = (delay == 26'd19999);	//產生讀請求信號

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) wr_data <= 8'd0;
	else if(delay == 26'd29999) wr_data <= wr_data + 1'b1;	//寫入數據每1.28秒
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) addr_r <= 15'd0;
	else if (delay == 26'd29999) addr_r <= addr_r + 1'b1; 	//寫入地址每1.28s自增
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) led_r <= 1'b0;
	else if(delay == 26'd20099) begin			//每1.28s比較一次同一地址寫入和讀出的數據
		if(wr_data == rd_data) led_r <= 1'b1;	//寫入和讀出數據一致
		else led_r <= 1'b0;						//寫入和讀出數據不同
	end
end

assign led = led_r;

//---------------------------------------------------------------------------------
reg [2:0] cnt;		//延時計數器
reg [3:0] cstate,nstate;


`define DELAY_80NS		(cnt == 3'd7)

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) cnt <= 3'd0;
	else if (cstate == IDLE) cnt <= 3'd0;
	else cnt <= cnt + 1'b1;
end
//---------------------------------------------------------------------------------
//兩段式狀態機
parameter 	IDLE	= 4'd0,
			WRT0	= 4'd1,
			WRT1	= 4'd2,
			REA0	= 4'd3,
			REA1	= 4'd4;

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) cstate <= IDLE;
	else cstate <= nstate;
end

always@(cstate or sram_wr_req or sram_rd_req or cnt)
begin
	case(cstate)
		IDLE:	if(sram_wr_req) nstate <= WRT0;			//進入寫狀態
				else if(sram_rd_req) nstate <= REA0;	//進入讀狀態
				else nstate <= IDLE;
		
		WRT0:	if(`DELAY_80NS) nstate <= WRT1;
				else nstate <= WRT0;					//延時等待160ns
		
		WRT1:	nstate <= IDLE;							//寫結束,返回
		
		REA0: 	if(`DELAY_80NS) nstate <= REA1;			
				else nstate <= REA0;					//延時等待160ns
		
		REA1:	nstate <= IDLE;							//讀結束,返回
		
		default: nstate <= IDLE;
	endcase
end


//---------------------------------------------------------------------
assign sram_addr = addr_r;		//SRAM地址總線連接
//---------------------------------------------------------------------

reg sdlink;		//SRAM數據總線控制信號

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) rd_data <= 8'd0;
	else if(cstate == REA1) rd_data <= sram_data;		//讀出數據
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) sdlink <= 1'b0;
	else begin
		case(cstate)
			IDLE:	if(sram_wr_req) sdlink <= 1'b1;			//進入連續寫狀態
					else if (sram_rd_req) sdlink <= 1'b0;	//進入單字節讀狀態
					else sdlink <= 1'b0;
			
			WRT0:	sdlink <= 1'b1;
			default: sdlink <= 1'b0;
		endcase
	end
end

assign sram_data = sdlink ? wr_data : 8'hzz;			//SRAM地址總線連接(讀的時候須高阻態)
assign sram_wr_n = ~sdlink;

endmodule
