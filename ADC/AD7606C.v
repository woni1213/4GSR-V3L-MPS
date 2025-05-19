`timescale 1 ns / 1 ps

/*

BR MPS Main ADC Module
개발 2팀 전경원 부장

25.04.02 :	최초 생성

1. ADC
 - 16 Bit ADC
 - SDR Mode
 - 8 Ch
 - 1MSps

2. SPI
 - Clock : < 40MHz
 - Write : High, Low 12.5 ns
 - Read : 12.5 ns
 - CPOL CPHA : 11 (Data Read)
 - CPOL CPHA : 10 (Reg Config)

*/

module AD7606C
(
	input i_clk,
	input i_rst,

	input i_adc_busy,
	output o_adc_cnv,
	output o_adc_rst,

	output reg o_adc_spi_start,
	input i_adc_spi_done,
	output reg o_init_spi_start,
	input i_init_spi_done,

	output o_cpol,
	output o_cpha,

	input [31:0] i_adc_cyc_t,
	output reg [15:0] o_adc_init_data,

	output [3:0] o_state
);

	localparam DELAY	= 0;
	localparam INIT		= 1;
	localparam INIT_WAIT= 2;
	localparam IDLE		= 3;
	localparam CONV		= 4;
	localparam BUSY_H	= 5;
	localparam BUSY		= 6;
	localparam SPI		= 7;
	localparam SPI_WAIT	= 8;
	localparam DONE		= 9;

	localparam INIT_SET		= 16'h6F00;
	localparam INIT_DATA_1	= 16'hFFFF;
	localparam INIT_DATA_2	= 16'h0218;
	localparam INIT_CLR		= 16'h0000;

	reg [3:0] state;
	reg [3:0] n_state;

	// Counter
	reg [5:0] delay_cnt;
	reg [2:0] conv_cnt;
	reg [2:0] init_cnt;
	reg [31:0] cyc_cnt;

	// Flag
	wire conv_flag;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			state <= DELAY;

		else 
			state <= n_state;
	end

	// always @(*)
	// begin
	// 	case (state)
	// 		DELAY		: n_state = (&delay_cnt) ? INIT : DELAY;
	// 		INIT		: n_state = INIT_WAIT;
	// 		INIT_WAIT	: n_state = (i_init_spi_done) ? ((init_cnt == 3) ? IDLE : DELAY) : INIT_WAIT;
	// 		IDLE		: n_state = (conv_flag) ? CONV : IDLE;
	// 		CONV		: n_state = (&conv_cnt) ? BUSY : CONV;
	// 		BUSY		: n_state = (~i_adc_busy) ? SPI : BUSY;
	// 		SPI			: n_state = SPI_WAIT;
	// 		SPI_WAIT	: n_state = (i_adc_spi_done) ? DONE : SPI_WAIT;
	// 		DONE		: n_state = IDLE;
	// 		default 	: n_state = DELAY;
	// 	endcase
	// end

	always @(*)
	begin
		case (state)
			DELAY		: n_state = (&delay_cnt) ? INIT : DELAY;
			INIT		: n_state = INIT_WAIT;
			INIT_WAIT	: n_state = (i_init_spi_done) ? ((init_cnt == 3) ? IDLE : DELAY) : INIT_WAIT;
			IDLE		: n_state = (conv_flag) ? CONV : IDLE;
			CONV		: n_state = (conv_cnt == 4) ? BUSY_H : CONV;
			BUSY_H		: n_state = (i_adc_busy) ? BUSY : BUSY_H;
			BUSY		: n_state = (~i_adc_busy) ? SPI : BUSY;
			SPI			: n_state = SPI_WAIT;
			SPI_WAIT	: n_state = (i_adc_spi_done) ? DONE : SPI_WAIT;
			DONE		: n_state = IDLE;
			default 	: n_state = DELAY;
		endcase
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			delay_cnt <= 0;

		else
			delay_cnt <= ((state == DELAY) && (i_adc_cyc_t >= 200)) ? delay_cnt + 1 : 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			cyc_cnt <= 0;

		else
			cyc_cnt <= (i_adc_cyc_t >= 200) ? ((cyc_cnt == i_adc_cyc_t - 1) ? 0 : (cyc_cnt + 1)) : 0;
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
			o_adc_spi_start <= 0;

		else
			o_adc_spi_start <= (state == SPI);
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_init_spi_start <= 0;

		else
			o_init_spi_start <= (state == INIT);
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			init_cnt <= 0;

		else
			init_cnt <= (i_init_spi_done) ? init_cnt + 1 : init_cnt;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_adc_init_data <= 0;

		else if (init_cnt == 0)
			o_adc_init_data <= INIT_SET;

		else if (init_cnt == 1)
			o_adc_init_data <= INIT_DATA_1;

		else if (init_cnt == 2)
			o_adc_init_data <= INIT_DATA_2;

		else if (init_cnt == 3)
			o_adc_init_data <= INIT_CLR;

		else
			o_adc_init_data <= 0;
	end

	assign o_state = state;
	assign conv_flag = (cyc_cnt == i_adc_cyc_t - 1);
	assign o_adc_cnv = ~(state == CONV);
	assign o_cpol = 1;
	assign o_cpha = (state > 3);
	assign o_adc_rst = 0;

endmodule