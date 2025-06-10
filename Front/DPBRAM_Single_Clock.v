`timescale 1ns / 1ps
/*

Dual Port BRAM
개발 4팀 전경원 차장

24.05.03 :	최초 생성
24.05.10 :	AWIDTH 삭제. clog2 RAM_DEPTH로 대체함

 - Dual Port 및 1 Clock으로 동작하는 Block RAM
 - 각 Port는 Write / Read 전용으로 사용하는 것을 권장함

*/

module DPBRAM_Single_Clock #
(
	parameter integer DWIDTH = 16,			// DPBRAM Data Width (Bit)
	parameter integer RAM_DEPTH = 1000		// DPBRAM Depth
)
(
	input i_clk,

	// BUS Interface. IP Package 시 Port들 Bus로 지정
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 S_DPBRAM_PORT addr0" *) input [$clog2(RAM_DEPTH) - 1 : 0] s_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 S_DPBRAM_PORT ce0" *) input s_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 S_DPBRAM_PORT we0" *) input s_we,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 S_DPBRAM_PORT din0" *) input [DWIDTH - 1 : 0] s_din,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 S_DPBRAM_PORT dout0" *) output reg [DWIDTH - 1 : 0] s_dout,

	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 M_DPBRAM_PORT addr1" *) input [$clog2(RAM_DEPTH) - 1 : 0] m_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 M_DPBRAM_PORT ce1" *) input m_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 M_DPBRAM_PORT we1" *) input m_we,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 M_DPBRAM_PORT din1" *) input [DWIDTH - 1 : 0] m_din,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 M_DPBRAM_PORT dout1" *) output reg [DWIDTH - 1 : 0] m_dout
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