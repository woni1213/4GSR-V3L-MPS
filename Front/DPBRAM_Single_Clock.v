`timescale 1ns / 1ps
/*

Dual Port BRAM
개발 4팀 전경원 차장

24.05.03 :	최초 생성
24.05.10 :	AWIDTH 삭제. clog2 RAM_DEPTH로 대체함

 - Dual Port 및 1 Clock으로 동작하는 Block RAM
 - 각 Port는 Write / Read 전용으로 사용하는 것을 권장함

*/

module DPBRAM_Single_Clock
(
	input i_clk,

	// BUS Interface. IP Package 시 Port들 Bus로 지정
	input [7:0] s_addr,
	input s_ce,
	input s_we,
	input [23:0] s_din,
	output reg [23:0] s_dout,

	input [7:0] m_addr,
	input m_ce,
	input m_we,
	input [23:0] m_din,
	output reg [23:0] m_dout
);
 
(* RAM_STYLE = "BLOCK"*) reg [23:0] ram[7:0];	// Sythesis에서 RAM을 Block으로 합성하도록 지시

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