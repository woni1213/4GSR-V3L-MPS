`timescale 1 ns / 1 ps

module Limit_tb();

	reg i_clk_0;
	reg i_clr_0;
	reg [31:0]i_data_0;
	reg i_over_en_0;
	reg [31:0] i_over_sp_0;
	reg i_rst_0;
	reg i_under_en_0;
	reg [31:0] i_under_sp_0;

	Limit_wrapper u_Limit_wrapper
	(
		.i_clk_0(i_clk_0),
		.i_clr_0(i_clr_0),
		.i_data_0(i_data_0),
		.i_over_en_0(i_over_en_0),
		.i_over_sp_0(i_over_sp_0),
		.i_rst_0(i_rst_0),
		.i_under_en_0(i_under_en_0),
		.i_under_sp_0(i_under_sp_0)
	);

	always #5 i_clk_0 = ~i_clk_0;

	initial
	begin
		i_clk_0 = 1;
		i_clr_0 = 0;
		i_data_0 = 0;
		i_over_en_0 = 0;
		i_over_sp_0 = 0;
		
		i_rst_0 = 1;
		i_under_en_0 = 0;
		i_under_sp_0 = 0;

		#10 i_rst_0 = 0;
		#10 i_rst_0 = 1;

		#10;
		i_over_sp_0 = 32'h3f000000;		// 0.5
		i_under_sp_0 = 32'h3e99999a;

		#10;
		i_over_en_0 = 1;

		#20
		i_data_0 = 32'h3f4ccccd;

		#10
		i_data_0 = 32'h00000000;

		#50
		i_clr_0 = 1;

		#10
		i_clr_0 = 0;

		#10
		i_over_en_0 = 0;

		#10
		i_data_0 = 32'h3f99999a;

		#10
		i_under_en_0 = 1;

		#10
		i_data_0 = 32'h00000000;

		#10
		i_data_0 = 32'h3f99999a;

		#50
		i_clr_0 = 1;

		#10
		i_clr_0 = 0;
	end

endmodule