`timescale 1 ns / 1 ps

/*

BR MPS System Module

개발 2팀 전경원 부장

25.04.03 :	최초 생성

1. 개요
 - MPS FSM
 - MPS I/F

 System Off - System On - RUN - INTL - 

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

	input [16:0] i_analog_intl,
	output o_pwm_en,

	input [31:0] i_dc_v,
	input [15:0] i_ext_di,
	output [7:0] o_ext_do,
	input [3:0] i_pwm_fault,
	input i_intl_OC,

	output o_intl_clr,
	input i_sys_rst_flag,
	output o_en_dsp_boot,
	output o_sys_rst,
	output o_intl_OC_rst,

	output [2:0] o_mps_fsm_m,
	output [3:0] o_op_on_state,
	output [3:0] o_op_off_state,

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

	wire [4:0] ext_do;

	reg intl_flag;

	wire op_on;
	wire run;
	wire ready;
	wire op_off;
	wire op_on_flag;
	wire op_off_flag;
	wire [2:0] mc;

	wire [3:0] op_on_fail_buf;
	wire [3:0] op_on_fsm;
	wire [3:0] op_off_fsm;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			intl_flag <= 0;

		else
			intl_flag <= ((|i_analog_intl) || (i_ext_di[0]) || (|i_ext_di[8:4]));
	end

	AXI4_Lite_MPS_System #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_MPS_System
	(
		.o_op_on		(op_on),
		.o_run			(run),
		.o_ready		(ready),
		.o_op_off		(op_off),
		.o_ext_do		(ext_do),

		.i_pwm_en		(o_pwm_en),
		.i_ext_di		(i_ext_di),
		.i_analog_intl	(i_analog_intl),
		.i_mps_fsm_m	(o_mps_fsm_m),
		.i_op_on_fsm	(op_on_fsm),
		.i_op_off_fsm	(op_off_fsm),
		.i_on_state_fail_buf(op_on_fail_buf),
		.i_mc			(mc),

		.o_intl_clr		(o_intl_clr),
		.i_sys_rst_flag	(i_sys_rst_flag),
		.o_en_dsp_boot	(o_en_dsp_boot),
		.o_sys_rst		(o_sys_rst),
		.o_intl_OC_rst	(o_intl_OC_rst),

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

	MPS_System_FSM u_MPS_System_FSM
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_op_on(op_on),
		.i_run(run),
		.i_ready(ready),
		.i_op_off(op_off),
		.o_mps_fsm_m(o_mps_fsm_m),
		.i_op_on_fsm(op_on_fsm),
		.i_op_off_fsm(op_off_fsm),

		.i_intl_flag(intl_flag),
		.o_op_on_flag(op_on_flag),
		.o_op_off_flag(op_off_flag),

		.o_mc(mc),
		.o_pwm_en(o_pwm_en)
	);

	MPS_Operation_FSM u_MPS_Operation_FSM
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_op_on_flag(op_on_flag),
		.i_op_off_flag(op_off_flag),
		.i_op_intl(intl_flag),

		.i_dc_v(i_dc_v),
		.i_ext_di(i_ext_di),
		
		.o_on_state_fail_buf(op_on_fail_buf),
		.o_on_state(op_on_fsm),
		.o_off_state(op_off_fsm)
	);

	assign o_op_on_state = op_on_fsm;
	assign o_op_off_state = op_off_fsm;
	assign o_ext_do = {ext_do, mc};

endmodule