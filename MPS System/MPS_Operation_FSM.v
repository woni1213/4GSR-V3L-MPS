`timescale 1 ns / 1 ps

/*

BR MPS System Operation Module
개발 2팀 전경원 부장

*/

module MPS_Operation_FSM
(
	input i_clk,
	input i_rst,

	input i_op_on_flag,
	input i_op_off_flag,
	input i_op_intl,

	input [31:0] i_dc_v,
	input [15:0] i_ext_di,

	output reg [3:0] o_on_state_fail_buf,
	output [3:0] o_on_state,
	output [3:0] o_off_state
);

	localparam IDLE			= 0;
	localparam CLR			= 1;
	localparam DISCHA_CHK	= 4;
	localparam DISCHA_DONE	= 5;
	localparam SLOW_ON_CHK	= 6;
	localparam SLOW_ON_DONE	= 7;
	localparam DC_CHK		= 8;
	localparam DC_DONE		= 9;
	localparam MAIN_CHK		= 10;
	localparam MAIN_DONE	= 11;
	localparam SLOW_OFF_CHK	= 12;
	localparam SLOW_OFF_DONE= 13;
	localparam SYSTEM_ON	= 14;
	localparam FAIL			= 15;

	localparam MAIN_OFF		= 1;
	localparam DISCHA_ON	= 2;
	localparam SYSTEM_OFF	= 3;

	localparam TIME_OUT	= 2_000_000_000;		// 10s

	reg [3:0] on_state;
	reg [3:0] n_on_state;
	reg [3:0] off_state;
	reg [3:0] n_off_state;

	reg [27:0] on_hold_cnt;
	reg [27:0] off_hold_cnt;
	reg [28:0] timeout_cnt;

	reg [30:0] off_timeout_cnt;

	wire dc_on_flag;
	wire dc_on_valid;
	wire dc_off_flag;
	wire dc_off_valid;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			on_state <= IDLE;

		else if ((i_op_intl) || (&timeout_cnt))
			on_state <= FAIL;

		else
			on_state <= n_on_state;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			off_state <= IDLE;

		else 
			off_state <= (off_timeout_cnt == (TIME_OUT - 1)) ? FAIL : n_off_state;
	end

	always @(*)
	begin
		case (on_state)
			IDLE			: n_on_state = (i_op_on_flag) ? CLR : IDLE;
			CLR				: n_on_state = DISCHA_CHK;
			DISCHA_CHK		: n_on_state = ((&on_hold_cnt) && (~i_ext_di[3])) ? DISCHA_DONE : DISCHA_CHK;
			DISCHA_DONE		: n_on_state = SLOW_ON_CHK;
			SLOW_ON_CHK		: n_on_state = ((&on_hold_cnt) && (i_ext_di[2])) ? SLOW_ON_DONE : SLOW_ON_CHK;
			SLOW_ON_DONE	: n_on_state = DC_CHK;
			DC_CHK			: n_on_state = (dc_on_flag && dc_on_valid) ? DC_DONE : DC_CHK;
			DC_DONE			: n_on_state = MAIN_CHK;
			MAIN_CHK		: n_on_state = ((&on_hold_cnt) && (i_ext_di[1])) ? MAIN_DONE : MAIN_CHK;
			MAIN_DONE		: n_on_state = SLOW_OFF_CHK;
			SLOW_OFF_CHK	: n_on_state = ((&on_hold_cnt) && (~i_ext_di[2])) ? SLOW_OFF_DONE : SLOW_OFF_CHK;
			SLOW_OFF_DONE	: n_on_state = SYSTEM_ON;
			SYSTEM_ON		: n_on_state = (off_state == SYSTEM_OFF) ? IDLE : SYSTEM_ON;
			FAIL			: n_on_state = IDLE;
			default 		: n_on_state = IDLE;
		endcase
	end

	always @(*)
	begin
		case (off_state)
			IDLE			: n_off_state = (i_op_off_flag) ? MAIN_OFF : IDLE;
			MAIN_OFF		: n_off_state = (&off_hold_cnt) ? DISCHA_ON : MAIN_OFF;
			DISCHA_ON		: n_off_state = (dc_off_flag && dc_off_valid) ? SYSTEM_OFF : DISCHA_ON;
			SYSTEM_OFF		: n_off_state = IDLE;
			FAIL			: n_off_state = IDLE;
			default 		: n_off_state = IDLE;
		endcase
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_on_state_fail_buf <= 0;

		else if (on_state == CLR)
			o_on_state_fail_buf <= 0;

		else
			o_on_state_fail_buf <= (on_state > o_on_state_fail_buf) ? ((on_state == 15) ? o_on_state_fail_buf : on_state) : o_on_state_fail_buf;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			on_hold_cnt <= 0;

		else
			on_hold_cnt <= (on_state[0]) ? 0 : 
							((&on_hold_cnt) ? on_hold_cnt : 
							((on_state == 0) || (on_state == 14) || (on_state == 8)) ? 0 : on_hold_cnt + 1);
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			off_hold_cnt <= 0;

		else
			off_hold_cnt <= (off_state == MAIN_OFF) ? off_hold_cnt + 1 : 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			timeout_cnt <= 0;

		else
			timeout_cnt <= (&on_hold_cnt) ? ((&timeout_cnt) ? timeout_cnt : timeout_cnt + 1) : 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			off_timeout_cnt <= 0;

		else
			off_timeout_cnt <= ((off_state == IDLE) || (off_state == FAIL)) ? 0 : (off_timeout_cnt == (TIME_OUT - 1)) ? off_timeout_cnt : off_timeout_cnt + 1;
	end

	// A > B
	floating_point_CGT floating_point_CGT_op_on
	(
		.aclk(i_clk),
		.s_axis_a_tdata(i_dc_v),
		.s_axis_a_tvalid(on_state == DC_CHK),
		// .s_axis_b_tdata(32'h43898000),			// 275
		.s_axis_b_tdata(32'h43858000),			// 267
		.s_axis_b_tvalid(on_state == DC_CHK),
		.m_axis_result_tdata(dc_on_flag),
		.m_axis_result_tvalid(dc_on_valid)
	);

	// A > B
	floating_point_CGT floating_point_CGT_op_off
	(
		.aclk(i_clk),
		.s_axis_a_tdata(32'h41200000),				// 10
		.s_axis_a_tvalid(off_state == DISCHA_ON),
		.s_axis_b_tdata(i_dc_v),
		.s_axis_b_tvalid(off_state == DISCHA_ON),
		.m_axis_result_tdata(dc_off_flag),
		.m_axis_result_tvalid(dc_off_valid)
	);

	assign o_on_state = on_state;
	assign o_off_state = off_state;

endmodule