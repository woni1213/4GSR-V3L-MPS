`timescale 1 ns / 1 ps

module SFP_Handler_tb();

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

	SFP_Handler_Test_wrapper u_SFP_Handler_Test_wrapper
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

endmodule