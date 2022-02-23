`timescale 1ns / 1ps

module lcd_display(
	 input				 clk00,//50M
	 input				 clk0,//adc
    input             lcd_clk,                  //lcd驱动时钟
    input             sys_rst_n,                //复位信号
    input				 key,
	 input 		[7:0] AD_data,							//AD输出
    input      [11:0] pixel_xpos,               //像素点横坐标
    input      [11:0] pixel_ypos,               //像素点纵坐标    
    output reg [23:0] pixel_data                //像素点数据,
    );    

//reg define
reg  [10:0] char[370:0]; 

reg  [10:0]num=11'd0;
reg  [9:0] rdaddress;
reg  [9:0] wraddress;
reg[8:0]   grid_x;
reg		flag0=1'd0;
reg		flag1=1'd0;

//wire define   
wire  [7:0] q;
wire [10:0] x_cnt;
wire [10:0] y_cnt;
wire	adc0_buf_wr;
wire[10:0]   adc0_buf_addr;
wire[7:0]    adc0_buf_data;



always@(posedge clk0)
begin
		wraddress <= wraddress + 10'd1;

end

always@(posedge lcd_clk)
begin
		grid_x <= (grid_x == 9'd9) ? 9'd0 : grid_x + 9'd1;		
end

always@(posedge clk0)
begin
		rdaddress <= rdaddress + 10'd1;
end

always@(posedge lcd_clk or negedge key or negedge sys_rst_n)
begin
		if(key==1'd0 || sys_rst_n==1'd0)
		begin
			flag0<=1'd0;
			num<=11'd0;
		end
		else
		begin
			if(num==11'd370)
			begin
				flag0<=1'd1;
				num<=11'd0;
			end
			else
				num<=num+1'd1;
				
			if(flag0==1'd0)
				char[num]<=q;
		end

end

always@(posedge lcd_clk)
begin
		if(pixel_xpos>55 && pixel_xpos<429)
		begin
			if((grid_x==9'd9 && pixel_ypos[0] == 1'b1) || pixel_ypos==11'd136)
				pixel_data <= 24'b00000000_00001111_00001111;
			else if(11'd267-pixel_ypos==char[pixel_xpos-56])
					pixel_data <= 24'b00000000_00000000_11111111;
			else
					pixel_data <= 24'b11111111_00000000_00000000;
			end
		else
			pixel_data <= 24'b11111111_00000000_00000000;


end

ram2 u_ram2(
	.data(AD_data),//AD_data
	.rdaddress(rdaddress),
	.rdclock(clk0),
	.wraddress(wraddress),//wraddress
	.wrclock(clk0),
	.wren(1'd1),//1'd1
	.q(q));



endmodule 