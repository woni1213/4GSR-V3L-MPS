`timescale 1 ns / 1 ps

/*

MPS INTerLock Module
개발 2팀 전경원 부장

25.04.10 :	최초 생성

Interlock이 많아져서 새로 모듈 만듬

 - 출력값을 변경하는 경우 바로 동작
 - 일정시간 (i_delay) 뒤에 설정한 출력 값에 도달하지 못하는 경우 (i_diff > i_set_point - i_data) 발생

*/

module Regu_INTL
(
	input i_clk,
	input i_rst,

	input i_clr,
	input [31:0] i_data,
	input [31:0] i_set_point,
	input [31:0] i_diff,
	input [31:0] i_delay,

	input i_regu_en,

	output reg o_regu_flag,

	output [1:0] o_state,
	output reg [31:0] o_regu_sub
);

	parameter IDLE	= 0;
	parameter DELAY	= 1;
	parameter RUN	= 2;
	parameter DONE	= 3;

	reg [1:0] state;

	reg [31:0] sp_buf;
	wire [31:0] sub_buf;
	wire [31:0] abs_buf;
	reg [31:0] delay_cnt;

	wire sp_flag;
	wire sub_valid;
	wire abs_valid;
	wire comp_valid;
	wire regu_flag;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			state <= IDLE;

		else
		begin
			if (state == IDLE)
				state <= (sp_flag && i_regu_en && ~o_regu_flag) ? DELAY : IDLE;

			else if (state == DELAY)
				state <= (delay_cnt >= i_delay) ? RUN : DELAY;
				
			else if (state == RUN)
				state <= DONE;

			else if (state == DONE)
				state <= (comp_valid) ? IDLE : DONE;

			else
				state <= IDLE;
		end
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			sp_buf <= 0;

		else
			sp_buf <= i_set_point;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			delay_cnt <= 0;

		else
			delay_cnt <= (state == DELAY) ? delay_cnt + 1 : 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_regu_flag <= 0;

		else
			o_regu_flag <= (regu_flag && comp_valid) ? 1 : ((i_clr) ? 0 : o_regu_flag);
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_regu_sub <= 0;

		else
			o_regu_sub <= (abs_valid) ? abs_buf : o_regu_sub;
	end

	floating_point_sub
	u_floating_point_sub_regu
	(
		.aclk(i_clk),
		.s_axis_a_tdata(i_set_point),
		.s_axis_a_tvalid(state == RUN),
		.s_axis_b_tdata(i_data),
		.s_axis_b_tvalid(state == RUN),
		.m_axis_result_tdata(sub_buf),
		.m_axis_result_tvalid(sub_valid)
	);

	floating_point_abs
	u_floating_point_abs_regu
	(
		.s_axis_a_tdata(sub_buf),
		.s_axis_a_tvalid(sub_valid),
		.m_axis_result_tdata(abs_buf),
		.m_axis_result_tvalid(abs_valid)
	);

	floating_point_CGT
	u_floating_point_CGT_regu
	(
		.aclk(i_clk),
		.s_axis_a_tdata(abs_buf),
		.s_axis_a_tvalid(abs_valid),
		.s_axis_b_tdata(i_diff),
		.s_axis_b_tvalid(abs_valid),
		.m_axis_result_tdata(regu_flag),
		.m_axis_result_tvalid(comp_valid)
	);

	assign o_state = state;
	assign sp_flag = (sp_buf != i_set_point);

endmodule