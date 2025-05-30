`timescale 1 ns / 1 ps

/*

MPS Front Panel Module
개발 4팀 전경원 차장

24.07.26 :	최초 생성

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - 

1. 개요
 - 

*/

module Front_Top #
(
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_WIDTH = 6,
	parameter integer DWIDTH = 24,
	parameter integer RAM_DEPTH = 256
)
(
	// to SPI Module
	input i_spi_cs,				// SPI Module (n_cs)
	output o_spi_start,			// SPI Module (i_spi_start)
	output [23:0] o_mosi_data,	// SPI Module (i_mosi_data)
	input [23:0] i_miso_data,	// SPI Module (o_miso_data)

	// to Ext.Port
	input i_sw_intr,			// Interrupt
	input i_ro_enc_state_a,		// Rotary Encoder A
	input i_ro_enc_state_b,

	output o_lcd_cs,			// LCD SPI CS Output
	output o_sw_cs,				// Switch SPI CS Output

	// AXI4 Lite Bus Interface Ports
    input wire  s00_axi_aclk,
    input wire  s00_axi_aresetn,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire  s00_axi_awvalid,
    output wire  s00_axi_awready,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire  s00_axi_wvalid,
    output wire  s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire  s00_axi_bvalid,
    input wire  s00_axi_bready,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire  s00_axi_arvalid,
    output wire  s00_axi_arready,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire  s00_axi_rvalid,
    input wire  s00_axi_rready
);

	wire [7:0] lcd_data_m_addr;
	wire [23:0] lcd_data_m_dout;
	wire [7:0] lcd_data_s_addr;
	wire [23:0] lcd_data_s_din;

	wire lcd_sw_start;
	wire sw_intr_clear;
	wire [7:0] sw_data;

	// RO_ENC.v
	// wire [1:0] ro_enc_data;

	// RO_ENC_test.v
	wire [4:0] ro_enc_data;
	wire ro_enc_irq;
	wire ro_enc_dir;

	wire lcd_sw_cs;

	AXI4_Lite_Front #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_Front
	(
		.o_lcd_sw_start(lcd_sw_start),
		.o_sw_intr_clear(sw_intr_clear),

		// RO_ENC_test.v
		.i_ro_enc_irq(ro_enc_irq),
		.i_ro_enc_dir(ro_enc_dir),
		.i_sw_data(sw_data),

		// RO_ENC.v
		// .i_ro_enc_data(ro_enc_data),

		.o_dpbram_axi_data(lcd_data_m_dout),
		.o_dpbram_axi_addr(lcd_data_m_addr),
		.o_dpbram_axi_ce(),
		.o_dpbram_axi_we(),

		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
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

	LCD_SW
	u_LCD_SW
	(
		.i_clk(s00_axi_aclk),
		.i_rst(s00_axi_aresetn),

		.i_lcd_sw_start(lcd_sw_start),
		.i_sw_intr(i_sw_intr),
		.i_sw_intr_clear(sw_intr_clear),
		.o_sw_data(sw_data),

		.i_dpbram_data(lcd_data_s_din),
		.o_dpbram_addr(lcd_data_s_addr),

		.o_spi_start(o_spi_start),
		.o_mosi_data(o_mosi_data),
		.i_miso_data(i_miso_data),

		.o_lcd_sw_cs(lcd_sw_cs)
	);

	RO_ENC
	u_RO_ENC
	(
		.i_clk(s00_axi_aclk),
		.i_rst(s00_axi_aresetn),

		.i_ro_enc_state_a(i_ro_enc_state_a),
		.i_ro_enc_state_b(i_ro_enc_state_b),

		.i_sw_intr_clear(sw_intr_clear),
		.o_ro_enc_data(ro_enc_data),

		//RO_ENC_test.v
		.o_ro_enc_irq(ro_enc_irq),
		.o_ro_enc_dir(ro_enc_dir)
	);

	DPBRAM_Single_Clock #
	(
		.DWIDTH(DWIDTH),
		.RAM_DEPTH(RAM_DEPTH)
	)
	u_DPBRAM_Single_Clock
	(
		.i_clk(s00_axi_aclk),
		
		.s_addr(lcd_data_s_addr),
		.s_ce(1),
		.s_we(0),
		.s_din(0),
		.s_dout(lcd_data_s_din),

		.m_addr(lcd_data_m_addr),
		.m_ce(1),
		.m_we(1),
		.m_din(lcd_data_m_dout),
		.m_dout()
	);

	assign o_lcd_cs = ~(lcd_sw_cs) ? i_spi_cs : 1;
	assign o_sw_cs = (lcd_sw_cs) ? i_spi_cs : 1;

endmodule