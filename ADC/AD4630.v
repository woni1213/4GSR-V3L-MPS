`timescale 1 ns / 1 ps

/*

BR MPS Main ADC Module
개발 2팀 전경원 부장

25.03.28 :	최초 생성

1. ADC
 - 24 Bit ADC
 - SDR Mode
 - 4-Lane
 - 2MSps
 - 9.944V (+V 0V)
 - 10.001V (+V -V)
 - -10.002V (-V +V)

2. SPI
 - Write : High, Low 5.2 ns
 - Read : 4.2 ns
 - CPOL CPHA : 00 (Data Read)
 - CPOL CPHA : 01 (Reg Config)

*/

module AD4630
(
	input i_clk,
	input i_rst,

	input i_adc_busy,
	output o_adc_cnv,

	output reg o_adc_spi_start,
	input i_adc_spi_done,
	output o_adc_data_valid,
	output o_adc_init,

	input [5:0] i_adc_data_0,
	input [5:0] i_adc_data_1,
	input [5:0] i_adc_data_2,
	input [5:0] i_adc_data_3,
	input [5:0] i_adc_data_4,
	input [5:0] i_adc_data_5,
	input [5:0] i_adc_data_6,
	input [5:0] i_adc_data_7,

	input [31:0] i_adc_cyc_t,
	output reg [23:0] o_adc_init_data,
	output reg [23:0] o_i_adc_data,
	output reg [23:0] o_v_adc_data,

	output [2:0] o_state
);

	localparam DELAY	= 0;
	localparam INIT		= 1;
	localparam IDLE		= 2;
	localparam CONV		= 3;
	localparam BUSY		= 4;
	localparam SPI		= 5;
	localparam SPI_WAIT	= 6;
	localparam DONE		= 7;

	localparam ADC_CONV_T	= 4;			// 20ns

	localparam INIT_SET 	= 24'hBF_FF00;		// Reg. Mode Config Mode IN
	localparam INIT_DATA 	= 24'h00_2080;		// 4-Lane Setting
	localparam INIT_CLR 	= 24'h00_1401;		// Reg. Mode Config Mode OUT

	reg [2:0] state;
	reg [2:0] n_state;

	// Counter
	reg [3:0] init_delay_cnt;
	reg [1:0] init_cnt;
	reg [31:0] cyc_cnt;
	reg [2:0] conv_cnt;

	// Flag
	wire conv_flag;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			state <= DELAY;

		else 
			state <= n_state;
	end

	always @(*)
	begin
		case (state)
			DELAY	: n_state = ((&init_delay_cnt) && (i_adc_cyc_t >= 100)) ? INIT : DELAY;
			INIT	: n_state = (i_adc_spi_done) ? ((init_cnt == 2) ? IDLE : DELAY) : INIT;
			IDLE 	: n_state = (conv_flag) ? CONV : IDLE;
			CONV	: n_state = (&conv_cnt) ? BUSY : CONV;
			BUSY	: n_state = (~i_adc_busy) ? SPI : BUSY;
			SPI		: n_state = SPI_WAIT;
			SPI_WAIT: n_state = (i_adc_spi_done) ? DONE : SPI_WAIT;
			DONE	: n_state = IDLE;
			default : n_state = DELAY;
		endcase
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			init_delay_cnt <= 0;

		else
			init_delay_cnt <= (state == DELAY) ? init_delay_cnt + 1 : 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			cyc_cnt <= 0;

		else
			cyc_cnt <= (i_adc_cyc_t >= 100) ? ((cyc_cnt == i_adc_cyc_t - 1) ? 0 : (cyc_cnt + 1)) : 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			conv_cnt <= 0;

		else
			conv_cnt <= (state == CONV) ? conv_cnt + 1 : 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			init_cnt <= 0;

		else
			init_cnt <= ((state == INIT) && (i_adc_spi_done))? init_cnt + 1 : init_cnt;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_adc_spi_start <= 0;

		else
			o_adc_spi_start <= (state == SPI);
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_adc_init_data <= 0;

		else if (init_cnt == 0)
			o_adc_init_data <= INIT_SET;

		else if (init_cnt == 1)
			o_adc_init_data <= INIT_DATA;

		else if (init_cnt == 2)
			o_adc_init_data <= INIT_CLR;

		else
			o_adc_init_data <= 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
		begin
			o_i_adc_data <= 0;
			o_v_adc_data <= 0;
		end

		else
		begin
			if (state == INIT)
			begin
				o_i_adc_data <= 0;
				o_v_adc_data <= 0;
			end

			else
			begin
				o_i_adc_data <= (i_adc_spi_done) ? 	{	i_adc_data_4[5], i_adc_data_5[5], i_adc_data_6[5], i_adc_data_7[5],
														i_adc_data_4[4], i_adc_data_5[4], i_adc_data_6[4], i_adc_data_7[4],
														i_adc_data_4[3], i_adc_data_5[3], i_adc_data_6[3], i_adc_data_7[3],
														i_adc_data_4[2], i_adc_data_5[2], i_adc_data_6[2], i_adc_data_7[2],
														i_adc_data_4[1], i_adc_data_5[1], i_adc_data_6[1], i_adc_data_7[1],
														i_adc_data_4[0], i_adc_data_5[0], i_adc_data_6[0], i_adc_data_7[0] }
														: o_i_adc_data;

				o_v_adc_data <= (i_adc_spi_done) ? 	{	i_adc_data_0[5], i_adc_data_1[5], i_adc_data_2[5], i_adc_data_3[5],
														i_adc_data_0[4], i_adc_data_1[4], i_adc_data_2[4], i_adc_data_3[4],
														i_adc_data_0[3], i_adc_data_1[3], i_adc_data_2[3], i_adc_data_3[3],
														i_adc_data_0[2], i_adc_data_1[2], i_adc_data_2[2], i_adc_data_3[2],
														i_adc_data_0[1], i_adc_data_1[1], i_adc_data_2[1], i_adc_data_3[1],
														i_adc_data_0[0], i_adc_data_1[0], i_adc_data_2[0], i_adc_data_3[0] }
														: o_v_adc_data;
			end
		end
	end

	assign o_state = state;
	assign conv_flag = (cyc_cnt == i_adc_cyc_t - 1);
	assign o_adc_cnv = (state == CONV);
	assign o_adc_data_valid = (state == DONE);
	assign o_adc_init = ((state == DELAY) || (state == INIT));
	
endmodule