`timescale 1ns / 1ps

/*

25.07.01 :	최초 생성

 - 저장 데이터는 32 + 32 비트로 ADC 값 저장
 - Interlock 방생 전에는 1초 동안의 데이터를 Queue 방식으로 계속 저장 (o_addr_cnt)
 - Interlock 발생 후에는 0.5초 동안의 데이터를 저장하고 스톱 (intl_cnt)
 - Interlock 클리어 후 다시 동작

 - Test Bench는
	1. Test Bench로 Interlock 전 후 o_addr_cnt, intl_cnt 동작 확인
	2. Interlock 클리어 후 정상 동작 확인

 - Test는
	1. PS DDR4 데이터 저장 유무 (Vitis로 확인, 64비트로 32비트씩 읽어야 함)

*/

module Postmortem_Handler
(
	input i_clk,
	input i_rst,

	input [31:0] i_c,
	input [31:0] i_v,
	input [31:0] i_dc_c,
	input [31:0] i_dc_v,
	input [31:0] i_igbt_t,
	input [31:0] i_i_inductor_t,
	input [31:0] i_o_inductor_t,
	input [31:0] i_phase_rms_r,
	input [31:0] i_phase_rms_s,
	input [31:0] i_phase_rms_t,

	input i_intl_flag,
	output o_start,
	input i_done,

	output reg [39:0] o_ddr_addr,
	output reg [63:0] o_ddr_data,
	output reg [15:0] o_addr_cnt,

	output [2:0] o_state
);

	localparam IDLE = 0;
	localparam OUTP = 1;
	localparam DC_L = 2;
	localparam IDT  = 3;
	localparam RMS1 = 4;
	localparam RMS2 = 5;
	localparam DONE = 6;
	
	localparam PERIOD 	= 4000;		// 20us, 50KHz
	localparam ADDR 	= 50000;	// 50,000개, 1초, 0x3_0D40

	localparam OUTPUT 		= 40'h00_0040_0000;
	localparam DC_LINK 		= 40'h00_0050_0000;
	localparam INDUCTER		= 40'h00_0060_0000;
	localparam IGBT_RMS_R	= 40'h00_0070_0000;
	localparam RMS_S_T		= 40'h00_0080_0000;

	reg [2:0] state;
	reg [2:0] n_state;

	reg [11:0] period_cnt;
	reg [14:0] intl_cnt;

	wire ddr_start_flag;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			state <= IDLE;
			
		else
			state <= n_state;
	end

	always @(*)
	begin
		case (state)
			IDLE	: n_state = (ddr_start_flag) ? OUTP : IDLE;
			OUTP	: n_state = (i_done) ? DC_L : OUTP;
			DC_L	: n_state = (i_done) ? IDT : DC_L;
			IDT		: n_state = (i_done) ? RMS1 : IDT;
			RMS1	: n_state = (i_done) ? RMS2 : RMS1;
			RMS2	: n_state = (i_done) ? DONE : RMS2;
			DONE	: n_state = IDLE;
			default:
				n_state = IDLE;
		endcase
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			period_cnt <= 0;

		else
			period_cnt <= (period_cnt < PERIOD - 1) ? ((intl_cnt < 25000) ? period_cnt + 1 : 0) : 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_addr_cnt <= 0;

		else
			o_addr_cnt <= (state == DONE) ? ((o_addr_cnt == ADDR - 1) ? 0 : o_addr_cnt + 1) : o_addr_cnt;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			intl_cnt <= 0;

		else
			intl_cnt <= (i_intl_flag) ? (((state == DONE) && (intl_cnt < 25000)) ? intl_cnt + 1 : intl_cnt) : 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
		begin
			o_ddr_addr <= 0;
			o_ddr_data <= 0;
		end

		else if (state == OUTP)
		begin
			o_ddr_addr <= OUTPUT + (o_addr_cnt * 8);
			o_ddr_data <= {i_c, i_v};
		end

		else if (state == DC_L)
		begin
			o_ddr_addr <= DC_LINK + (o_addr_cnt * 8);
			o_ddr_data <= {i_dc_c, i_dc_v};
		end

		else if (state == IDT)
		begin
			o_ddr_addr <= INDUCTER + (o_addr_cnt * 8);
			o_ddr_data <= {i_i_inductor_t, i_o_inductor_t};
		end

		else if (state == RMS1)
		begin
			o_ddr_addr <= IGBT_RMS_R + (o_addr_cnt * 8);
			o_ddr_data <= {i_igbt_t, i_phase_rms_r};
		end

		else if (state == RMS2)
		begin
			o_ddr_addr <= RMS_S_T + (o_addr_cnt * 8);
			o_ddr_data <= {i_phase_rms_s, i_phase_rms_t};
		end
	end

	assign o_state = state;

	assign ddr_start_flag = (period_cnt == PERIOD - 1);
	assign o_start = ~((state == IDLE) || (state == DONE));

endmodule