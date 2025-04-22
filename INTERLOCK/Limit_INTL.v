`timescale 1 ns / 1 ps

/*

MPS INTerLock Module
개발 2팀 전경원 부장

25.04.10 :	최초 생성

Interlock이 많아져서 새로 모듈 만듬

*/

module Limit_INTL
(
	input i_clk,
	input i_rst,

	input [31:0] i_data,
	input [31:0] i_over_sp,
	input [31:0] i_under_sp,

	input i_clr,
	input i_over_en,
	input i_under_en,

	output reg o_over_flag,
	output reg o_under_flag
);

	wire over_flag;
	wire under_flag;
	wire over_valid;
	wire under_valid;

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			o_over_flag <= 0;

		else
			o_over_flag <= (over_flag && over_valid) ? 1 : ((i_clr) ? 0 : o_over_flag);
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			o_under_flag <= 0;

		else
			o_under_flag <= (under_flag && under_valid) ? 1 : ((i_clr) ? 0 : o_under_flag);
	end


	floating_point_CGT			// A > B
	u_floating_point_CGT_over
	(
		.aclk(i_clk),
		.s_axis_a_tdata(i_data),
		.s_axis_a_tvalid(i_over_en),
		.s_axis_b_tdata(i_over_sp),
		.s_axis_b_tvalid(i_over_en),
		.m_axis_result_tdata(over_flag),
		.m_axis_result_tvalid(over_valid)
	);

	floating_point_CGT			// A > B
	u_floating_point_CGT_under
	(
		.aclk(i_clk),
		.s_axis_a_tdata(i_under_sp),
		.s_axis_a_tvalid(i_under_en),
		.s_axis_b_tdata(i_data),
		.s_axis_b_tvalid(i_under_en),
		.m_axis_result_tdata(under_flag),
		.m_axis_result_tvalid(under_valid)
	);

endmodule