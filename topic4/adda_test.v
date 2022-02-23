`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module adda_test(
    input clk,            //fpga clock
	 
	 output daclk,
    output [7:0] dadata,       //DA data
	 
	 output adclk,
	 input [7:0] addata,         //AD data
	
	 input           rst,      //复位信号
	 input 			  key1,
	 output          lcd_hs,         //LCD 行同步信号
    output          lcd_vs,         //LCD 场同步信号
    output          lcd_de,         //LCD 数据输入使能
    output  [23:0]  lcd_rgb,        //LCD RGB565颜色数据
    output          lcd_pclk        //LCD 采样时钟
    );


reg [8:0] rom_addr0;
reg [8:0] rom_addr1;
reg [8:0] rom_addr2;

reg [7:0] ad_data;
reg [1:0] lcd_dis_mode=2'b00;
reg [23:0] key1_counter; 
reg [7:0] rom_data;

wire [7:0] rom_data0;
wire [7:0] rom_data1;
wire [7:0] rom_data2;


wire ad_clk;
wire clk0;


wire         lcd_clk_w;             //PLL分频得到9Mhz时钟
wire         locked_w;              //PLL输出稳定信号
wire         rst_n_w;               //内部复位信号
wire [15:0]  pixel_data_w;          //像素点数据
wire [ 9:0]  pixel_xpos_w;          //像素点横坐标
wire [ 9:0]  pixel_ypos_w;          //像素点纵坐标

assign daclk=da_clk;
assign adclk=ad_clk;
assign dadata=rom_data;

assign rst_n_w = rst ;


//DA output sin waveform
always @(negedge clk)//da_clk
begin
     rom_addr0 <= rom_addr0 + 1'b1 ; 
     rom_addr1 <= rom_addr1 + 1'b1 ; 
     rom_addr2 <= rom_addr2 + 1'b1 ; 

end 

always @(posedge ad_clk)
begin
      ad_data <= addata ;  //AD输出
end 

always@(posedge clk or negedge rst)
begin
    if(~rst) 
	 begin 
	    lcd_dis_mode<=2'b00;  
		 key1_counter<=0;	 
	 end	
	 
	 else 
	 begin
	    if (key1==1'b1)                               //如果按钮没有按下，寄存器为0
	       key1_counter<=0;
	    else if ((key1==1'b0)& (key1_counter<=24'd899_999))      //如果按钮按下并按下时间少于1ms,计数(9M*0.1-1=4_999_999)     
          key1_counter<=key1_counter+1'b1;
  	  
       if (key1_counter==24'd899_999)                //一次按钮有效，改变显示模式
		    begin
		      if(lcd_dis_mode==2'b10)
			      lcd_dis_mode<=2'b00;
			   else
			      lcd_dis_mode<=lcd_dis_mode+1'b1; 
          end	
     end		
end

always@(posedge clk)
begin
		case(lcd_dis_mode)
		2'b00:
		begin
			rom_data = rom_data0;
		end
		2'b01:
		begin
			rom_data = rom_data1;
		end
		2'b10:
		begin
			rom_data = rom_data2;
		end
		default:
		begin
			rom_data = rom_data0;
		end
			
		endcase
end

rom rom_inst0 (
  .clock(da_clk), //da_clk*3
  .address(rom_addr0), 
  .q(rom_data0) 
);

rom_sanjiao rom_inst1 (
  .clock(da_clk), 
  .address(rom_addr1), 
  .q(rom_data1) 
);

rom_juchi rom_inst2 (
  .clock(da_clk), 
  .address(rom_addr2), 
  .q(rom_data2) 
);

   
pll	u_pll(                  //时钟分频模块
	.inclk0         (clk),    
	.areset         (~sys_rst_n),
    
	.c0             (ad_clk),    //33,9
	.c1				 (lcd_clk_w),
	.locked         (locked_w)
	); 
	
pll125 u_pll125(//125
	.inclk0(clk),
	.c0(da_clk));
	

	
	
	
lcd_driver u_lcd_driver(            //lcd驱动模块
    .lcd_clk        (lcd_clk_w),    //
    .sys_rst_n      (rst_n_w),    

    .lcd_hs         (lcd_hs),       
    .lcd_vs         (lcd_vs),       
    .lcd_de         (lcd_de),       
    .lcd_rgb        (lcd_rgb),
    .lcd_bl         (),
    .lcd_rst        (sys_rst_n),
    .lcd_pclk       (lcd_pclk),
    
    .pixel_data     (pixel_data_w), 
    .pixel_xpos     (pixel_xpos_w), 
    .pixel_ypos     (pixel_ypos_w)
    ); 
    
lcd_display u_lcd_display(          //lcd显示模块
	 .clk00(clk0),
	 .clk0(ad_clk),
    .lcd_clk        (lcd_clk_w),    //
    .sys_rst_n      (rst_n_w),
    .key(key1),
	 .AD_data		  (ad_data),
    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .pixel_data     (pixel_data_w)
    ); 


endmodule
