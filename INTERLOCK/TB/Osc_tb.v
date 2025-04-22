`timescale 1 ns / 1 ps

module Osc_tb();

	reg i_clk_0;
	reg i_clr_0;
	reg [31:0]i_cnt_thresh_0;
	reg [31:0]i_cycle_cnt_0;
	reg [31:0]i_data_0;
	reg [31:0]i_data_thresh_0;
	reg i_osc_en_0;
	reg [31:0]i_period_0;
	reg i_rst_0;

	Osc_wrapper u_Osc_wrapper
	(
		.i_clk_0(i_clk_0),
        .i_clr_0(i_clr_0),
        .i_cnt_thresh_0(i_cnt_thresh_0),
        .i_cycle_cnt_0(i_cycle_cnt_0),
        .i_data_0(i_data_0),
        .i_data_thresh_0(i_data_thresh_0),
        .i_osc_en_0(i_osc_en_0),
        .i_period_0(i_period_0),
        .i_rst_0(i_rst_0)
	);

	always #5 i_clk_0 = ~i_clk_0;

	initial
	begin
		i_clk_0 = 1;
		i_clr_0 = 0;
		i_cnt_thresh_0 = 0;
		i_cycle_cnt_0 = 0;
		i_data_0 = 0;
		i_data_thresh_0 = 0;
		i_osc_en_0 = 0;
		i_period_0 = 0;
		i_rst_0 = 0;

		#10 i_rst_0 = 1;

		#10;
		i_data_thresh_0 = 32'h3f000000;		// 0.5
		i_cnt_thresh_0 = 3;
		i_period_0 = 20;
		i_cycle_cnt_0 = 5;

		#10;
		i_osc_en_0 = 1;					// 인터락 안 걸림
		i_data_0 = 32'h3f000000;		// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8

        #400 i_data_0 = 32'h3f000000;	// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8

		#400 i_data_0 = 32'h3f000000;	// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8

		#400 i_data_0 = 32'h3f000000;	// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8

		#400 i_data_0 = 32'h3f000000;	// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8


		// 인터락 걸림
		#600 i_data_0 = 32'h40000000;	// 2.0

        #400 i_data_0 = 32'h3f4ccccd;	// 0.8

		#10 i_data_0 = 32'h40000000;	// 2.0

		#400 i_data_0 = 32'h3f4ccccd;	// 0.8

		#10 i_data_0 = 32'h40000000;	// 2.0

		#400 i_data_0 = 32'h3f4ccccd;	// 0.8

		#10 i_data_0 = 32'h40000000;	// 2.0

		#400 i_data_0 = 32'h3f4ccccd;	// 0.8

		#10 i_data_0 = 32'h40000000;	// 2.0

		#1000 i_osc_en_0 = 0;

		// 인터락 안 풀림
		#200 i_clr_0 = 1;

		#10  i_clr_0 = 0;

		// 인터락 풀림
		#1000;
		i_osc_en_0 = 1;
		i_data_0 = 32'h3f000000;		// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8

        #400 i_data_0 = 32'h3f000000;	// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8

		#400 i_data_0 = 32'h3f000000;	// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8

		#400 i_data_0 = 32'h3f000000;	// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8

		#400 i_data_0 = 32'h3f000000;	// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8

		#200 i_clr_0 = 1;

		#10  i_clr_0 = 0;

		// clr 고정
		#1000 i_clr_0 = 1;

		// intl
		#400 i_data_0 = 32'h3f4ccccd;	// 0.8

		#10 i_data_0 = 32'h40000000;	// 2.0

        #400 i_data_0 = 32'h3f4ccccd;	// 0.8

		#10 i_data_0 = 32'h40000000;	// 2.0

		#400 i_data_0 = 32'h3f4ccccd;	// 0.8

		#10 i_data_0 = 32'h40000000;	// 2.0

		#400 i_data_0 = 32'h3f4ccccd;	// 0.8

		#10 i_data_0 = 32'h40000000;	// 2.0

		#400 i_data_0 = 32'h3f4ccccd;	// 0.8

		#10 i_data_0 = 32'h40000000;	// 2.0

		// intl clr
		#400 i_data_0 = 32'h3f000000;	// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8

        #400 i_data_0 = 32'h3f000000;	// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8

		#400 i_data_0 = 32'h3f000000;	// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8

		#400 i_data_0 = 32'h3f000000;	// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8

		#400 i_data_0 = 32'h3f000000;	// 0.5

		#10 i_data_0 = 32'h3f4ccccd;	// 0.8
	end

endmodule