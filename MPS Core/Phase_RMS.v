`timescale 1 ns / 1 ps
/*

BR MPS Phase RMS Module
개발 2팀 전경원 부장

25.04.24 :	최초 생성

1. 개요
 3상 전압을 RMS로 변환

*/

module Phase_RMS
(
	input i_clk,
	input i_rst,

	input [31:0] i_phase,
	output reg [31:0] o_rms,

	output [1:0] o_state
);

	localparam IDLE	= 0;
	localparam RUN	= 1;
	localparam CALC	= 2;
	localparam DONE	= 3;

	localparam CYCLE_60HZ = 22'd3333333;

	reg [1:0] state;
	reg [1:0] n_state;

	reg [21:0] period_cnt;
	reg [31:0] max_buf;
	wire max_flag;
	wire [31:0] rms_buf;
	wire rms_valid;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			state <= IDLE;

		else 
			state <= n_state;
	end

	always @(*)
	begin
		case (state)
			IDLE	: n_state = RUN;
			RUN		: n_state = (period_cnt >= CYCLE_60HZ) ? CALC : RUN;
			CALC	: n_state = DONE;
			DONE	: n_state = (rms_valid) ? IDLE : DONE;
			default : n_state = IDLE;
		endcase
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst) 
			period_cnt <= 0;

		else
			period_cnt <= (state == RUN) ? period_cnt + 1 : 0;		// 16.666 ms
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			max_buf <= 0;

		else if (state == IDLE)
			max_buf <= 0;

		else
			max_buf <= (max_flag && (state == RUN)) ? i_phase : max_buf;
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			o_rms <= 0;

		else
			o_rms <= (rms_valid) ? rms_buf : o_rms;
	end

	assign max_flag = (i_phase[31] != max_buf[31])  ? (i_phase[31] == 0) : (i_phase[31] == 0)? 
							((i_phase[30:23] > max_buf[30:23]) ? 1 :
							(i_phase[30:23] < max_buf[30:23]) ? 0 :
							(i_phase[22:0] > max_buf[22:0]) ? 1 : 0) 
							:
							((i_phase[30:23] < max_buf[30:23]) ? 1 :
							(i_phase[30:23] > max_buf[30:23]) ? 0 :
							(i_phase[22:0] < max_buf[22:0]) ? 1 : 0);

	floating_point_mul
	u_floating_point_mul_rms
	(
		.aclk(i_clk),
		.s_axis_a_tdata(max_buf),
		.s_axis_a_tvalid(state == CALC),
		.s_axis_b_tdata(32'h3f3504f3),			// 0.70710678
		.s_axis_b_tvalid(1),
		.m_axis_result_tdata(rms_buf),
		.m_axis_result_tvalid(rms_valid)
	);

	assign o_state = state;

endmodule