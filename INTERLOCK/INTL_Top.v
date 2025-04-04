`timescale 1 ns / 1 ps

/*

MPS INTerLock Module
개발 4팀 전경원 차장

24.07.04 :	최초 생성

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - 

1. Initialize
 - 아닐 가능성 있음

 - o_en_dsp_boot : 1
 - o_sys_rst : 0
 - o_en_dsp_buf_ctrl : 0 (토글시켜줬으므로 AXI에서 입력해줘야하는 initial data는 0)
 - o_eeprom_rst : 1

*/

module INTL_Top #
(
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_WIDTH = 7
)
(
    // From MPS_Core_v1_0_Top
	
	// External Interlock Input
	// input i_intl_ext1,			// i_MILKI1
    // input i_intl_ext2,
    // input i_intl_ext3,
    // input i_intl_ext4,

	input [15:0] i_intl_ext,

	// External Interlock Output
	// output o_intl_ext1,			// o_nNILKO1
    // output o_intl_ext2,
    // output o_intl_ext3,
    // output o_intl_ext4,

	// H/W Interlock
	input i_intl_OC,			// 제어보드 Over Current (OC) i_MOCDETF
    input [3:0] i_pwm_fault,	// PWM Fault 신호 (PWM 1 Top, PWM 1 Bottom, ...)
    // input i_intl_OV,			// 전력보드 Over Voltage (OV) i_MPCHKS
    // input i_intl_OH,			// 전력보드 Over Heat (전력보드 TP202, Not Used) i_MOHSS

	// Reset
    input i_sys_rst_flag,		// Reset (RS232 DTR) i_nMONXRST
	output o_intl_OC_rst,		// 제어보드 Over Current (OC) RST o_nMCL0CF
	// output o_intl_POC_rst,		// 전력보드 Over Current (POC) RST o_MINOCMR

	// System Control
    output o_en_dsp_boot,		// DSP Boot Mode Select, ENSOMBT
	output o_sys_rst,			// System RST, ENSOMMR
	output o_en_dsp_buf_ctrl,	// DSP to ZYNQ Level Shift Block Control o_MENLLS
	output o_eeprom_rst,		// EEPROM RST o_WEMEEP

	// Trigger
	input i_ext_trg,			// External Trigger i_MEXTRG

	// ADC Raw Data
	input [31:0] i_c_data,
	input [31:0] i_v_data,
	input [31:0] i_dc_c_data,
	input [31:0] i_dc_v_data,
	input [31:0] i_phase_r_adc,
	input [31:0] i_phase_s_adc,
	input [31:0] i_phase_t_adc,
	input [31:0] i_igbt_t_adc,
	input [31:0] i_i_inductor_t_adc,
	input [31:0] i_o_inductor_t_adc,

	// Interlock State Out
	output [31:0] o_intl_state,
	
	// Interlock clear from MPS Core Top
	input i_intl_clr,
	input [31:0] i_c_sp_data,
	input [31:0] i_v_sp_data,

	// State
	output [2:0] o_osc_fsm_state,
	output [1:0] o_regu_fsm_state,

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

	wire [31:0] intl_ext_bypass;

	wire [31:0] intl_state;
	wire [31:0] intl_OC_p;			// OC Positive
	wire [31:0] intl_OC_n;			// OC Negative
	wire [31:0] intl_OV_p;			// OV Positive
	wire [31:0] intl_OV_n;			// OV Negative
	wire [31:0] intl_UV;			// Under Volt (DC-Link)
	wire mps_polarity;				// Unipolar / Bipolar

	wire intl_OSC_bypass;
	wire [31:0] c_intl_OSC_adc_threshold;
	wire [9:0] c_intl_OSC_count_threshold;
	wire [31:0] v_intl_OSC_adc_threshold;
	wire [9:0] v_intl_OSC_count_threshold;
	wire [19:0] intl_OSC_period;
	wire [9:0] intl_OSC_cycle_count;

	wire intl_REGU_mode;
	wire intl_REGU_bypass;
	wire [31:0] c_intl_REGU_diff;
	wire [31:0] c_intl_REGU_delay;
	wire [31:0] v_intl_REGU_diff;
	wire [31:0] v_intl_REGU_delay;

	wire en_dsp_buf_ctrl;
	
	wire [15:0] system_state_2;
	wire [15:0] ext_intl_state;

	AXI4_Lite_INTL #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_INTL
	(
		// Write (PS - PL)
		.o_intl_ext1(),
		.o_intl_ext2(),
		.o_intl_ext3(),
		.o_intl_ext4(),
		.o_intl_OC_rst(o_intl_OC_rst),
		.o_intl_POC_rst(),
		.o_intl_ext_bypass(intl_ext_bypass),

		.o_intl_OC_p(intl_OC_p),
        .o_intl_OC_n(intl_OC_n),
		.o_intl_OV_p(intl_OV_p),
        .o_intl_OV_n(intl_OV_n),
		.o_intl_UV(intl_UV),
        .o_mps_polarity(mps_polarity),
        
		.o_en_dsp_boot(o_en_dsp_boot),
		.o_sys_rst(o_sys_rst),
		.o_en_dsp_buf_ctrl(en_dsp_buf_ctrl),
		.o_eeprom_rst(o_eeprom_rst),

		.o_intl_OSC_bypass(intl_OSC_bypass),
		.o_c_intl_OSC_adc_threshold(c_intl_OSC_adc_threshold),
		.o_c_intl_OSC_count_threshold(c_intl_OSC_count_threshold),
		.o_v_intl_OSC_adc_threshold(v_intl_OSC_adc_threshold),
		.o_v_intl_OSC_count_threshold(v_intl_OSC_count_threshold),
		.o_intl_OSC_period(intl_OSC_period),
		.o_intl_OSC_cycle_count(intl_OSC_cycle_count),

		.o_intl_REGU_mode(intl_REGU_mode),
		.o_intl_REGU_bypass(intl_REGU_bypass),
		.o_c_intl_REGU_diff(c_intl_REGU_diff),
		.o_c_intl_REGU_delay(c_intl_REGU_delay),
		.o_v_intl_REGU_diff(v_intl_REGU_diff),
		.o_v_intl_REGU_delay(v_intl_REGU_delay),

		// Read (PL - PS)
		.i_intl_state(intl_state),
		.i_ext_trg(i_ext_trg),
		.i_ext_intl_state(ext_intl_state),

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

	INTL
	u_INTL
	(
		.i_clk(s00_axi_aclk),
		.i_rst(s00_axi_aresetn),
		
		.i_intl_clr(i_intl_clr),
		.i_mps_polarity(mps_polarity),

		.i_intl_ext(i_intl_ext),

		.i_intl_ext_bypass(intl_ext_bypass),

		.i_intl_OC(i_intl_OC),
		.i_pwm_fault(i_pwm_fault),
		// .i_intl_OV(i_intl_OV),
		// .i_intl_OH(i_intl_OH),

		.i_sys_rst_flag(i_sys_rst_flag),

		// .i_c_data(i_c_data),
		// .i_v_data(i_v_data),
		// .i_dc_c_data(i_dc_c_data),
		// .i_dc_v_data(i_dc_v_data),
		// .i_phase_r_adc(i_phase_r_adc),
		// .i_phase_s_adc(i_phase_s_adc),
		// .i_phase_t_adc(i_phase_t_adc),
		// .i_igbt_t_adc(i_igbt_t_adc),
		// .i_i_inductor_t_adc(i_i_inductor_t_adc),
		// .i_o_inductor_t_adc(i_o_inductor_t_adc),

		.i_dc_floating_data(i_dc_v_data),
		.i_c_floating_data(i_c_data),
		.i_v_floating_data(i_v_data),

		.i_intl_OC_p(intl_OC_p),
		.i_intl_OC_n(intl_OC_n),
		.i_intl_OV_p(intl_OV_p),
		.i_intl_OV_n(intl_OV_n),
		.i_intl_UV(intl_UV),

		.i_intl_OSC_bypass(intl_OSC_bypass),
		.i_c_intl_OSC_adc_threshold(c_intl_OSC_adc_threshold),
		.i_c_intl_OSC_count_threshold(c_intl_OSC_count_threshold),
		.i_v_intl_OSC_adc_threshold(v_intl_OSC_adc_threshold),
		.i_v_intl_OSC_count_threshold(v_intl_OSC_count_threshold),
		.i_intl_OSC_period(intl_OSC_period),
		.i_intl_OSC_cycle_count(intl_OSC_cycle_count),

		.i_intl_REGU_mode(intl_REGU_mode),
		.i_intl_REGU_bypass(intl_REGU_bypass),

		.i_c_intl_REGU_sp(i_c_sp_data),
		.i_c_intl_REGU_diff(c_intl_REGU_diff),
		.i_c_intl_REGU_delay(c_intl_REGU_delay),
		.i_v_intl_REGU_sp(i_v_sp_data),
		.i_v_intl_REGU_diff(v_intl_REGU_diff),
		.i_v_intl_REGU_delay(v_intl_REGU_delay),

		.o_intl_state(intl_state),
		.o_ext_intl_state(ext_intl_state),

		.o_osc_fsm_state(o_osc_fsm_state),
		.o_regu_fsm_state(o_regu_fsm_state)
    );

	assign o_intl_state = intl_state;
	assign o_en_dsp_buf_ctrl = ~en_dsp_buf_ctrl;

endmodule