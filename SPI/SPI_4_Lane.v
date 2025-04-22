`timescale 1ns / 1ps
/*

SPI AD4630 Module
개발 2팀 전경원 부장

25.03.28 :	최초 생성

BR MPS AD4630 용
CPOL CPHA : 00 (Data Read)
CPOL CPHA : 01 (Reg Config)

*/

module SPI_4_Lane
(
	input i_rst,
	input i_clk,

	input i_spi_start,
	output o_spi_done,
	input i_adc_init,

	output reg o_spi_clk,
	output o_cs,

	output o_mosi,
	input i_miso,
	output reg [5:0] o_miso_data,
	input [23:0] i_adc_init_data,
	
	output [2:0] o_state
);

	localparam IDLE 	= 0;
	localparam DELAY_1	= 1;
	localparam RUN 		= 2;
	localparam DELAY_2 	= 3;
	localparam DONE 	= 4;

	reg [2:0] state;
	reg [2:0] n_state;

	reg [2:0] spi_clk_width_cnt;

	reg [3:0] delay_1_cnt;
	reg [3:0] delay_2_cnt;
	reg [5:0] spi_data_cnt;

	reg [5:0] miso_buf;
	reg [23:0] mosi_buf;

	// flag
	wire spi_data_comp_flag;
	wire spi_data_flag;

	// FSM init.
	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			state <= IDLE;

		else 
			state <= n_state;
	end

	// FSM
	always @(*)
	begin
		case (state)
			IDLE 	: n_state = (i_spi_start) ? DELAY_1 : IDLE;
			DELAY_1 : n_state = (delay_1_cnt >= 3) ? RUN : DELAY_1;
			RUN 	: n_state = (spi_data_comp_flag) ? DELAY_2 : RUN;
			DELAY_2 : n_state = (delay_2_cnt >= 2) ? DONE : DELAY_2;
			DONE 	: n_state = (~i_spi_start) ? IDLE : DONE;
			default : n_state = IDLE;
		endcase
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			delay_1_cnt <= 0;

		else
			delay_1_cnt <= (state == DELAY_1) ? (delay_1_cnt + 1) : 0;
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			delay_2_cnt <= 0;

		else
			delay_2_cnt <= (state == DELAY_2) ? (delay_2_cnt + 1) : 0;
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			spi_clk_width_cnt <= 3'b111;

		else if (i_adc_init)
		begin
			if ((state == RUN) && (spi_data_cnt <= 48))
				spi_clk_width_cnt <= (spi_clk_width_cnt >= 2) ? 0 : (spi_clk_width_cnt + 1);

			else
				spi_clk_width_cnt <= 3'b111;
		end

		else
		begin
			if ((state == RUN) && (spi_data_cnt <= 12))
				spi_clk_width_cnt <= (spi_clk_width_cnt >= 1) ? 0 : (spi_clk_width_cnt + 1);

			else
				spi_clk_width_cnt <= 3'b111;
		end
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			spi_data_cnt <= 0;

		else if (state == RUN)
			spi_data_cnt <= (i_adc_init) ? 	((spi_clk_width_cnt == 2) ? (spi_data_cnt + 1) : spi_data_cnt) :
											((spi_clk_width_cnt == 1) ? (spi_data_cnt + 1) : spi_data_cnt);

		else
			spi_data_cnt <= 0;
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			o_spi_clk <= 0;

		else if (state == RUN)
		begin
			if (i_adc_init)
				o_spi_clk <= (spi_clk_width_cnt == 2) ? ((spi_data_cnt == 48) ? o_spi_clk : ~o_spi_clk) : o_spi_clk;

			else
				o_spi_clk <= (spi_clk_width_cnt == 1) ? ((spi_data_cnt == 12) ? o_spi_clk : ~o_spi_clk) : o_spi_clk;
		end
		
		else
			o_spi_clk <= 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			miso_buf <= 0;

		else if (spi_data_flag)
			miso_buf <= {miso_buf[4:0], i_miso};

		// else if (state == DONE)
		// 	miso_buf <= 0;

		else
			miso_buf <= miso_buf;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			mosi_buf <= 0;

		else if (spi_data_flag)
			mosi_buf <= (spi_data_cnt == 0) ? mosi_buf : {mosi_buf[22:0], 1'b0};

		else if (state == DELAY_1)
			mosi_buf <= i_adc_init_data;

		else
			mosi_buf <= mosi_buf;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_miso_data <= 0;

		else if (spi_data_comp_flag)
			o_miso_data <= miso_buf;

		else
			o_miso_data <= o_miso_data;
	end

	assign o_spi_done = (state == DONE);
	assign spi_data_flag = ((spi_clk_width_cnt == 0) && (o_spi_clk)) ? ((i_adc_init) ? spi_data_cnt <= (48) : spi_data_cnt <= (12)) : 0;
	// assign spi_data_flag = ((spi_clk_width_cnt == 0) && (o_spi_clk) && (spi_data_cnt <= (12) && (~i_adc_init)));
	// assign spi_data_n_flag = ((spi_clk_width_cnt == 0) && (o_spi_clk) && (spi_data_cnt <= (48) && (i_adc_init)));
	assign spi_data_comp_flag = (i_adc_init) ? (spi_data_cnt == 49) : (spi_data_cnt == 13);
	assign o_cs = ((state == IDLE) || (state == DONE));
	assign o_mosi = (i_adc_init) ? ((~o_cs) ? mosi_buf[23] : 1'bz) : 1'bz;
	assign o_state = state;

endmodule