`timescale 1 ns / 1 ps

/*

BR MPS SFP Module
개발 2팀 전경원 부장

25.05.26 :	최초 생성

*/
module SFP_Top #
(
	parameter integer C_S_AXI_DATA_WIDTH = 32,								// AXI4-Lite Data Width
	parameter integer C_S_AXI_ADDR_NUM = 21,								// AXI4-Lite Slave Reg Number
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2		// AXI4-Lite Address
)
(
	input i_clk,
	input i_rst,

	input [31:0] i_status,
	input [31:0] i_intl,
	input [31:0] i_c,
	input [31:0] i_v,
	input [31:0] i_dc_c,
	input [31:0] i_dc_v,
	input [31:0] i_phase_r,
	input [31:0] i_phase_s,
	input [31:0] i_phase_t,

	input [31:0] i_peer_wr_data_cnt,
	input [31:0] i_local_wr_data_cnt,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [63:0] 	sfp_m_axis_tdata,
	input			sfp_m_axis_tready,
	output 			sfp_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [63:0] 	sfp_s_axis_tdata,
	output			sfp_s_axis_tready,
	input 			sfp_s_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [63:0] 	peer_m_axis_tdata,
	input			peer_m_axis_tready,
	output 			peer_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [63:0] 	peer_s_axis_tdata,
	output			peer_s_axis_tready,
	input 			peer_s_axis_tvalid,

		(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [63:0] 	local_m_axis_tdata,
	input			local_m_axis_tready,
	output 			local_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [63:0] 	local_s_axis_tdata,
	output			local_s_axis_tready,
	input 			local_s_axis_tvalid,

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

	wire sfp_en;
	wire [1:0] sfp_id;

	wire [31:0] m_sfp_cmd;
	wire [31:0] m_sfp_data;
	wire m_sfp_flag;

	wire [63:0] m_sfp_rsp;
	wire [31:0] s_sfp_cmd;
	wire [31:0] s_sfp_data;
	wire s_sfp_flag;
	wire s_sfp_done;

	wire [63:0] s_sfp_rsp;
	wire s_sfp_rsp_flag;

	wire [31:0] s0_status;
	wire [31:0] s0_intl;
	wire [31:0] s0_c;
	wire [31:0] s0_v;
	wire [31:0] s0_dc_c;
	wire [31:0] s0_dc_v;
	wire [31:0] s0_phase_r;
	wire [31:0] s0_phase_s;
	wire [31:0] s0_phase_t;

	AXI4_Lite_SFP #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_SFP
	(
		.o_sfp_en(sfp_en),
		.o_sfp_id(sfp_id),

		// Master
		.o_m_sfp_cmd(m_sfp_cmd),
		.o_m_sfp_data(m_sfp_data),
		.o_m_sfp_flag(m_sfp_flag),

		.i_m_sfp_rsp(m_sfp_rsp),

		.i_s0_status(s0_status),			// FSM, MPS Setting
		.i_s0_intl(s0_intl),
		.i_s0_c(s0_c),
		.i_s0_v(s0_v),
		.i_s0_dc_c(s0_dc_c),
		.i_s0_dc_v(s0_dc_v),
		.i_s0_phase_r(s0_phase_r),
		.i_s0_phase_s(s0_phase_s),
		.i_s0_phase_t(s0_phase_t),

		// Slave
		.i_s_sfp_cmd(s_sfp_cmd),
		.i_s_sfp_data(s_sfp_data),

		.o_s_sfp_rsp(s_sfp_rsp),
		.o_s_sfp_rsp_flag(s_sfp_rsp_flag),

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

	SFP_Handler
	u_SFP_Handler
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_sfp_en(sfp_en),
		.i_sfp_id(sfp_id),

		.o_tx_sfp_tdata(sfp_m_axis_tdata),
		.i_tx_sfp_tready(sfp_m_axis_tready),
		.o_tx_sfp_tvalid(sfp_m_axis_tvalid),

		.i_rx_sfp_tdata(sfp_s_axis_tdata),
		.o_rx_sfp_tready(sfp_s_axis_tready),
		.i_rx_sfp_tvalid(sfp_s_axis_tvalid),

		// Master
		.i_m_sfp_cmd(m_sfp_cmd),
		.i_m_sfp_data(m_sfp_data),
		.i_m_sfp_flag(m_sfp_flag),

		.o_m_sfp_rsp(m_sfp_rsp),

		.o_s0_status(s0_status),
		.o_s0_intl(s0_intl),
		.o_s0_c(s0_c),
		.o_s0_v(s0_v),
		.o_s0_dc_c(s0_dc_c),
		.o_s0_dc_v(s0_dc_v),
		.o_s0_phase_r(s0_phase_r),
		.o_s0_phase_s(s0_phase_s),
		.o_s0_phase_t(s0_phase_t),

		// Slave
		.o_s_sfp_cmd(s_sfp_cmd),
		.o_s_sfp_data(s_sfp_data),

		.i_s_sfp_rsp(s_sfp_rsp),
		.i_s_sfp_flag(s_sfp_rsp_flag),

		.m_peer_tdata(peer_m_axis_tdata),
		.m_peer_tready(peer_m_axis_tready),
		.m_peer_tvalid(peer_m_axis_tvalid),

		.m_local_tdata(local_m_axis_tdata),
		.m_local_tready(local_m_axis_tready),
		.m_local_tvalid(local_m_axis_tvalid),

		.s_peer_tdata(peer_s_axis_tdata),
		.s_peer_tready(peer_s_axis_tready),
		.s_peer_tvalid(peer_s_axis_tvalid),

		.s_local_tdata(local_s_axis_tdata),
		.s_local_tready(local_s_axis_tready),
		.s_local_tvalid(local_s_axis_tvalid),

		.i_peer_wr_data_cnt(i_peer_wr_data_cnt),
		.i_local_wr_data_cnt(i_local_wr_data_cnt),

		.i_status(i_status),
		.i_intl(i_intl),
		.i_c(i_c),
		.i_v(i_v),
		.i_dc_c(i_dc_c),
		.i_dc_v(i_dc_v),
		.i_phase_r(i_phase_r),
		.i_phase_s(i_phase_s),
		.i_phase_t(i_phase_t),

		.o_m_tx_state(),
		.o_s_peer_tx_state(),
		.o_s_local_tx_state(),
		.o_s_tx_state()
	);

endmodule