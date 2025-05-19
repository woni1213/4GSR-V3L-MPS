`timescale 1 ns / 1 ps

/*

BR MPS System FSM Module
개발 2팀 전경원 부장

o_mc[0] : Main MC (Active 1)
o_mc[1] : Slow Charge MC (Active 1)
o_mc[2] : DisCharge MC (Active 0)

*/

module MPS_System_FSM
(
	input i_clk,
	input i_rst,

	input i_op_on,
	input i_run,
	input i_ready,
	input i_op_off,
	output [2:0] o_mps_fsm_m,
	input [3:0] i_op_on_fsm,
	input [3:0] i_op_off_fsm,

	input i_intl_flag,
	output reg o_op_on_flag,
	output reg o_op_off_flag,

	output reg [2:0] o_mc,
	output o_pwm_en,
	output o_pm
);

	localparam IDLE			= 0;
	localparam OP_ON		= 1;
	localparam OP_ON_HOLD	= 2;
	localparam READY		= 3;
	localparam RUN			= 4;
	localparam OP_OFF		= 5;
	localparam OP_OFF_HOLD	= 6;
	localparam INTL			= 7;

	reg [2:0] state;
	reg [2:0] n_state;

	reg [1:0] pm_cnt;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			state <= IDLE;

		else if (i_intl_flag)
			state <= INTL;

		else 
			state <= n_state;
	end

	always @(*)
	begin
		case (state)
			IDLE		: n_state = (i_op_on) ? OP_ON : IDLE;
			OP_ON		: n_state = OP_ON_HOLD;
			OP_ON_HOLD	: n_state = (i_op_on_fsm == 15) ? IDLE : ((i_op_on_fsm == 14) ? READY : OP_ON_HOLD);
			READY		: n_state = (i_run) ? RUN : ((i_op_off) ? OP_OFF : READY);
			RUN			: n_state = (i_ready) ? READY : RUN;
			OP_OFF		: n_state = OP_OFF_HOLD;
			OP_OFF_HOLD	: n_state = (i_op_off_fsm == 3) ? IDLE : OP_OFF_HOLD;
			INTL		: n_state = IDLE;
			default 	: n_state = IDLE;
		endcase
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_op_on_flag <= 0;

		else
			o_op_on_flag <= (state == OP_ON) ? 1 : 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_op_off_flag <= 0;

		else
			o_op_off_flag <= (state == OP_OFF);
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_mc <= 3'b000;

		else if (state == OP_ON_HOLD)
		begin
			case (i_op_on_fsm)
				0		: o_mc <= 3'b000;
				1		: o_mc <= 3'b100;
				5		: o_mc <= 3'b110;
				9		: o_mc <= 3'b111;
				11		: o_mc <= 3'b101;
				default : o_mc <= o_mc;
			endcase
		end

		else if (state == INTL)
			o_mc <= 3'b000;

		else if (state == OP_OFF_HOLD)
		begin
			case (i_op_off_fsm)
				1		: o_mc <= 3'b100;
				2		: o_mc <= 3'b000;
				default : o_mc <= o_mc;
			endcase
		end

		else
			o_mc <= o_mc;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			pm_cnt <= 0;

		else
			pm_cnt <= (state == INTL) ? ((&pm_cnt) ? pm_cnt : pm_cnt + 1) : 0;
	end

	assign o_pwm_en = (state == RUN);
	assign o_pm = (pm_cnt == 1);
	assign o_mps_fsm_m = state;

endmodule