`timescale 1 ns / 1 ps

/*

BR MPS Core Module

개발 4팀 전경원 차장
개발 4팀 김선경 사원

24.09.10 :	최초 생성

24.09.24 :	WF 삭제. 다른 IP로 이동. WF_Counter(wf_read_cnt)는 존재함
			DSP에서 DPBRAM으로 해당 Count값이 오기 때문임
			WF Count 값 Output 생성. WF IP로 전달

1. 개요
 - 기존의 DSP_v1_0을 대체함
 - DSP와 Zynq간 Handler
 - SFP Control 구현 (AXI4_Lite에 포함)
 - Slave는 최대 3개까지 구현을 하였으며 추가가 될 경우 DSP에서 보내는 PI Parameter의 Protocol을 수정해야하며 나머지는 수정없이 적용 가능하다.
 - ADC, DSP Control Data, SFP
 - Protocol 및 데이터 등은 구글 시트를 참조한다.

2. DSP
 - DSP와의 통신은 DPBRAM을 이용한다.
 - Read와 Write용 DPBRAM을 구분하여 DSP to Zynq, Zynq to DSP를 별도로(2가지 FSM) 관리한다.
 - 기존 코드와 다르게 주기적(100KHz)으로 데이터를 교체하는 것이 아닌 실시간으로 데이터를 입력한다.
 - SFP Master(sfp_m_en)일 경우에만 Write FSM이 동작한다.

3. SFP
 - AXI4_Lite_S01.v에 포함되어있다.
 - PS가 Master 및 Slave를 선택(sfp_id)하며 Slave시 장비의 번호(slv_id)를 지정하여야 한다.
 - 총 4개의 FSM으로 구성되어 있으며 Master와 Slave 별 R/W로 구성된다. (M_TX, M_RX, S_TX, S_RX)
 
 3.1 Master
  3.1.1 TX
   - Master TX의 경우 2가지 타입으로 전송된다.
   - PS에서 각 Slave별로 다양한 Parameter를 보내며
   - DSP에서 전체 Slave로 PI 제어용 Parameter를 보낸다.

  3.1.2 RX
   - 각 Slave가 보내는 데이터를 처리한다.
   - CMD 영역이 0x000F일 경우에만 데이터를 PS로 보내주며
   - 나머지는 무시한다.

 3.2 Slave
  3.2.1 TX
   - Slave의 TX도 2가지 타입으로 전송된다.
   - 본 장비의 데이터가 아닐 경우 다른 장비로 전송되는 PASS 신호와
   - 주기적(1us)으로 보내는 상태값 및 I, V 값으로 구성된다.
   - PASS의 신호는 Slave RX에서 명령(S_RX_PASS)을 받는다.

  3.2.2 RX
   - RX의 경우에는 본 장비의 데이터일 경우 데이터를 적용(S_RX_INSERT)한다.
   - 데이터의 적용은 AXI4_Lite를 대신해서 값을 적용한다는 개념이다.
   - Master의 DSP가 각 Slave의 PI제어 값(i_slave_pi_param_x)을 연산하기 때문에 Set값이나 Gain값은 무시된다.
   - 만약 본 장비의 데이터가 아닐 경우 다른 장비로 전달(S_RX_PASS)한다.

4. AXI4-Lite
 - Slave Reg의 수가 많아져서 배열로 수정함.
 - 내부적으로 사용되는 ADDR_LSB 및 OPT_MEM_ADDR_BITS 등도 함께 수정하였음
 - 자세한건 Custom IP의 AXI4_Lite_Array 파일 주석 참조

*/
module MPS_Core_Top #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,								// AXI4-Lite Data Width
	parameter integer C_S_AXI_ADDR_NUM = 128,								// AXI4-Lite Slave Reg Number
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2,	// AXI4-Lite Address

	parameter integer C_AXIS_TDATA_WIDTH = 64,								// Frame Data Width (Aurora 64B/66B)
	parameter integer C_NUMBER_OF_FRAME = 2,								// Slave?쓽 Frame ?닔

	parameter integer C_DATA_FRAME_BIT = ((C_AXIS_TDATA_WIDTH) * (C_NUMBER_OF_FRAME))	// ?쟾泥? Frame Bit ?닔
)
(
	input [31:0] i_zynq_intl,					// Interlock Input. from INTL IP
	input i_w_ready,							// Write Ready by DSP. to DSP (MXTMP4)
	output o_nMENPWM,							// PWM Enable. to INTL IP
	output o_w_valid,							// Write Valid to DSP. to DSP (MXTMP3)
	input i_tx_en,								// from AXIS FRAME IP
	output [31:0] o_wf_read_cnt,				// Waveform Read Count. to WF IP
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

    // Factor AXIS
	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_c_factor_axis_tdata,
	output o_c_factor_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] o_v_factor_axis_tdata,
	output o_v_factor_axis_tvalid,

	/////////////////////////////////////////////////////////
	// SFP Data
	output [383:0] o_sfp_tx_data,
	input [383:0] i_sfp_rx_data,
	
	// SFP Flag
	output o_sfp_tx_start_flag,					// SFP Tx ?떆?옉
	input i_sfp_rx_end_flag,					// SFP Rx 醫낅즺
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

	output o_intl_clr,

	output [31:0] o_set_c,
	output [31:0] o_set_v,
	output [31:0] o_c_adc,
	output [31:0] o_v_adc,
	output [31:0] o_dc_c_adc,
	output [31:0] o_dc_v_adc,
	output [31:0] o_phase_r_adc,
	output [31:0] o_phase_s_adc,
	output [31:0] o_phase_t_adc,
	output [31:0] o_igbt_t_adc,
	output [31:0] o_i_inductor_t_adc,
	output [31:0] o_o_inductor_t_adc,

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

    wire [31:0] d_gain_c;
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
    
    wire o_hw_pwm_en;

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

	AXI4_Lite_MPS_Core #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),

		.C_DATA_FRAME_BIT(C_DATA_FRAME_BIT)
	)
	u_AXI4_Lite_MPS_Core
	(
		// ADC Calc Factor
		.o_c_factor(o_c_factor_axis_tdata),
		.o_v_factor(o_v_factor_axis_tdata),

		// ADC Data
		.i_c_adc_data(c_adc_s_axis_tdata),
        .i_v_adc_data(v_adc_s_axis_tdata),
		
		// DPBRAM Write
        .o_write_index(write_index),
		.o_index_data(index_data),
		.o_zynq_status(zynq_status),
        .o_set_c(set_c),
        .o_write_index_flag(write_index_flag),
		.o_max_duty(max_duty),
		.o_max_phase(max_phase),
		.o_max_freq(max_freq),
		.o_min_freq(min_freq),
		.o_set_v(set_v),
		.o_slave_count(slave_count),
		.o_slave_1_ram_cs(slave_1_ram_cs),
		.o_slave_1_ram_addr(slave_1_ram_addr),
		.o_slave_2_ram_cs(slave_2_ram_cs),
		.o_slave_2_ram_addr(slave_2_ram_addr),
		.o_slave_3_ram_cs(slave_3_ram_cs),
		.o_slave_3_ram_addr(slave_3_ram_addr),
		.o_axi_pwm_en(axi_pwm_en),

		// DPBRAM Read
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
		.i_dsp_pi_param(dsp_pi_param),
		.i_slave_c(slave_c),
		.i_slave_v(slave_v),
		.i_slave_status(slave_status),
		.i_dsp_status(dsp_status),
		.i_dc_adc_data(sub_adc_4_s_axis_tdata),
		.i_dsp_ver(dsp_ver),
		.i_slave_1_ram_data(slave_1_ram_data),
		.i_slave_2_ram_data(slave_2_ram_data),
		.i_slave_3_ram_data(slave_3_ram_data),

		// SFP Data
		.i_sfp_c_factor(sfp_c_factor),
		.i_sfp_v_factor(sfp_v_factor),
		.i_sfp_max_duty(sfp_max_duty),
		.i_sfp_max_phase(sfp_max_phase),
		.i_sfp_max_freq(sfp_max_freq),
		.i_sfp_min_freq(sfp_min_freq),
		.o_axi_data_valid(axi_data_valid),

		/////////////////////////////////////////////////////////
		.o_sfp_en(sfp_en),
		.o_sfp_id(sfp_id),

		.i_sfp_cmd(sfp_cmd),
		.i_sfp_data_1(sfp_data_1),
		.i_sfp_data_2(sfp_data_2),
		.i_sfp_data_3(sfp_data_3),

		.o_m_sfp_1_cmd(m_zynq_sfp_1_cmd),
		.o_m_sfp_1_data(m_sfp_1_data),

		.o_m_sfp_2_cmd(m_zynq_sfp_2_cmd),
		.o_m_sfp_2_data(m_sfp_2_data),

		.o_m_sfp_3_cmd(m_zynq_sfp_3_cmd),
		.o_m_sfp_3_data(m_sfp_3_data),

		.i_s_sfp_1_cmd(s_sfp_1_cmd),
		.i_s_sfp_1_data_1(s_sfp_1_data_1),
		.i_s_sfp_1_data_2(s_sfp_1_data_2),
		.i_s_sfp_1_data_3(s_sfp_1_data_3),

		.i_s_sfp_2_cmd(s_sfp_2_cmd),
		.i_s_sfp_2_data_1(s_sfp_2_data_1),
		.i_s_sfp_2_data_2(s_sfp_2_data_2),
		.i_s_sfp_2_data_3(s_sfp_2_data_3),

		.i_s_sfp_3_cmd(s_sfp_3_cmd),
		.i_s_sfp_3_data_1(s_sfp_3_data_1),
		.i_s_sfp_3_data_2(s_sfp_3_data_2),
		.i_s_sfp_3_data_3(s_sfp_3_data_3),
		/////////////////////////////////////////////////////////

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
		.i_axi_pwm_en(axi_pwm_en),

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
        .i_c_adc_data(c_adc_s_axis_tdata),
        .i_v_adc_data(v_adc_s_axis_tdata),
        .i_zynq_status(zynq_status),
		.i_write_index(write_index),
		.i_index_data(index_data),
		.i_set_c(set_c),
		.i_max_duty(max_duty),
		.i_max_phase(max_phase),
		.i_max_freq(max_freq),
		.i_min_freq(min_freq),
		.i_set_v(set_v),
		.i_master_pi_param(sfp_data_1),			// Master PI Parameter Send to DSP (SFP Slave Mode)
        .i_write_index_flag(write_index_flag),
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
		.o_wf_read_cnt(o_wf_read_cnt),
		.o_dsp_status(dsp_status),
		.o_dsp_cmd(m_dsp_sfp_cmd),
		.o_dsp_ver(dsp_ver),
		
		.s_zynq_intl(s_zynq_intl),
		// System Control
		.o_hw_pwm_en(o_hw_pwm_en),
		.o_intl_clr(o_intl_clr),

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
		.i_sfp_set_v(sfp_set_v)
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
		.i_slv_state(s_zynq_intl),						// Slave Mode MPS Status
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

    assign o_c_factor_axis_tvalid = 1;
    assign o_v_factor_axis_tvalid = 1;

    assign o_xintf_w_ram_we = 1;
    assign o_xintf_r_ram_we = 0;

	assign o_xintf_wf_ram_ce = 1;
	assign o_xintf_wf_ram_we = 1;
	
	assign o_nMENPWM = o_hw_pwm_en;
	assign o_set_c = set_c;
	assign o_set_v = set_v;

	assign o_c_adc = c_adc_s_axis_tdata;
	assign o_v_adc = v_adc_s_axis_tdata;
	assign o_dc_c_adc = sub_adc_4_s_axis_tdata;
	assign o_dc_v_adc = sub_adc_0_s_axis_tdata;
	assign o_phase_r_adc = sub_adc_1_s_axis_tdata;
	assign o_phase_s_adc = sub_adc_2_s_axis_tdata;
	assign o_phase_t_adc = sub_adc_3_s_axis_tdata;
	assign o_igbt_t_adc = sub_adc_5_s_axis_tdata;
	assign o_i_inductor_t_adc = sub_adc_6_s_axis_tdata;
	assign o_o_inductor_t_adc = sub_adc_7_s_axis_tdata;
	
endmodule