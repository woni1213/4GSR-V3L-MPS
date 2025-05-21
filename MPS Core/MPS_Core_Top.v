`timescale 1 ns / 1 ps

/*


*/
module MPS_Core_Top #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,								// AXI4-Lite Data Width
	parameter integer C_S_AXI_ADDR_NUM = 128,								// AXI4-Lite Slave Reg Number
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2,	// AXI4-Lite Address

	parameter integer C_AXIS_TDATA_WIDTH = 64,								// Frame Data Width (Aurora 64B/66B)
	parameter integer C_NUMBER_OF_FRAME = 2,								// Slave??“½ Frame ??‹”

	parameter integer C_DATA_FRAME_BIT = ((C_AXIS_TDATA_WIDTH) * (C_NUMBER_OF_FRAME))	// ??Ÿ¾ï§?? Frame Bit ??‹”
)
(
	input [31:0] i_zynq_intl,					// Interlock Input. from INTL IP
	input i_w_ready,							// Write Ready by DSP. to DSP (MXTMP4)
	output o_w_valid,							// Write Valid to DSP. to DSP (MXTMP3)
	input i_tx_en,								// from AXIS FRAME IP
	input i_r_valid,

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

	/////////////////////////////////////////////////////////
	// SFP Data
	output [383:0] o_sfp_tx_data,
	input [383:0] i_sfp_rx_data,
	
	// SFP Flag
	output o_sfp_tx_start_flag,					// SFP Tx ??–†??˜‰
	input i_sfp_rx_end_flag,					// SFP Rx ?†«?‚…ì¦?
	///////////////////////////////////////////////////////

    // DPBRAM (XINTF) Bus Interface Ports Attribute
	// DPBRAM Write / Address length : 6 (Depth : 43) / Data Width : 16
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM addr0" *) output [8:0] o_xintf_w_ram_addr,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM ce0" *) output o_xintf_w_ram_ce,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM we0" *) output o_xintf_w_ram_we,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM din0" *) output [15:0] o_xintf_w_ram_din,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM dout0" *) input [15:0] i_xintf_w_ram_dout,

	// DPBRAM Read / Address length : 4 (Depth : 10) / Data Width : 16
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM addr1" *) output [8:0] o_xintf_r_ram_addr,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM ce1" *) output o_xintf_r_ram_ce,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM we1" *) output o_xintf_r_ram_we,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM din1" *) output [15:0] o_xintf_r_ram_din,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM dout1" *) input [15:0] i_xintf_r_ram_dout,

	output o_dsp_status,

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
	wire axi_data_valid;

    wire [31:0] p_gain_c;
    wire [31:0] i_gain_c;
    wire [31:0] d_gain_c;
	wire [31:0] p_gain_v;
	wire [31:0] i_gain_v;
	wire [31:0] d_gain_v;
	wire [12:0] zynq_status;
	wire [15:0] write_index;
	wire [31:0] index_data;
    wire [31:0] set_c;
	wire write_index_flag;
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
	wire [2:0] slave_count;
	wire [15:0] s_zynq_intl;
	wire slave_1_ram_cs;
	wire [7:0] slave_1_ram_addr;
	wire slave_2_ram_cs;
	wire [7:0] slave_2_ram_addr;
	wire slave_3_ram_cs;
	wire [7:0] slave_3_ram_addr;
	wire axi_pwm_en;

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
	wire [31:0] dsp_pi_param;
	wire [31:0] slave_c;
    wire [31:0] slave_v;
	wire [31:0] slave_status;
    wire [15:0] dsp_status;
    wire [15:0] dsp_ver;
    wire [31:0] slave_1_ram_data;
    wire [31:0] slave_2_ram_data;
    wire [31:0] slave_3_ram_data;

	/////////////////////////////////////////////////////////
	wire sfp_en;
	wire [1:0] sfp_id;

	wire [15:0] sfp_cmd;
	wire [31:0] sfp_data_1;
	wire [31:0] sfp_data_2;
	wire [31:0] sfp_data_3;

	wire [7:0] m_dsp_sfp_cmd;

	wire [7:0] m_zynq_sfp_1_cmd;
	wire [31:0] m_sfp_1_data;

	wire [7:0] m_zynq_sfp_2_cmd;
	wire [31:0] m_sfp_2_data;

	wire [7:0] m_zynq_sfp_3_cmd;
	wire [31:0] m_sfp_3_data;

	wire [15:0] s_sfp_1_cmd;
	wire [31:0] s_sfp_1_data_1;
	wire [31:0] s_sfp_1_data_2;
	wire [31:0] s_sfp_1_data_3;

	wire [15:0] s_sfp_2_cmd;
	wire [31:0] s_sfp_2_data_1;
	wire [31:0] s_sfp_2_data_2;
	wire [31:0] s_sfp_2_data_3;

	wire [15:0] s_sfp_3_cmd;
	wire [31:0] s_sfp_3_data_1;
	wire [31:0] s_sfp_3_data_2;
	wire [31:0] s_sfp_3_data_3;
/////////////////////////////////////////////////////////
	wire sfp_pwm_en;
	wire [31:0] sfp_c_factor;
	wire [31:0] sfp_v_factor;
	wire [15:0] sfp_zynq_ver;
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
	wire sfp_intl_clr;
	wire [31:0] sfp_set_c;
	wire [31:0] sfp_set_v;

	always @(posedge s00_axi_aclk or negedge s00_axi_aresetn) 
	begin
		if (~s00_axi_aresetn)
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

		// assign o_c 				= (c_adc_s_axis_tvalid) ? c_adc_s_axis_tdata : o_c;
		// assign o_v 				= (v_adc_s_axis_tvalid) ? v_adc_s_axis_tdata : o_v;
		// assign o_dc_c 			= (sub_adc_4_s_axis_tvalid) ? sub_adc_4_s_axis_tdata : o_dc_c;
		// assign o_dc_v 			= (sub_adc_0_s_axis_tvalid) ? sub_adc_0_s_axis_tdata : o_dc_v;
		// assign o_phase_r 		= (sub_adc_1_s_axis_tvalid) ? sub_adc_1_s_axis_tdata : o_phase_r;
		// assign o_phase_s 		= (sub_adc_2_s_axis_tvalid) ? sub_adc_2_s_axis_tdata : o_phase_s;
		// assign o_phase_t 		= (sub_adc_3_s_axis_tvalid) ? sub_adc_3_s_axis_tdata : o_phase_t;
		// assign o_igbt_t 		= (sub_adc_5_s_axis_tvalid) ? sub_adc_5_s_axis_tdata : o_igbt_t;
		// assign o_i_inductor_t 	= (sub_adc_6_s_axis_tvalid) ? sub_adc_6_s_axis_tdata : o_i_inductor_t;
		// assign o_o_inductor_t 	= (sub_adc_7_s_axis_tvalid) ? sub_adc_7_s_axis_tdata : o_o_inductor_t;

	AXI4_Lite_MPS_Core #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),

		.C_DATA_FRAME_BIT(C_DATA_FRAME_BIT)
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

		.o_mps_status(zynq_status),
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

		.o_sfp_en(sfp_en),
		.o_sfp_id(sfp_id),

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

    DSP_Handler
	u_DSP_Handler
	(
        .i_clk(s00_axi_aclk),
        .i_rst(s00_axi_aresetn),

		.i_zynq_sfp_en(sfp_en),
		.i_sfp_id(sfp_id),
		.i_axi_pwm_en(0),

		.i_zynq_intl(i_zynq_intl),
		.i_w_ready(i_w_ready),
		.o_w_valid(o_w_valid),
		.i_r_valid(i_r_valid),

        // DPBRAM WRITE
        .o_xintf_w_ram_addr(o_xintf_w_ram_addr),
        .o_xintf_w_ram_din(o_xintf_w_ram_din),
		.o_xintf_w_ram_ce(o_xintf_w_ram_ce),

		.i_aurora_set_mode(sfp_id),
		.i_aurora_set_cmd(sfp_cmd),
		.i_d_gain_c(d_gain_c),
		.i_d_gain_v(d_gain_v),
		//
		.i_p_gain_c(p_gain_c),
		.i_i_gain_c(i_gain_c),
		.i_p_gain_v(p_gain_v),
		.i_i_gain_v(i_gain_v),
		//
        .i_c_adc_data(o_c),
        .i_v_adc_data(o_v),
        .i_zynq_status(0),
		.i_write_index(0),
		.i_index_data(0),
		.i_set_c(set_c),
		.i_max_duty(max_duty),
		.i_max_phase(max_phase),
		.i_max_freq(max_freq),
		.i_min_freq(min_freq),
		//
		.i_min_c(min_c),
		.i_max_c(max_c),
		.i_min_v(min_v),
		.i_max_v(max_v),
		.i_deadband(deadband),
		.i_sw_freq(sw_freq),
		//
		.i_set_v(set_v),
		.i_master_pi_param(sfp_data_1),			// Master PI Parameter Send to DSP (SFP Slave Mode)
		.i_slave_1_c(s_sfp_1_data_1),
		.i_slave_1_v(s_sfp_1_data_2),
		.i_slave_2_c(s_sfp_2_data_1),
        .i_slave_2_v(s_sfp_2_data_2),
        .i_slave_3_c(s_sfp_3_data_1),
        .i_slave_3_v(s_sfp_3_data_2),
        .i_slave_1_status(s_sfp_1_cmd),
        .i_slave_2_status(s_sfp_2_cmd),
		.i_slave_3_status(s_sfp_3_cmd),
		.i_slave_count(slave_count),

        // DPBRAM READ
        .i_xintf_r_ram_dout(i_xintf_r_ram_dout),
        .o_xintf_r_ram_addr(o_xintf_r_ram_addr),
		.o_xintf_r_ram_ce(o_xintf_r_ram_ce),

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
		.o_dsp_pi_param(dsp_pi_param),
		.o_slave_c(slave_c),
		.o_slave_v(slave_v),
		.o_slave_status(slave_status),
		.o_dsp_status(dsp_status),
		.o_dsp_cmd(m_dsp_sfp_cmd),
		.o_dsp_ver(dsp_ver),

		// SFP CMD Data
		.i_sfp_pwm_en(sfp_pwm_en),
		.i_sfp_zynq_ver(sfp_zynq_ver),
		.i_sfp_min_c(sfp_min_c),
		.i_sfp_max_c(sfp_max_c),
		.i_sfp_min_v(sfp_min_v),
		.i_sfp_max_v(sfp_max_v),
		.i_sfp_deadband(sfp_deadband),
		.i_sfp_sw_freq(sfp_sw_freq),
		.i_sfp_p_gain_c(sfp_p_gain_c),
		.i_sfp_i_gain_c(sfp_i_gain_c),
		.i_sfp_d_gain_c(sfp_d_gain_c),
		.i_sfp_p_gain_v(sfp_p_gain_v),
		.i_sfp_i_gain_v(sfp_i_gain_v),
		.i_sfp_d_gain_v(sfp_d_gain_v),
		.i_sfp_intl_clr(sfp_intl_clr),
		.i_sfp_1_stat	(s_sfp_1_cmd),
		.i_sfp_2_stat	(s_sfp_2_cmd),
		.i_sfp_3_stat	(s_sfp_3_cmd),

		.i_m_sfp_1_data(m_sfp_1_data),
		.i_m_sfp_2_data(m_sfp_2_data),
		.i_m_sfp_3_data(m_sfp_3_data),

		.i_sfp_set_c(sfp_set_c),
		.i_sfp_set_v(sfp_set_v),
		
		// DC
		.i_dc_v_adc(o_dc_v),
		.i_dc_c_adc(o_dc_c)
    );

	///////////////////////////////////////////////
	SFP_Handler
	u_SFP_Handler
	(
		.i_clk(s00_axi_aclk),
		.i_rst(s00_axi_aresetn),

		.i_zynq_sfp_en(sfp_en),
		.i_sfp_id(sfp_id),
		.i_axi_data_valid(axi_data_valid),

		// Slave Mode
		.i_slv_state(0),						// Slave Mode MPS Status
		.i_curr_data(c_adc_s_axis_tdata),
		.i_volt_data(v_adc_s_axis_tdata),
		.i_dc_data(sub_adc_4_s_axis_tdata),				// Slave Mode DC-Link

		.o_sfp_cmd		(sfp_cmd),						// Slave Mode Input Command
		.o_sfp_data_1	(sfp_data_1),
		.o_sfp_data_2	(sfp_data_2),
		.o_sfp_data_3	(sfp_data_3),

		// Master Mode
		.i_dsp_sfp_cmd		(m_dsp_sfp_cmd),

		.i_zynq_sfp_1_cmd	(m_zynq_sfp_1_cmd),			// Master Mode 1st Slave MPS Command
		.i_sfp_1_data_1		(dsp_pi_param),
		.i_sfp_1_data_2		(m_sfp_1_data),
		.i_sfp_1_data_3		(m_sfp_1_data_3),

		.i_zynq_sfp_2_cmd	(m_zynq_sfp_2_cmd),			// Master Mode 2nd Slave MPS Command
		.i_sfp_2_data_1		(dsp_pi_param),
		.i_sfp_2_data_2		(m_sfp_2_data),
		.i_sfp_2_data_3		(m_sfp_2_data_3),

		.i_zynq_sfp_3_cmd	(m_zynq_sfp_3_cmd),			// Master Mode 3rd Slave MPS Command
		.i_sfp_3_data_1		(dsp_pi_param),
		.i_sfp_3_data_2		(m_sfp_3_data),
		.i_sfp_3_data_3		(m_sfp_3_data_3),

		.o_sfp_1_stat	(s_sfp_1_cmd),					// Master Mode 1st Slave MPS Status
		.o_sfp_1_curr	(s_sfp_1_data_1),
		.o_sfp_1_volt	(s_sfp_1_data_2),
		.o_sfp_1_dc		(s_sfp_1_data_3),

		.o_sfp_2_stat	(s_sfp_2_cmd),					// Master Mode 2nd Slave MPS Status
		.o_sfp_2_curr	(s_sfp_2_data_1),
		.o_sfp_2_volt	(s_sfp_2_data_2),
		.o_sfp_2_dc		(s_sfp_2_data_3),

		.o_sfp_3_stat	(s_sfp_3_cmd),					// Master Mode 3rd Slave MPS Status
		.o_sfp_3_curr	(s_sfp_3_data_1),
		.o_sfp_3_volt	(s_sfp_3_data_2),
		.o_sfp_3_dc		(s_sfp_3_data_3),

		// SFP
		.o_sfp_tx_data(o_sfp_tx_data),					// SFP Tx Data
		.i_sfp_rx_data(i_sfp_rx_data),					// SFP Rx Data
		.o_sfp_tx_start_flag(o_sfp_tx_start_flag),
		.i_sfp_rx_end_flag(i_sfp_rx_end_flag),
		.i_sfp_tx_end_flag(i_tx_en),

		.o_state(o_sfp_state),							// FSM

		// SFP Slave Zynq CMD Data
		.o_sfp_pwm_en(sfp_pwm_en),
		.o_sfp_c_factor(sfp_c_factor),
		.o_sfp_v_factor(sfp_v_factor),
		.o_sfp_zynq_ver(sfp_zynq_ver),
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
		.o_sfp_intl_clr(sfp_intl_clr),
		.o_sfp_set_c(sfp_set_c),
		.o_sfp_set_v(sfp_set_v)
	);
//////////////////////////////////////////////
	Slave_DPBRAM
	u_Slave_DPBRAM_1
	(
		.i_clk(s00_axi_aclk),

		.i_slave_w_ram_addr(m_zynq_sfp_1_cmd),
		.i_slave_w_ram_ce(axi_data_valid),
		.i_slave_w_ram_din(m_sfp_1_data),

		.i_slave_r_ram_addr(slave_1_ram_addr),
		.i_slave_r_ram_ce(slave_1_ram_cs),
		.o_slave_r_ram_dout(slave_1_ram_data)
	);

	Slave_DPBRAM
	u_Slave_DPBRAM_2
	(
		.i_clk(s00_axi_aclk),

		.i_slave_w_ram_addr(m_zynq_sfp_2_cmd),
		.i_slave_w_ram_ce(axi_data_valid),
		.i_slave_w_ram_din(m_sfp_2_data),

		.i_slave_r_ram_addr(slave_2_ram_addr),
		.i_slave_r_ram_ce(slave_2_ram_cs),
		.o_slave_r_ram_dout(slave_2_ram_data)
	);

	Slave_DPBRAM
	u_Slave_DPBRAM_3
	(
		.i_clk(s00_axi_aclk),

		.i_slave_w_ram_addr(m_zynq_sfp_3_cmd),
		.i_slave_w_ram_ce(axi_data_valid),
		.i_slave_w_ram_din(m_sfp_3_data),

		.i_slave_r_ram_addr(slave_3_ram_addr),
		.i_slave_r_ram_ce(slave_3_ram_cs),
		.o_slave_r_ram_dout(slave_3_ram_data)
	);

	Phase_RMS u_Phase_RMS_R
	(
		.i_clk(s00_axi_aclk),
		.i_rst(s00_axi_aresetn),

		.i_phase(o_phase_r),
		.o_rms(o_phase_rms_r),

		.o_state()
	);

	Phase_RMS u_Phase_RMS_S
	(
		.i_clk(s00_axi_aclk),
		.i_rst(s00_axi_aresetn),

		.i_phase(o_phase_s),
		.o_rms(o_phase_rms_s),

		.o_state()
	);

	Phase_RMS u_Phase_RMS_T
	(
		.i_clk(s00_axi_aclk),
		.i_rst(s00_axi_aresetn),

		.i_phase(o_phase_t),
		.o_rms(o_phase_rms_t),

		.o_state()
	);

    assign o_c_factor_axis_tvalid = 1;
    assign o_v_factor_axis_tvalid = 1;
	assign o_dc_c_factor_axis_tvalid = 1;
    assign o_dc_v_factor_axis_tvalid = 1;
    assign o_phase_r_factor_axis_tvalid = 1;
    assign o_phase_s_factor_axis_tvalid = 1;
    assign o_phase_t_factor_axis_tvalid = 1;
    assign o_igbt_t_factor_axis_tvalid = 1;
    assign o_i_inductor_t_factor_axis_tvalid = 1;
    assign o_o_inductor_t_factor_axis_tvalid = 1;

    assign o_xintf_w_ram_we = 1;
    assign o_xintf_r_ram_we = 0;

	assign o_xintf_wf_ram_ce = 1;
	assign o_xintf_wf_ram_we = 1;

	assign o_set_c = set_c;
	assign o_set_v = set_v;

	assign o_dsp_status = dsp_status[4];

endmodule