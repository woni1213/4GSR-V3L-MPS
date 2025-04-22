`timescale 1 ns / 1 ps

module MPS_System_FSM_tb();

	reg i_clk_0;
	reg [31:0] i_dc_v_0;
	reg [3:0] i_ext_di_0;
	reg [2:0] i_mc_0;
	reg i_op_intl_0;
	wire i_op_off_flag_0;
	wire i_op_on_flag_0;
	reg i_rst_0;

	reg i_op_on;
	reg i_op_man_stop;
	reg i_run;
	reg i_ready;
	reg i_op_off;
	reg i_op_mode;
	reg i_intl_flag;

	wire [3:0] o_off_state_0;
	wire [3:0] o_on_state_0;

	Operation_wrapper u_Operation_wrapper
	(
		.i_clk_0(i_clk_0),
		.i_dc_v_0(i_dc_v_0),
		.i_ext_di_0(i_ext_di_0),
		.i_mc_0(i_mc_0),
		.i_op_intl_0(i_op_intl_0),
		.i_op_off_flag_0(i_op_off_flag_0),
		.i_op_on_flag_0(i_op_on_flag_0),
		.i_rst_0(i_rst_0),

		.o_off_state_0(o_off_state_0),
		.o_on_state_0(o_on_state_0)
	);

	MPS_System_FSM u_MPS_System_FSM
	(
		.i_clk(i_clk_0),
		.i_rst(i_rst_0),

		.i_op_on(i_op_on),
		.i_op_man_stop(i_op_man_stop),
		.i_run(i_run),
		.i_ready(i_ready),
		.i_op_off(i_op_off),

		.i_op_on_fsm(o_on_state_0),
		.i_op_off_fsm(o_off_state_0),

		.i_op_mode(i_op_mode),
		.i_intl_flag(i_intl_flag),
		.o_op_on_flag(i_op_on_flag_0),
		.o_op_off_flag(i_op_off_flag_0)

	);


	always #2.5 i_clk_0 = ~i_clk_0;

	initial
	begin
		i_clk_0 = 1;
		i_dc_v_0 = 0;
		i_ext_di_0 = 0;
		i_mc_0 = 0;
		i_op_intl_0 = 0;
		i_rst_0 = 0;

		i_op_on = 0;
		i_op_man_stop = 0;
		i_run = 0;
		i_ready = 0;
		i_op_off = 0;
		i_op_mode = 0;
		i_intl_flag = 0;

		#10 
		i_rst_0 = 1;

		// OP On Start
		#100
		i_op_on = 1;
		#5
		i_op_on = 0;

		// RUN
		#1000
		i_run = 1;
		#5
		i_run = 0;

		// Ready
		#100
		i_ready = 1;
		#5
		i_ready = 0;

		// RUN
		#100
		i_run = 1;
		#5
		i_run = 0;

		// Interlock
		#100
		i_intl_flag = 1;
		#5
		i_intl_flag = 0;

		// Wrong Control
		#100
		i_op_off = 1;
		#5
		i_op_off = 0;

		// Ready
		#100
		i_ready = 1;
		#5
		i_ready = 0;

		// OP Off
		#100
		i_op_off = 1;
		#5
		i_op_off = 0;

	end

	always @(posedge i_clk_0)
	begin
		if (o_on_state_0 == 2)			// Phase Check 
			i_ext_di_0[3] <= 0;

		else if (o_on_state_0 == 4)		// Discharge Off Check
			i_ext_di_0[3] <= 0;

		else if (o_on_state_0 == 6)		// Slow On Check
			i_ext_di_0[2] <= 1;

		else if (o_on_state_0 == 8)		// DC Link Check
			i_dc_v_0 <= 132'h438c8000;

		else if (o_on_state_0 == 10)	// Main Check
			i_ext_di_0[1] <= 1;

		else if (o_on_state_0 == 12)	// Slow Off Check
			i_ext_di_0[2] <= 0;
	end

	always @(posedge i_clk_0)
	begin
		if (o_off_state_0 == 2)			// DC Link Check
			i_dc_v_0 <= 32'h41100000;
	end

endmodule