`timescale 1ns / 1ps


module deal_process(
	input                       adc_clk,
	input                       rst,
	input[7:0]                  adc_data,
	
	output                      adc_buf_wr,
	output[11:0]                adc_buf_addr,
	output[7:0]                 adc_buf_data
);

//`define TRIGGER
parameter		adc_data_valid =1'd1;

localparam       S_IDLE    = 0;
localparam       S_SAMPLE  = 1;
localparam       S_WAIT    = 2;

reg [7:0]num;
reg[7:0] adc_data_d0;
reg[7:0] adc_data_d1;
reg[10:0] sample_cnt;
reg[31:0] wait_cnt;
reg[2:0] state;
assign adc_buf_addr = sample_cnt;
assign adc_buf_data = adc_data;
assign adc_buf_wr = (state == S_SAMPLE && adc_data_valid == 1'b1) ? 1'b1 : 1'b0;

always@(posedge adc_clk or negedge rst)
begin
	if(rst == 1'b0)
		adc_data_d0 <= 8'd0;
	else if(adc_data_valid == 1'b1)
		adc_data_d0 <= adc_data;
end


always@(posedge adc_clk or negedge rst)
begin
	if(rst == 1'b0)
	begin
		state <= S_IDLE;
		wait_cnt <= 32'd0;
		sample_cnt <= 11'd0;
	end
	else
		case(state)
			S_IDLE:
			begin
				state <= S_SAMPLE;
			end
			S_SAMPLE:
			begin
				if(adc_data_valid == 1'b1)
				begin
					if(sample_cnt == 11'd590)
					begin
						sample_cnt <= 11'd0;
						state <= S_WAIT;
					end
					else
					begin
						sample_cnt <= sample_cnt + 11'd1;
					end
				end
			end		
			S_WAIT:
			begin
//`ifdef  TRIGGER				
//				if(adc_data_valid == 1'b1 && adc_data_d1 < 8'd127 && adc_data_d0 >= 8'd127)
//					state <= S_SAMPLE;
//`else
				if(wait_cnt == 32'd500_500)
				begin
					state <= S_SAMPLE;
					wait_cnt <= 32'd0;
				end
				else
				begin
					wait_cnt <= wait_cnt + 32'd1;
				end
//`endif					
			end	
			default:
				state <= S_IDLE;
		endcase
end

endmodule