`timescale 1 ns / 1 ps

module MPS_Operation_FSM_tb();

	reg i_clk_0;
	reg [31:0] i_dc_v_0;
	reg [3:0] i_ext_di_0;
	reg [2:0] i_mc_0;
	reg i_op_intl_0;
	reg i_op_off_flag_0;
	reg i_op_on_flag_0;
	reg i_rst_0;

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

	always #2.5 i_clk_0 = ~i_clk_0;

	initial
	begin
		i_clk_0 = 1;
		i_dc_v_0 = 0;
		i_ext_di_0 = 0;
		i_mc_0 = 0;
		i_op_intl_0 = 0;
		i_op_off_flag_0 = 0;
		i_op_on_flag_0 = 0;
		i_rst_0 = 0;


		#10 
		i_rst_0 = 1;

		// OP On Start
		#100
		i_op_on_flag_0 = 1;
		#5
		i_op_on_flag_0 = 0;

		// OP Off Start
		#1000
		i_op_off_flag_0 = 1;
		#5
		i_op_off_flag_0 = 0;
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