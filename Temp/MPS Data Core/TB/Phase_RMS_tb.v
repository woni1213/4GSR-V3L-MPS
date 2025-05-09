`timescale 1 ns / 1 ps

module Phase_RMS_tb();

	reg i_clk;
	reg i_rst;

	reg [31:0] i_phase;

	Phase_RMS u_Phase_RMS
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_phase(i_phase),
		.o_rms(),
		.o_state()
	);

	always #5 i_clk = ~i_clk;

	initial
	begin
		i_clk = 1;
		i_rst = 1;
		i_phase = 0;

		#10 i_rst = 0;
		#10 i_rst = 1;

		#50
		i_phase = 32'h439b0000;		// 310

		#20
		i_phase = 32'h42c80000;		// 100

	end

endmodule