`timescale 1 ns / 1 ps

/*

BR MPS Calculation Parameter Module
媛쒕컻 2?? ?쟾寃쎌썝 遺??옣

25.03.31 :	理쒖큹 ?깮?꽦

1. 媛쒖슂
 ?뿰?궛?떇?뿉 ?븘?슂?븳 ?긽?닔
 1 Step : 0.00000059604644775390625 V (0.59604 uV)

 Offset : -10 (0xc1200000)
 Gain : 0.0000011920928955078125 (0x35a00000)

*/

module ADC_Calc_Val #
(
	parameter integer C_S_AXI_DATA_WIDTH = 32,								// AXI4-Lite Data Width
	parameter integer C_S_AXI_ADDR_NUM = 20,								// AXI4-Lite Slave Reg Number
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2		// AXI4-Lite Address
)
(
	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] i_gain_m_axis_tdata,
	output i_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] i_offset_m_axis_tdata,
	output i_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] v_gain_m_axis_tdata,
	output v_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] v_offset_m_axis_tdata,
	output v_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_dc_v_gain_m_axis_tdata,
	output o_dc_v_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_dc_v_offset_m_axis_tdata,
	output o_dc_v_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_p_r_gain_m_axis_tdata,
	output o_p_r_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_p_r_offset_m_axis_tdata,
	output o_p_r_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_p_s_gain_m_axis_tdata,
	output o_p_s_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_p_s_offset_m_axis_tdata,
	output o_p_s_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_p_t_gain_m_axis_tdata,
	output o_p_t_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_p_t_offset_m_axis_tdata,
	output o_p_t_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_dc_c_gain_m_axis_tdata,
	output o_dc_c_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_dc_c_offset_m_axis_tdata,
	output o_dc_c_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_igbt_t_gain_m_axis_tdata,
	output o_igbt_t_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_igbt_t_offset_m_axis_tdata,
	output o_igbt_t_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_i_id_t_gain_m_axis_tdata,
	output o_i_id_t_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_i_id_t_offset_m_axis_tdata,
	output o_i_id_t_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_o_id_t_gain_m_axis_tdata,
	output o_o_id_t_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_o_id_t_offset_m_axis_tdata,
	output o_o_id_t_offset_m_axis_tvalid,

	// Factor AXIS
	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_c_factor_axis_tdata,
	output o_c_factor_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_v_factor_axis_tdata,
	output o_v_factor_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_dc_c_factor_axis_tdata,
	output o_dc_c_factor_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_dc_v_factor_axis_tdata,
	output o_dc_v_factor_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_p_r_factor_axis_tdata,
	output o_p_r_factor_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_p_s_factor_axis_tdata,
	output o_p_s_factor_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_p_t_factor_axis_tdata,
	output o_p_t_factor_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_igbt_t_factor_axis_tdata,
	output o_igbt_t_factor_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_i_id_t_factor_axis_tdata,
	output o_i_id_t_factor_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_o_id_t_factor_axis_tdata,
	output o_o_id_t_factor_axis_tvalid,

	// Factor Offset AXIS
	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_c_factor_offset_axis_tdata,
	output o_c_factor_offset_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_v_factor_offset_axis_tdata,
	output o_v_factor_offset_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_dc_c_factor_offset_axis_tdata,
	output o_dc_c_factor_offset_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_dc_v_factor_offset_axis_tdata,
	output o_dc_v_factor_offset_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_p_r_factor_offset_axis_tdata,
	output o_p_r_factor_offset_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_p_s_factor_offset_axis_tdata,
	output o_p_s_factor_offset_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_p_t_factor_offset_axis_tdata,
	output o_p_t_factor_offset_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_igbt_t_factor_offset_axis_tdata,
	output o_igbt_t_factor_offset_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_i_id_t_factor_offset_axis_tdata,
	output o_i_id_t_factor_offset_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_o_id_t_factor_offset_axis_tdata,
	output o_o_id_t_factor_offset_axis_tvalid,

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

	AXI4_Lite_Calc_Val #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_Calc_Val
	(
		// ADC Calc Factor
		.o_c_factor(o_c_factor_axis_tdata),
		.o_v_factor(o_v_factor_axis_tdata),
		.o_dc_c_factor(o_dc_c_factor_axis_tdata),
		.o_dc_v_factor(o_dc_v_factor_axis_tdata),
		.o_phase_r_factor(o_p_r_factor_axis_tdata),
		.o_phase_s_factor(o_p_s_factor_axis_tdata),
		.o_phase_t_factor(o_p_t_factor_axis_tdata),
		.o_igbt_t_factor(o_igbt_t_factor_axis_tdata),
		.o_i_inductor_t_factor(o_i_id_t_factor_axis_tdata),
		.o_o_inductor_t_factor(o_o_id_t_factor_axis_tdata),

		.o_c_factor_offset(o_c_factor_offset_axis_tdata),
		.o_v_factor_offset(o_v_factor_offset_axis_tdata),
		.o_dc_c_factor_offset(o_dc_c_factor_offset_axis_tdata),
		.o_dc_v_factor_offset(o_dc_v_factor_offset_axis_tdata),
		.o_phase_r_factor_offset(o_p_r_factor_offset_axis_tdata),
		.o_phase_s_factor_offset(o_p_s_factor_offset_axis_tdata),
		.o_phase_t_factor_offset(o_p_t_factor_offset_axis_tdata),
		.o_igbt_t_factor_offset(o_igbt_t_factor_offset_axis_tdata),
		.o_i_inductor_t_factor_offset(o_i_id_t_factor_offset_axis_tdata),
		.o_o_inductor_t_factor_offset(o_o_id_t_factor_offset_axis_tdata),

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

	assign i_gain_m_axis_tdata = 32'h35a0_0000;
	assign i_offset_m_axis_tdata = 32'hc120_0000;
	assign v_gain_m_axis_tdata = 32'h35a0_0000;
	assign v_offset_m_axis_tdata = 32'hc120_0000;
	assign o_dc_v_gain_m_axis_tdata = 32'h39a000a0;
	assign o_dc_v_offset_m_axis_tdata = 32'hc120_0000;
	assign o_p_r_gain_m_axis_tdata = 32'h39a000a0;
	assign o_p_r_offset_m_axis_tdata = 32'hc120_0000;
	assign o_p_s_gain_m_axis_tdata = 32'h39a000a0;
	assign o_p_s_offset_m_axis_tdata = 32'hc120_0000;
	assign o_p_t_gain_m_axis_tdata = 32'h39a000a0;
	assign o_p_t_offset_m_axis_tdata = 32'hc120_0000;
	assign o_dc_c_gain_m_axis_tdata = 32'h39a000a0;
	assign o_dc_c_offset_m_axis_tdata = 32'hc120_0000;
	assign o_igbt_t_gain_m_axis_tdata = 32'h39a000a0;
	assign o_igbt_t_offset_m_axis_tdata = 32'hc120_0000;
	assign o_i_id_t_gain_m_axis_tdata = 32'h39a000a0;
	assign o_i_id_t_offset_m_axis_tdata = 32'hc120_0000;
	assign o_o_id_t_gain_m_axis_tdata = 32'h39a000a0;
	assign o_o_id_t_offset_m_axis_tdata = 32'hc120_0000;

	assign i_gain_m_axis_tvalid = 1;
	assign i_offset_m_axis_tvalid = 1;
	assign v_gain_m_axis_tvalid = 1;
	assign v_offset_m_axis_tvalid = 1;
	assign o_dc_v_gain_m_axis_tvalid = 1;
	assign o_dc_v_offset_m_axis_tvalid = 1;
	assign o_p_r_gain_m_axis_tvalid = 1;
	assign o_p_r_offset_m_axis_tvalid = 1;
	assign o_p_s_gain_m_axis_tvalid = 1;
	assign o_p_s_offset_m_axis_tvalid = 1;
	assign o_p_t_gain_m_axis_tvalid = 1;
	assign o_p_t_offset_m_axis_tvalid = 1;
	assign o_dc_c_gain_m_axis_tvalid = 1;
	assign o_dc_c_offset_m_axis_tvalid = 1;
	assign o_igbt_t_gain_m_axis_tvalid = 1;
	assign o_igbt_t_offset_m_axis_tvalid = 1;
	assign o_i_id_t_gain_m_axis_tvalid = 1;
	assign o_i_id_t_offset_m_axis_tvalid = 1;
	assign o_o_id_t_gain_m_axis_tvalid = 1;
	assign o_o_id_t_offset_m_axis_tvalid = 1;

	assign o_c_factor_axis_tvalid = 1;
	assign o_v_factor_axis_tvalid = 1;
	assign o_dc_c_factor_axis_tvalid = 1;
	assign o_dc_v_factor_axis_tvalid = 1;
	assign o_p_r_factor_axis_tvalid = 1;
	assign o_p_s_factor_axis_tvalid = 1;
	assign o_p_t_factor_axis_tvalid = 1;
	assign o_igbt_t_factor_axis_tvalid = 1;
	assign o_i_id_t_factor_axis_tvalid = 1;
	assign o_o_id_t_factor_axis_tvalid = 1;

	assign o_c_factor_offset_axis_tvalid = 1;
	assign o_v_factor_offset_axis_tvalid = 1;
	assign o_dc_c_factor_offset_axis_tvalid = 1;
	assign o_dc_v_factor_offset_axis_tvalid = 1;
	assign o_p_r_factor_offset_axis_tvalid = 1;
	assign o_p_s_factor_offset_axis_tvalid = 1;
	assign o_p_t_factor_offset_axis_tvalid = 1;
	assign o_igbt_t_factor_offset_axis_tvalid = 1;
	assign o_i_id_t_factor_offset_axis_tvalid = 1;
	assign o_o_id_t_factor_offset_axis_tvalid = 1;

endmodule