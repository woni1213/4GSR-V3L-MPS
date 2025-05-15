`timescale 1 ns / 1 ps

/*

BR MPS Core Module

SFP 검토
 - Slave 모드일 때 Interlock, Status 정리. 최대 32비트까지

*/

module MPS_Data_Core_Top #
(
	parameter integer C_S_AXI_DATA_WIDTH = 32,								// AXI4-Lite Data Width
	parameter integer C_S_AXI_ADDR_NUM = 128,								// AXI4-Lite Slave Reg Number
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2		// AXI4-Lite Address
)
(
	input i_clk,
	input i_rst,

	input i_dsp_we,
	input i_dsp_rd,
	input i_i_dsp_ce,
	input [8:0] i_dsp_xa,
	inout [15:0] io_dsp_xd,

	input i_tx_en,					// from AXIS FRAME IP

	input i_intl_clr,
	input i_pwm_en,
	input [31:0] i_intl_status,
	input [31:0] i_system_fsm,

	// From ADC
	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [31:0] 	c_adc_s_axis_tdata,					// Current ADC Data
	input 			c_adc_s_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [31:0] 	v_adc_s_axis_tdata,					// Voltage ADC Data
	input			v_adc_s_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [31:0] 	sub_adc_0_s_axis_tdata,				// DC-Link Voltage Data
	input 			sub_adc_0_s_axis_tvalid,
	
	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [31:0] 	sub_adc_1_s_axis_tdata,				// Phase R ADC Data
	input 			sub_adc_1_s_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [31:0] 	sub_adc_2_s_axis_tdata,				// Phase S ADC Data
	input 			sub_adc_2_s_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [31:0] 	sub_adc_3_s_axis_tdata,				// Phase T ADC Data
	input 			sub_adc_3_s_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [31:0] 	sub_adc_4_s_axis_tdata,				// DC-Link Current
	input 			sub_adc_4_s_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [31:0] 	sub_adc_5_s_axis_tdata,				// IGBT Temp. ADC Data
	input 			sub_adc_5_s_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [31:0] 	sub_adc_6_s_axis_tdata,				// In Inductor Temp. ADC Data
	input 			sub_adc_6_s_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	input [31:0] 	sub_adc_7_s_axis_tdata,				// Out Inductor Temp. ADC Data
	input 			sub_adc_7_s_axis_tvalid,

	// SFP Data
	output [1215:0] o_sfp_tx_data,
	input [1215:0] i_sfp_rx_data,
	
	// SFP Flag
	output o_sfp_tx_start_flag,
	input i_sfp_rx_end_flag,

	output [31:0] o_set_c,
	output [31:0] o_set_v,
	output reg [31:0] o_c,
	output reg [31:0] o_v,
	output reg [31:0] o_dc_c,
	output reg [31:0] o_dc_v,
	output reg [31:0] o_phase_r,
	output reg [31:0] o_phase_s,
	output reg [31:0] o_phase_t,
	output reg [31:0] o_igbt_t,
	output reg [31:0] o_i_inductor_t,
	output reg [31:0] o_o_inductor_t,
	output reg [31:0] o_phase_rms_r,
	output reg [31:0] o_phase_rms_s,
	output reg [31:0] o_phase_rms_t,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
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
	input wire  s00_axi_rready,

	output [1:0] o_r_state,
	output [1:0] o_w_state,
	output [2:0] o_sfp_state
);
	wire [3:0] mps_status;
	wire intl_clr;
	wire [31:0] set_c;
	wire [31:0] set_v;
	wire [31:0] max_duty;
	wire [31:0] max_phase;
	wire [31:0] max_freq;
	wire [31:0] min_freq;

	wire [31:0] min_c;
	wire [31:0] max_c;
	wire [31:0] min_v;
	wire [31:0] max_v;
	wire [15:0] deadband;
	wire [15:0] sw_freq;
	wire [31:0] p_gain_c;
	wire [31:0] i_gain_c;
	wire [31:0] d_gain_c;
	wire [31:0] p_gain_v;
	wire [31:0] i_gain_v;
	wire [31:0] d_gain_v;

	wire [3:0] ps_mps_status;
	wire [31:0] ps_set_c;
	wire [31:0] ps_set_v;
	wire [31:0] ps_max_duty;
	wire [31:0] ps_max_phase;
	wire [31:0] ps_max_freq;
	wire [31:0] ps_min_freq;
	wire [31:0] ps_min_c;
	wire [31:0] ps_max_c;
	wire [31:0] ps_min_v;
	wire [31:0] ps_max_v;
	wire [15:0] ps_deadband;
	wire [15:0] ps_sw_freq;
	wire [31:0] ps_p_gain_c;
	wire [31:0] ps_i_gain_c;
	wire [31:0] ps_d_gain_c;
	wire [31:0] ps_p_gain_v;
	wire [31:0] ps_i_gain_v;
	wire [31:0] ps_d_gain_v;

	wire [31:0] dsp_max_duty;
	wire [31:0] dsp_max_phase;
	wire [31:0] dsp_max_frequency;
	wire [31:0] dsp_min_frequency;
	wire [31:0] dsp_min_v;
	wire [31:0] dsp_max_v;
	wire [31:0] dsp_min_c;
	wire [31:0] dsp_max_c;
	wire [15:0] dsp_deadband;
	wire [15:0] dsp_sw_freq;
	wire [31:0] dsp_p_gain_c;
	wire [31:0] dsp_i_gain_c;
	wire [31:0] dsp_d_gain_c;
	wire [31:0] dsp_p_gain_v;
	wire [31:0] dsp_i_gain_v;
	wire [31:0] dsp_d_gain_v;
	wire [31:0] dsp_set_c;
	wire [31:0] dsp_set_v;
	wire [15:0] dsp_status;

	wire sfp_en;
	wire sfp_id;
	wire sfp_slave;

	wire [1279:0] m_sfp_data;

	wire [31:0] sfp_c;
	wire [31:0] sfp_v;
	wire [31:0] sfp_dc_c;
	wire [31:0] sfp_dc_v;
	wire [31:0] sfp_phase_r_rms;
	wire [31:0] sfp_phase_s_rms;
	wire [31:0] sfp_phase_t_rms;
	wire [31:0] sfp_igbt_t;
	wire [31:0] sfp_i_inductor_t;
	wire [31:0] sfp_o_inductor_t;
	wire [31:0] sfp_intl;
	wire [31:0] sfp_fsm;

	wire [3:0] sfp_mps_status;
	wire sfp_intl_clr;
	wire [31:0] sfp_set_c;
	wire [31:0] sfp_set_v;
	wire [31:0] sfp_max_duty;
	wire [31:0] sfp_max_phase;
	wire [31:0] sfp_max_freq;
	wire [31:0] sfp_min_freq;
	wire [31:0] sfp_min_c;
	wire [31:0] sfp_max_c;
	wire [31:0] sfp_min_v;
	wire [31:0] sfp_max_v;
	wire [15:0] sfp_deadband;
	wire [15:0] sfp_sw_freq;
	wire [31:0] sfp_p_gain_c;
	wire [31:0] sfp_i_gain_c;
	wire [31:0] sfp_d_gain_c;
	wire [31:0] sfp_p_gain_v;
	wire [31:0] sfp_i_gain_v;
	wire [31:0] sfp_d_gain_v;

	wire [31:0] sfp_c_over_sp;
	wire [31:0] sfp_v_over_sp;
	wire [31:0] sfp_dc_c_over_sp;
	wire [31:0] sfp_dc_v_over_sp;
	wire [31:0] sfp_igbt_t_over_sp;
	wire [31:0] sfp_i_id_t_over_sp;
	wire [31:0] sfp_o_id_t_over_sp;
	wire [31:0] sfp_c_data_thresh;
	wire [31:0] sfp_c_cnt_thresh;
	wire [31:0] sfp_c_period;
	wire [31:0] sfp_c_cycle_cnt;
	wire [31:0] sfp_c_diff;
	wire [31:0] sfp_c_delay;
	wire [31:0] sfp_v_data_thresh;
	wire [31:0] sfp_v_cnt_thresh;
	wire [31:0] sfp_v_period;
	wire [31:0] sfp_v_cycle_cnt;
	wire [31:0] sfp_v_diff;
	wire [31:0] sfp_v_delay;

	wire [15:0]		xintf_z_to_d_data;
	wire [15:0]		xintf_d_to_z_data;

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
		begin
			o_c 			<= 0;
			o_v 			<= 0;
			o_dc_c 			<= 0;
			o_dc_v 			<= 0;
			o_phase_r 		<= 0;
			o_phase_s 		<= 0;
			o_phase_t 		<= 0;
			o_igbt_t 		<= 0;
			o_i_inductor_t 	<= 0;
			o_o_inductor_t 	<= 0;
		end

		else
		begin
			o_c 			<= (c_adc_s_axis_tvalid) ? c_adc_s_axis_tdata : o_c;
			o_v 			<= (v_adc_s_axis_tvalid) ? v_adc_s_axis_tdata : o_v;
			o_dc_c 			<= (sub_adc_4_s_axis_tvalid) ? sub_adc_4_s_axis_tdata : o_dc_c;
			o_dc_v 			<= (sub_adc_0_s_axis_tvalid) ? sub_adc_0_s_axis_tdata : o_dc_v;
			o_phase_r 		<= (sub_adc_1_s_axis_tvalid) ? sub_adc_1_s_axis_tdata : o_phase_r;
			o_phase_s 		<= (sub_adc_2_s_axis_tvalid) ? sub_adc_2_s_axis_tdata : o_phase_s;
			o_phase_t 		<= (sub_adc_3_s_axis_tvalid) ? sub_adc_3_s_axis_tdata : o_phase_t;
			o_igbt_t 		<= (sub_adc_5_s_axis_tvalid) ? sub_adc_5_s_axis_tdata : o_igbt_t;
			o_i_inductor_t 	<= (sub_adc_6_s_axis_tvalid) ? sub_adc_6_s_axis_tdata : o_i_inductor_t;
			o_o_inductor_t 	<= (sub_adc_7_s_axis_tvalid) ? sub_adc_7_s_axis_tdata : o_o_inductor_t;
		end
	end

	AXI4_Lite_MPS_Core #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_MPS_Core
	(
		.i_xintf_addr(i_dsp_xa),
		.o_xintf_z_to_d_data(xintf_z_to_d_data),
		.i_xintf_d_to_z_data(xintf_d_to_z_data),
		.i_dsp_we(i_dsp_we),

		.i_zynq_status({i_pwm_en, intl_clr, mps_status}),
		// ADC Data
		.i_c_data(o_c),
		.i_v_data(o_v),
		.i_dc_c_data(o_dc_c),
		.i_dc_v_data(o_dc_v),
		.i_phase_r_data(o_phase_r),
		.i_phase_s_data(o_phase_s),
		.i_phase_t_data(o_phase_t),
		.i_igbt_t_data(o_igbt_t),
		.i_i_inductor_t_data(o_i_inductor_t),
		.i_o_inductor_t_data(o_o_inductor_t),
		.i_phase_rms_r(o_phase_rms_r),
		.i_phase_rms_s(o_phase_rms_s),
		.i_phase_rms_t(o_phase_rms_t),
		
		// Zynq -> DSP
		.o_mps_status(ps_mps_status),
		.o_set_c(ps_set_c),
		.o_set_v(ps_set_v),
		.o_max_duty(ps_max_duty),
		.o_max_phase(ps_max_phase),
		.o_max_freq(ps_max_freq),
		.o_min_freq(ps_min_freq),
		.o_min_c(ps_min_c),
		.o_max_c(ps_max_c),
		.o_min_v(ps_min_v),
		.o_max_v(ps_max_v),
		.o_deadband(ps_deadband),
		.o_sw_freq(ps_sw_freq),
		.o_p_gain_c(ps_p_gain_c),
		.o_i_gain_c(ps_i_gain_c),
		.o_d_gain_c(ps_d_gain_c),
		.o_p_gain_v(ps_p_gain_v),
		.o_i_gain_v(ps_i_gain_v),
		.o_d_gain_v(ps_d_gain_v),
		

		// DSP -> Zynq
		.i_dsp_max_duty(dsp_max_duty),
		.i_dsp_max_phase(dsp_max_phase),
		.i_dsp_max_frequency(dsp_max_frequency),
		.i_dsp_min_frequency(dsp_min_frequency),
		.i_dsp_min_v(dsp_min_v),
		.i_dsp_max_v(dsp_max_v),
		.i_dsp_min_c(dsp_min_c),
		.i_dsp_max_c(dsp_max_c),
		.i_dsp_deadband(dsp_deadband),
		.i_dsp_sw_freq(dsp_sw_freq),
		.i_dsp_p_gain_c(dsp_p_gain_c),
		.i_dsp_i_gain_c(dsp_i_gain_c),
		.i_dsp_d_gain_c(dsp_d_gain_c),
		.i_dsp_p_gain_v(dsp_p_gain_v),
		.i_dsp_i_gain_v(dsp_i_gain_v),
		.i_dsp_d_gain_v(dsp_d_gain_v),
		.i_dsp_set_c(dsp_set_c),
		.i_dsp_set_v(dsp_set_v),
		.i_dsp_status(dsp_status),

		// SFP
		.o_sfp_en(sfp_en),
		.o_sfp_id(sfp_id),

		.o_m_sfp_data(m_sfp_data),

		.i_sfp_c(sfp_c),
		.i_sfp_v(sfp_v),
		.i_sfp_dc_c(sfp_dc_c),
		.i_sfp_dc_v(sfp_dc_v),
		.i_sfp_phase_r_rms(sfp_phase_r_rms),
		.i_sfp_phase_s_rms(sfp_phase_s_rms),
		.i_sfp_phase_t_rms(sfp_phase_t_rms),
		.i_sfp_igbt_t(sfp_igbt_t),
		.i_sfp_i_inductor_t(sfp_i_inductor_t),
		.i_sfp_o_inductor_t(sfp_o_inductor_t),
		.i_sfp_intl(sfp_intl),
		.i_sfp_fsm(sfp_fsm),

		.i_sfp_c_over_sp(sfp_c_over_sp),
		.i_sfp_v_over_sp(sfp_v_over_sp),
		.i_sfp_dc_c_over_sp(sfp_dc_c_over_sp),
		.i_sfp_dc_v_over_sp(sfp_dc_v_over_sp),
		.i_sfp_igbt_t_over_sp(sfp_igbt_t_over_sp),
		.i_sfp_i_id_t_over_sp(sfp_i_id_t_over_sp),
		.i_sfp_o_id_t_over_sp(sfp_o_id_t_over_sp),
		.i_sfp_c_data_thresh(sfp_c_data_thresh),
		.i_sfp_c_cnt_thresh(sfp_c_cnt_thresh),
		.i_sfp_c_period(sfp_c_period),
		.i_sfp_c_cycle_cnt(sfp_c_cycle_cnt),
		.i_sfp_c_diff(sfp_c_diff),
		.i_sfp_c_delay(sfp_c_delay),
		.i_sfp_v_data_thresh(sfp_v_data_thresh),
		.i_sfp_v_cnt_thresh(sfp_v_cnt_thresh),
		.i_sfp_v_period(sfp_v_period),
		.i_sfp_v_cycle_cnt(sfp_v_cycle_cnt),
		.i_sfp_v_diff(sfp_v_diff),
		.i_sfp_v_delay(sfp_v_delay),

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

		.i_zynq_sfp_en(sfp_en),
		.i_sfp_id(sfp_id),

		.i_sfp_rx_data(i_sfp_rx_data),
		.o_sfp_tx_start_flag(o_sfp_tx_start_flag),
		.i_sfp_rx_end_flag(i_sfp_rx_end_flag),
		.i_sfp_tx_end_flag(i_tx_en),

		// Slave -> Master
		.o_sfp_c(sfp_c),
		.o_sfp_v(sfp_v),
		.o_sfp_dc_c(sfp_dc_c),
		.o_sfp_dc_v(sfp_dc_v),
		.o_sfp_phase_r_rms(sfp_phase_r_rms),
		.o_sfp_phase_s_rms(sfp_phase_s_rms),
		.o_sfp_phase_t_rms(sfp_phase_t_rms),
		.o_sfp_igbt_t(sfp_igbt_t),
		.o_sfp_i_inductor_t(sfp_i_inductor_t),
		.o_sfp_o_inductor_t(sfp_o_inductor_t),
		.o_sfp_intl(sfp_intl),
		.o_sfp_fsm(sfp_fsm),

		// Master -> Slave
		.o_sfp_mps_status(sfp_mps_status),
		.o_sfp_intl_clr(sfp_intl_clr),
		.o_sfp_fsm_cmd(),
		.o_sfp_set_c(sfp_set_c),
		.o_sfp_set_v(sfp_set_v),
		.o_sfp_max_duty(sfp_max_duty),
		.o_sfp_max_phase(sfp_max_phase),
		.o_sfp_max_freq(sfp_max_freq),
		.o_sfp_min_freq(sfp_min_freq),
		.o_sfp_min_c(sfp_min_c),
		.o_sfp_max_c(sfp_max_c),
		.o_sfp_min_v(sfp_min_v),
		.o_sfp_max_v(sfp_max_v),
		.o_sfp_deadband(sfp_deadband),
		.o_sfp_sw_freq(sfp_sw_freq),
		.o_sfp_p_gain_c(sfp_p_gain_c),
		.o_sfp_i_gain_c(sfp_i_gain_c),
		.o_sfp_d_gain_c(sfp_d_gain_c),
		.o_sfp_p_gain_v(sfp_p_gain_v),
		.o_sfp_i_gain_v(sfp_i_gain_v),
		.o_sfp_d_gain_v(sfp_d_gain_v),

		.o_sfp_c_over_sp(sfp_c_over_sp),
		.o_sfp_v_over_sp(sfp_v_over_sp),
		.o_sfp_dc_c_over_sp(sfp_dc_c_over_sp),
		.o_sfp_dc_v_over_sp(sfp_dc_v_over_sp),
		.o_sfp_igbt_t_over_sp(sfp_igbt_t_over_sp),
		.o_sfp_i_id_t_over_sp(sfp_i_id_t_over_sp),
		.o_sfp_o_id_t_over_sp(sfp_o_id_t_over_sp),
		.o_sfp_c_data_thresh(sfp_c_data_thresh),
		.o_sfp_c_cnt_thresh(sfp_c_cnt_thresh),
		.o_sfp_c_period(sfp_c_period),
		.o_sfp_c_cycle_cnt(sfp_c_cycle_cnt),
		.o_sfp_c_diff(sfp_c_diff),
		.o_sfp_c_delay(sfp_c_delay),
		.o_sfp_v_data_thresh(sfp_v_data_thresh),
		.o_sfp_v_cnt_thresh(sfp_v_cnt_thresh),
		.o_sfp_v_period(sfp_v_period),
		.o_sfp_v_cycle_cnt(sfp_v_cycle_cnt),
		.o_sfp_v_diff(sfp_v_diff),
		.o_sfp_v_delay(sfp_v_delay),

		.o_state(o_sfp_state)
	);

	Phase_RMS u_Phase_RMS_R
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_phase(o_phase_r),
		.o_rms(o_phase_rms_r),

		.o_state()
	);

	Phase_RMS u_Phase_RMS_S
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_phase(o_phase_s),
		.o_rms(o_phase_rms_s),

		.o_state()
	);

	Phase_RMS u_Phase_RMS_T
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_phase(o_phase_t),
		.o_rms(o_phase_rms_t),

		.o_state()
	);

	assign io_dsp_xd = (i_dsp_we) ? xintf_z_to_d_data : 16'hZZZZ;
	assign xintf_d_to_z_data = (~i_dsp_we) ? io_dsp_xd : 16'hZZZZ;

	assign sfp_slave = (sfp_en && sfp_id);

	assign o_sfp_tx_data = (sfp_slave) ? {i_system_fsm, i_intl_status, o_o_inductor_t, o_i_inductor_t, o_igbt_t, o_phase_t, o_phase_s, o_phase_r, o_dc_v, o_dc_c, o_v, o_c}
												: m_sfp_data;
	
	assign mps_status 	= (sfp_slave) ? sfp_mps_status : ps_mps_status;
	assign intl_clr 	= (sfp_slave) ? sfp_intl_clr : i_intl_clr;
	assign set_c 		= (sfp_slave) ? sfp_set_c : ps_set_c;
	assign set_v 		= (sfp_slave) ? sfp_set_v : ps_set_v;
	assign max_duty 	= (sfp_slave) ? sfp_max_duty : ps_max_duty;
	assign max_phase 	= (sfp_slave) ? sfp_max_phase : ps_max_phase;
	assign max_freq 	= (sfp_slave) ? sfp_max_freq : ps_max_freq;
	assign min_freq 	= (sfp_slave) ? sfp_min_freq : ps_min_freq;
	assign min_c 		= (sfp_slave) ? sfp_min_c : ps_min_c;
	assign max_c 		= (sfp_slave) ? sfp_max_c : ps_max_c;
	assign min_v 		= (sfp_slave) ? sfp_min_v : ps_min_v;
	assign max_v 		= (sfp_slave) ? sfp_max_v : ps_max_v;
	assign deadband 	= (sfp_slave) ? sfp_deadband : ps_deadband;
	assign sw_freq 		= (sfp_slave) ? sfp_sw_freq : ps_sw_freq;
	assign p_gain_c 	= (sfp_slave) ? sfp_p_gain_c : ps_p_gain_c;
	assign i_gain_c 	= (sfp_slave) ? sfp_i_gain_c : ps_i_gain_c;
	assign d_gain_c 	= (sfp_slave) ? sfp_d_gain_c : ps_d_gain_c;
	assign p_gain_v 	= (sfp_slave) ? sfp_p_gain_v : ps_p_gain_v;
	assign i_gain_v 	= (sfp_slave) ? sfp_i_gain_v : ps_i_gain_v;
	assign d_gain_v 	= (sfp_slave) ? sfp_d_gain_v : ps_d_gain_v;
	
	assign o_set_c = set_c;
	assign o_set_v = set_v;
	
endmodule