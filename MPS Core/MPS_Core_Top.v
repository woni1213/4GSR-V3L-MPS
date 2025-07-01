`timescale 1 ns / 1 ps

/*


*/
module MPS_Core_Top #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,								// AXI4-Lite Data Width
	parameter integer C_S_AXI_ADDR_NUM = 128,								// AXI4-Lite Slave Reg Number
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2		// AXI4-Lite Address
)
(
	input i_clk,
	input i_rst,

	input i_w_ready,							// Write Ready by DSP. to DSP (MXTMP4)
	output o_w_valid,							// Write Valid to DSP. to DSP (MXTMP3)
	input i_tx_en,								// from AXIS FRAME IP
	input i_r_valid,
	input i_intl_clr,

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

	// DPBRAM (XINTF) Bus Interface Ports Attribute
	// DPBRAM Write / Address length : 6 (Depth : 43) / Data Width : 16
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM addr0" *) output [8:0] o_xintf_z_to_d_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM ce0" *) output o_xintf_z_to_d_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM we0" *) output o_xintf_z_to_d_we,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM din0" *) output [15:0] o_xintf_z_to_d_din,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM dout0" *) input [15:0] i_xintf_z_to_d_dout,

	// DPBRAM Read / Address length : 4 (Depth : 10) / Data Width : 16
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM addr1" *) output [8:0] o_xintf_d_to_z_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM ce1" *) output o_xintf_d_to_z_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM we1" *) output o_xintf_d_to_z_we,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM din1" *) output [15:0] o_xintf_d_to_z_din,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM dout1" *) input [15:0] i_xintf_d_to_z_dout,

	output o_dsp_duty_intl,

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
	output [31:0] o_phase_rms_r,
	output [31:0] o_phase_rms_s,
	output [31:0] o_phase_rms_t,

	// SFP Slave
	input i_sfp_slave,
	input [31:0] i_s_sfp_set_c,
	input [31:0] i_s_sfp_set_v,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	// AXI4 Lite Bus Interface Ports
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

	wire [31:0] p_gain_c;
	wire [31:0] i_gain_c;
	wire [31:0] d_gain_c;
	wire [31:0] p_gain_v;
	wire [31:0] i_gain_v;
	wire [31:0] d_gain_v;
	wire [3:0] mps_setup;
	wire [31:0] set_c;
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
	wire [31:0] set_v;

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

		.o_mps_setup(mps_setup),
		.o_set_c(set_c),
		.o_set_v(set_v),
		.o_max_duty(max_duty),
		.o_max_phase(max_phase),
		.o_max_freq(max_freq),
		.o_min_freq(min_freq),
		.o_min_c(min_c),
		.o_max_c(max_c),
		.o_min_v(min_v),
		.o_max_v(max_v),
		.o_deadband(deadband),
		.o_sw_freq(sw_freq),
		.o_p_gain_c(p_gain_c),
		.o_i_gain_c(i_gain_c),
		.o_d_gain_c(d_gain_c),
		.o_p_gain_v(p_gain_v),
		.o_i_gain_v(i_gain_v),
		.o_d_gain_v(d_gain_v),

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

	DSP_Handler
	u_DSP_Handler
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_w_ready(i_w_ready),
		.o_w_valid(o_w_valid),
		.i_r_valid(i_r_valid),
		.i_intl_clr(i_intl_clr),

		.i_sfp_slave(i_sfp_slave),
		.i_s_sfp_set_c(i_s_sfp_set_c),
		.i_s_sfp_set_v(i_s_sfp_set_v),

		// Zynq to DSP
		.o_xintf_z_to_d_addr(o_xintf_z_to_d_addr),
		.o_xintf_z_to_d_din(o_xintf_z_to_d_din),
		.o_xintf_z_to_d_ce(o_xintf_z_to_d_ce),

		.i_set_c(set_c),
		.i_set_v(set_v),
		.i_d_gain_c(d_gain_c),
		.i_d_gain_v(d_gain_v),
		.i_p_gain_c(p_gain_c),
		.i_i_gain_c(i_gain_c),
		.i_p_gain_v(p_gain_v),
		.i_i_gain_v(i_gain_v),
		.i_c_adc_data(o_c),
		.i_v_adc_data(o_v),

		.i_max_duty(max_duty),
		.i_max_phase(max_phase),
		.i_max_freq(max_freq),
		.i_min_freq(min_freq),
		.i_min_c(min_c),
		.i_max_c(max_c),
		.i_min_v(min_v),
		.i_max_v(max_v),
		.i_deadband(deadband),
		.i_sw_freq(sw_freq),
		.i_mps_setup(mps_setup),

		// DSP to Zynq
		.i_xintf_d_to_z_dout(i_xintf_d_to_z_dout),
		.o_xintf_d_to_z_addr(o_xintf_d_to_z_addr),
		.o_xintf_d_to_z_ce(o_xintf_d_to_z_ce),

		.o_dsp_max_duty(dsp_max_duty),
		.o_dsp_max_phase(dsp_max_phase),
		.o_dsp_max_frequency(dsp_max_frequency),
		.o_dsp_min_frequency(dsp_min_frequency),
		.o_dsp_min_v(dsp_min_v),
		.o_dsp_max_v(dsp_max_v),
		.o_dsp_min_c(dsp_min_c),
		.o_dsp_max_c(dsp_max_c),
		.o_dsp_deadband(dsp_deadband),
		.o_dsp_sw_freq(dsp_sw_freq),
		.o_dsp_p_gain_c(dsp_p_gain_c),
		.o_dsp_i_gain_c(dsp_i_gain_c),
		.o_dsp_d_gain_c(dsp_d_gain_c),
		.o_dsp_p_gain_v(dsp_p_gain_v),
		.o_dsp_i_gain_v(dsp_i_gain_v),
		.o_dsp_d_gain_v(dsp_d_gain_v),
		.o_dsp_set_c(dsp_set_c),
		.o_dsp_set_v(dsp_set_v),
		.o_dsp_status(dsp_status)
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

	assign o_xintf_z_to_d_we = 1;
	assign o_xintf_d_to_z_we = 0;

	assign o_xintf_wf_ram_ce = 1;
	assign o_xintf_wf_ram_we = 1;

	assign o_set_c = set_c;
	assign o_set_v = set_v;

	assign o_dsp_duty_intl = dsp_status[4];

endmodule