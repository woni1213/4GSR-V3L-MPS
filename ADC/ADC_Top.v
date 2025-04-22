`timescale 1 ns / 1 ps

/*

BR MPS Main ADC Module
개발 2팀 전경원 부장

25.03.28 :	최초 생성

1. 개요
 BR MPS ADC

*/

module ADC_Top #
(
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_NUM = 20,
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2
)
(
	input i_clk,
	input i_rst,

	input i_m_adc_busy,
	output o_m_adc_cnv,
	input i_s_adc_busy,
	output o_s_adc_cnv,
	output o_s_adc_rst,

	output o_m_adc_spi_start,
	input i_m_adc_spi_done,
	output o_m_adc_data_valid,
	output o_m_adc_init,

	output o_s_adc_spi_start,
	input i_s_adc_spi_done,
	output o_s_init_spi_start,
	input i_s_init_spi_done,
	output o_s_adc_data_valid,
	output o_cpol,
	output o_cpha,

	input [5:0] i_m_adc_data_0,
	input [5:0] i_m_adc_data_1,
	input [5:0] i_m_adc_data_2,
	input [5:0] i_m_adc_data_3,
	input [5:0] i_m_adc_data_4,
	input [5:0] i_m_adc_data_5,
	input [5:0] i_m_adc_data_6,
	input [5:0] i_m_adc_data_7,

	input [15:0] i_s_adc_data_0,
	input [15:0] i_s_adc_data_1,
	input [15:0] i_s_adc_data_2,
	input [15:0] i_s_adc_data_3,
	input [15:0] i_s_adc_data_4,
	input [15:0] i_s_adc_data_5,
	input [15:0] i_s_adc_data_6,
	input [15:0] i_s_adc_data_7,

	output [23:0] o_m_adc_init_data,
	output [15:0] o_s_adc_init_data,
	output [23:0] o_i_adc_data,
	output [23:0] o_v_adc_data,

	output [15:0] o_s_adc_data_0,
	output [15:0] o_s_adc_data_1,
	output [15:0] o_s_adc_data_2,
	output [15:0] o_s_adc_data_3,
	output [15:0] o_s_adc_data_4,
	output [15:0] o_s_adc_data_5,
	output [15:0] o_s_adc_data_6,
	output [15:0] o_s_adc_data_7,

	output [3:0] o_m_adc_state,
	output [3:0] o_s_adc_state,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
	input [2 : 0] s00_axi_awprot,
	input s00_axi_awvalid,
	output s00_axi_awready,
	input [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
	input [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input s00_axi_wvalid,
	output s00_axi_wready,
	output [1 : 0] s00_axi_bresp,
	output s00_axi_bvalid,
	input s00_axi_bready,
	input [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
	input [2 : 0] s00_axi_arprot,
	input s00_axi_arvalid,
	output s00_axi_arready,
	output [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
	output [1 : 0] s00_axi_rresp,
	output s00_axi_rvalid,
	input s00_axi_rready
);

	wire [31:0] m_adc_cyc_t;
	wire [31:0] s_adc_cyc_t;

	AD4630
	u_AD4630
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_adc_busy(i_m_adc_busy),
		.o_adc_cnv(o_m_adc_cnv),

		.o_adc_spi_start(o_m_adc_spi_start),
		.i_adc_spi_done(i_m_adc_spi_done),
		.o_adc_data_valid(o_m_adc_data_valid),
		.o_adc_init(o_m_adc_init),

		.i_adc_data_0(i_m_adc_data_0),
		.i_adc_data_1(i_m_adc_data_1),
		.i_adc_data_2(i_m_adc_data_2),
		.i_adc_data_3(i_m_adc_data_3),
		.i_adc_data_4(i_m_adc_data_4),
		.i_adc_data_5(i_m_adc_data_5),
		.i_adc_data_6(i_m_adc_data_6),
		.i_adc_data_7(i_m_adc_data_7),

		// .i_adc_cyc_t(100),
		.i_adc_cyc_t(m_adc_cyc_t),
		.o_adc_init_data(o_m_adc_init_data),
		.o_i_adc_data(o_i_adc_data),
		.o_v_adc_data(o_v_adc_data),

		.o_state(o_m_adc_state)
	);

	AD7606C
	u_AD7606C
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_adc_busy(i_s_adc_busy),
		.o_adc_cnv(o_s_adc_cnv),
		.o_adc_rst(o_s_adc_rst),

		.o_adc_spi_start(o_s_adc_spi_start),
		.i_adc_spi_done(i_s_adc_spi_done),
		.o_init_spi_start(o_s_init_spi_start),
		.i_init_spi_done(i_s_init_spi_done),
		
		.o_cpol(o_cpol),
		.o_cpha(o_cpha),

		.i_adc_cyc_t(s_adc_cyc_t),
		.o_adc_init_data(o_s_adc_init_data),

		.o_state(o_s_adc_state)
	);

	AXI4_Lite_ADC #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_ADC
	(
		.o_m_adc_cyc_t(m_adc_cyc_t),
		.o_s_adc_cyc_t(s_adc_cyc_t),

		.i_i_adc_raw_data(o_i_adc_data),
		.i_v_adc_raw_data(o_v_adc_data),

		.i_s_adc_data_0(i_s_adc_data_0),
		.i_s_adc_data_1(i_s_adc_data_1),
		.i_s_adc_data_2(i_s_adc_data_2),
		.i_s_adc_data_3(i_s_adc_data_3),
		.i_s_adc_data_4(i_s_adc_data_4),
		.i_s_adc_data_5(i_s_adc_data_5),
		.i_s_adc_data_6(i_s_adc_data_6),
		.i_s_adc_data_7(i_s_adc_data_7),
		
		.S_AXI_ACLK(i_clk),
		.S_AXI_ARESETN(i_rst),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	assign o_s_adc_data_valid = i_s_adc_spi_done;

	assign o_s_adc_data_0 = i_s_adc_data_0;
	assign o_s_adc_data_1 = i_s_adc_data_1;
	assign o_s_adc_data_2 = i_s_adc_data_2;
	assign o_s_adc_data_3 = i_s_adc_data_3;
	assign o_s_adc_data_4 = i_s_adc_data_4;
	assign o_s_adc_data_5 = i_s_adc_data_5;
	assign o_s_adc_data_6 = i_s_adc_data_6;
	assign o_s_adc_data_7 = i_s_adc_data_7;

endmodule