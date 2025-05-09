`timescale 1 ns / 1 ps

/*

MPS INTerLock Module
개발 2팀 전경원 부장

25.04.10 :	최초 생성

Interlock이 많아져서 새로 모듈 만듬

 - 

*/

module Osc_INTL
(
	input i_clk,
	input i_rst,

	input i_clr,
	input [31:0] i_data,
	input [31:0] i_data_thresh,
	input [31:0] i_cnt_thresh,
	input [31:0] i_period,
	input [31:0] i_cycle_cnt,

	input i_osc_en,

	output reg o_osc_flag,

	output [2:0] o_state
);

	parameter IDLE	= 0;
	parameter RUN	= 1;
	parameter COUNT	= 2;
	parameter HOLD	= 3;
	parameter RESET	= 4;

	reg [2:0] state;

	reg [31:0] period_cnt;
	reg [31:0] cycle_cnt;
	reg [31:0] osc_cnt;

	wire min_flag;
	wire max_flag;
	wire osc_flag;
	wire osc_valid;
	wire sub_valid;

	reg [31:0] min_buf;
	reg [31:0] max_buf;
	wire [31:0] sub_buf;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			state <= IDLE;

		else if (~i_osc_en)
			state <= IDLE;

		else
		begin
			if (state == IDLE)
				state <= (i_osc_en && ~o_osc_flag) ? RUN : IDLE;

			else if (state == RUN)
				state <= (period_cnt == i_period) ? COUNT : RUN;

			else if (state == COUNT)
				state <= HOLD;

			else if (state == HOLD)
				state <= (osc_valid) ? RESET : HOLD;

			else if (state == RESET)
				state <= (cycle_cnt == i_cycle_cnt + 1) ? IDLE : RUN;

			else
				state <= IDLE;
		end
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst) 
			period_cnt <= 0;

		else
			period_cnt <= (state == RUN) ? period_cnt + 1 : 0;
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst) 
			cycle_cnt <= 0;

		else if (state == IDLE)
			cycle_cnt <= 0;

		else
			cycle_cnt <= (state == COUNT) ? cycle_cnt + 1 : cycle_cnt;
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			min_buf <= 0;

		else if ((state == IDLE) || (state == RESET))
			min_buf <= 0;

		else
			min_buf <= (state == RUN) ? ((min_flag) ? i_data : min_buf) : min_buf;
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst)
			max_buf <= 0;

		else if ((state == IDLE) || (state == RESET))
			max_buf <= 0;

		else
			max_buf <= (state == RUN) ? ((max_flag) ? i_data : max_buf) : max_buf;
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			osc_cnt <= 0;

		else if (state == IDLE)
			osc_cnt <= 0;

		else
			osc_cnt <= (osc_valid) ? ((osc_flag) ? osc_cnt + 1 : ((osc_cnt != 0) ? osc_cnt - 1 : osc_cnt)) : osc_cnt;
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			o_osc_flag <= 0;

		else if (i_clr)
			o_osc_flag <= 0;

		else
			o_osc_flag <= ((osc_cnt >= i_cnt_thresh) && i_osc_en) ? 1 : o_osc_flag;
	end

	floating_point_sub
	u_floating_point_sub
	(
		.aclk(i_clk),
		.s_axis_a_tdata(max_buf),
		.s_axis_a_tvalid(state == COUNT),
		.s_axis_b_tdata(min_buf),
		.s_axis_b_tvalid(state == COUNT),
		.m_axis_result_tdata(sub_buf),
		.m_axis_result_tvalid(sub_valid)
	);

	floating_point_CGE
	u_floating_point_CGE
	(
		.aclk(i_clk),
		.s_axis_a_tdata(sub_buf),
		.s_axis_a_tvalid(sub_valid),
		.s_axis_b_tdata(i_data_thresh),
		.s_axis_b_tvalid(1),
		.m_axis_result_tdata(osc_flag),
		.m_axis_result_tvalid(osc_valid)
	);

	assign max_flag = (i_data[31] != max_buf[31])  ? (i_data[31] == 0) : (i_data[31] == 0)? 
							((i_data[30:23] > max_buf[30:23]) ? 1 :
							(i_data[30:23] < max_buf[30:23]) ? 0 :
							(i_data[22:0] > max_buf[22:0]) ? 1 : 0) 
							:
							((i_data[30:23] < max_buf[30:23]) ? 1 :
							(i_data[30:23] > max_buf[30:23]) ? 0 :
							(i_data[22:0] < max_buf[22:0]) ? 1 : 0);

	assign min_flag = (min_buf[31] != i_data[31])  ? (min_buf[31] == 0) : (min_buf[31] == 0)? 
							((min_buf[30:23] > i_data[30:23]) ? 1 :
							(min_buf[30:23] < i_data[30:23]) ? 0 :
							(min_buf[22:0] > i_data[22:0]) ? 1 : 0) 
							:
							((min_buf[30:23] < i_data[30:23]) ? 1 :
							(min_buf[30:23] > i_data[30:23]) ? 0 :
							(min_buf[22:0] < i_data[22:0]) ? 1 : 0);

	assign o_state = state;

endmodule