`timescale 1ns / 1ps

/*

25.07.01 :	최초 생성

*/

module Osc_Handler
(
	input i_clk,
	input i_rst,

	input [31:0] i_c,
	input [31:0] i_v,
	input [31:0] i_dc_c,
	input [31:0] i_dc_v,

	output o_start,
	input i_done,

	output reg [39:0] o_ddr_addr,
	output reg [63:0] o_ddr_data,
	output reg [17:0] o_addr_cnt,

	input [1:0] i_osc_trg_ch,
	output reg [31:0] o_adc_buf,

	output [1:0] o_state
);

	localparam IDLE = 0;
	localparam OUTP = 1;
	localparam DC_L = 2;
	localparam DONE = 3;
	
	localparam PERIOD 	= 2000;		// 10us, 100KHz
	localparam ADDR 	= 200000;	// 200,000개 (100,000개씩 2세트)

	localparam OUTPUT = 40'h00_0090_0000;
	localparam DC_LINK = 40'h00_00A0_0000;

	reg [1:0] state;
	reg [1:0] n_state;

	reg [10:0] osc_period;

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
			DC_L	: n_state = (i_done) ? DONE : DC_L;
			DONE	: n_state = IDLE;
			default:
				n_state = IDLE;
		endcase
	end
	
	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			osc_period <= 0;

		else
			osc_period <= (osc_period > PERIOD - 1) ? 0 : osc_period + 1;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_addr_cnt <= 0;

		else
			o_addr_cnt <= (o_addr_cnt > ADDR - 1) ? 0 : (state == DONE) ? o_addr_cnt + 1 : 0;
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
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_adc_buf <= 0;

		else if ((i_osc_trg_ch == 0) && (state == OUTP))
			o_adc_buf <= i_c;

		else if ((i_osc_trg_ch == 1) && (state == OUTP))
			o_adc_buf <= i_v;

		else if ((i_osc_trg_ch == 2) && (state == DC_L))
			o_adc_buf <= i_dc_c;


		else if ((i_osc_trg_ch == 3) && (state == DC_L))
			o_adc_buf <= i_dc_v;

		else
			o_adc_buf <= o_adc_buf;
	end

	assign o_state = state;

	assign ddr_start_flag = (osc_period == PERIOD - 1);
	assign o_start = ~((state == IDLE) || (state == DONE));

endmodule