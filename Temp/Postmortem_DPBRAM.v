`timescale 1ns / 1ps
/*

*/

module Postmortem_DPBRAM #
(
	parameter integer DWIDTH = 32,			// DPBRAM Data Width (Bit)
	parameter integer RAM_DEPTH = 50000		// DPBRAM Depth, 16 Bit
)
(
	input i_clk,

	input [$clog2(RAM_DEPTH) - 1 : 0] s_addr,
	input s_ce,
	input s_we,
	input [DWIDTH - 1 : 0] s_din,
	output reg [DWIDTH - 1 : 0] s_dout,

	input [$clog2(RAM_DEPTH) - 1 : 0] m_addr,
	input m_ce,
	input m_we,
	input [DWIDTH - 1 : 0] m_din,
	output reg [DWIDTH - 1 : 0] m_dout
);
 
	(* RAM_STYLE = "BLOCK"*) reg [DWIDTH - 1 : 0] ram[0 : RAM_DEPTH - 1];	// Sythesis에서 RAM을 Block으로 합성하도록 지시

	always @(posedge i_clk) 
	begin
		if(s_ce)
		begin
			if(s_we)
				ram[s_addr] <= s_din;

			else
				s_dout <= ram[s_addr];
		end
	end

	always @(posedge i_clk) 
	begin
		if(m_ce)
		begin
			if(m_we)
				ram[m_addr] <= m_din;

			else
				m_dout <= ram[m_addr];
		end
	end

endmodule