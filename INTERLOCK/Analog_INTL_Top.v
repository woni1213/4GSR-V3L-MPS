`timescale 1 ns / 1 ps

/*

BR MPS Interlock Module
개발 2팀 전경원 부장

25.04.14 :	최초 생성

*/

module Analog_INTL_Top #
(
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_NUM = 20,
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2
)
(
	input i_clk,
	input i_rst,

	output [31:0] o_c_over_sp,
	output [31:0] o_v_over_sp,
	output [31:0] o_dc_c_over_sp,
	output [31:0] o_dc_v_over_sp,

	output [31:0] o_igbt_t_over_sp,
	output [31:0] o_i_id_t_over_sp,
	output [31:0] o_o_id_t_over_sp,

	output [31:0] o_c_data_thresh,
	output [31:0] o_c_cnt_thresh,
	output [31:0] o_c_period,
	output [31:0] o_c_cycle_cnt,

	output [31:0] o_c_diff,
	output [31:0] o_c_delay,

	output [31:0] o_v_data_thresh,
	output [31:0] o_v_cnt_thresh,
	output [31:0] o_v_period,
	output [31:0] o_v_cycle_cnt,

	output [31:0] o_v_diff,
	output [31:0] o_v_delay,

	output [31:0] o_phase_under_data,
	output [31:0] o_phase_over_data,

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

	AXI4_Lite_A_INTL #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_A_INTL
	(
		.o_c_over_sp(o_c_over_sp),
		.o_v_over_sp(o_v_over_sp),
		.o_dc_c_over_sp(o_dc_c_over_sp),
		.o_dc_v_over_sp(o_dc_v_over_sp),

		.o_igbt_t_over_sp(o_igbt_t_over_sp),
		.o_i_id_t_over_sp(o_i_id_t_over_sp),
		.o_o_id_t_over_sp(o_o_id_t_over_sp),

		.o_c_data_thresh(o_c_data_thresh),
		.o_c_cnt_thresh(o_c_cnt_thresh),
		.o_c_period(o_c_period),
		.o_c_cycle_cnt(o_c_cycle_cnt),
		.o_c_diff(o_c_diff),
		.o_c_delay(o_c_delay),

		.o_v_data_thresh(o_v_data_thresh),
		.o_v_cnt_thresh(o_v_cnt_thresh),
		.o_v_period(o_v_period),
		.o_v_cycle_cnt(o_v_cycle_cnt),
		.o_v_diff(o_v_diff),
		.o_v_delay(o_v_delay),

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

	assign o_phase_under_data = 32'h43460000;		// 198
	assign o_phase_over_data = 32'h43720000;		// 242

endmodule