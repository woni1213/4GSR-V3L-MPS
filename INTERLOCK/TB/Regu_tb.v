`timescale 1 ns / 1 ps

module Regu_tb();

	reg i_clk_0;
	reg i_clr_0;
	reg [31:0]i_data_0;
	reg [31:0]i_delay_0;
	reg [31:0]i_diff_0;
	reg i_regu_en_0;
	reg i_rst_0;
	reg [31:0] i_set_point_0;

	Regu_wrapper u_Regu_wrapper
	(
		.i_clk_0(i_clk_0),
		.i_clr_0(i_clr_0),
		.i_data_0(i_data_0),
		.i_delay_0(i_delay_0),
		.i_diff_0(i_diff_0),
		.i_regu_en_0(i_regu_en_0),
		.i_rst_0(i_rst_0),
		.i_set_point_0(i_set_point_0)
	);

	always #5 i_clk_0 = ~i_clk_0;

	initial
	begin
		i_clk_0 = 1;
		i_rst_0 = 1;

		i_clr_0 = 0;
		i_data_0 = 0;
		i_delay_0 = 0;
		i_diff_0 = 0;
		i_regu_en_0 = 0;
		i_set_point_0 = 0;

		#10 i_rst_0 = 0;
		#20 i_rst_0 = 1;

		#100
		i_set_point_0 = 32'h3f99999a;	// 1
		i_regu_en_0 = 1;
		i_diff_0 = 32'h3dcccccd;		// 0.1
		i_delay_0 = 2;

		#10
		i_data_0 = 32'h3f99999a;		// 1


		#200
		i_set_point_0 = 32'h00000000;	// 0

		#10
		i_data_0 = 32'h3e99999a;		// 0.3

		#20
		i_data_0 = 32'h3f4ccccd;

		#10
		i_data_0 = 32'h00000000;

		#150
		i_clr_0 = 1;

		#10
		i_clr_0 = 0;
	end

endmodule