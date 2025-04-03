`timescale 1 ns / 1 ps

/*

BR MPS System Module

개발 2팀 전경원 부장

25.04.03 :	최초 생성

1. 개요
 - MPS FSM
 - MPS I/F

*/

module MPS_System_Top #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,								// AXI4-Lite Data Width
	parameter integer C_S_AXI_ADDR_NUM = 20,								// AXI4-Lite Slave Reg Number
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2		// AXI4-Lite Address
)
(
	input i_clk,
	input i_rst,

	input [15:0] i_ext_di,
	output [7:0] o_ext_do,

	output o_emergency,
	output o_main_mc_m,
	output o_slow_charge_mc_m,
	output o_discharge_mc_m,
	output o_diode_over_t_m,
	output o_igbt_over_t_m,
	output o_damp_res_over_t_m,
	output o_diode_flow_m,
	output o_igbt_res_flow_m,
	output o_f_door_m,
	output o_r_door_m,
	output o_leakage_m,
	output o_spare_di_m,
	output o_ext_1_m,
	output o_ext_2_m,
	output o_ext_3_m,

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

	wire ps_main_mc;
	wire ps_slow_charge_mc;
	wire ps_discharge_mc;
	wire ps_ext_do_1;
	wire ps_ext_do_2;
	wire ps_ext_do_3;
	wire ps_leakage_rst;
	wire ps_spare_do;

	wire pl_main_mc;
	wire pl_slow_charge_mc;
	wire pl_discharge_mc;
	wire pl_ext_do_1;
	wire pl_ext_do_2;
	wire pl_ext_do_3;
	wire pl_leakage_rst;
	wire pl_spare_do;

	AXI4_Lite_MPS_System #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_MPS_System
	(
		.o_mps_sys			(),
		.o_mps_fsm			(),
		.o_main_mc			(ps_main_mc),
		.o_slow_charge_mc	(ps_slow_charge_mc),
		.o_discharge_mc		(ps_discharge_mc),
		.o_ext_do_1			(ps_ext_do_1),
		.o_ext_do_2			(ps_ext_do_2),
		.o_ext_do_3			(ps_ext_do_3),
		.o_leakage_rst		(ps_leakage_rst),
		.o_spare_do			(ps_spare_do),

		.i_ext_di		(i_ext_di),
		.i_mps_fsm_m	(0),

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

	assign o_emergency = i_ext_di[0];
	assign o_main_mc_m = i_ext_di[1];
	assign o_slow_charge_mc_m = i_ext_di[2];
	assign o_discharge_mc_m = i_ext_di[3];
	assign o_diode_over_t_m = i_ext_di[4];
	assign o_igbt_over_t_m = i_ext_di[5];
	assign o_damp_res_over_t_m = i_ext_di[6];
	assign o_diode_flow_m = i_ext_di[7];
	assign o_igbt_res_flow_m = i_ext_di[8];
	assign o_f_door_m = i_ext_di[9];
	assign o_r_door_m = i_ext_di[10];
	assign o_leakage_m = i_ext_di[11];
	assign o_spare_di_m = i_ext_di[12];
	assign o_ext_1_m = i_ext_di[13];
	assign o_ext_2_m = i_ext_di[14];
	assign o_ext_3_m = i_ext_di[15];

	assign o_ext_do = {ps_main_mc, ps_slow_charge_mc, ps_discharge_mc, ps_ext_do_1, ps_ext_do_2, ps_ext_do_3, ps_leakage_rst, ps_spare_do};

endmodule