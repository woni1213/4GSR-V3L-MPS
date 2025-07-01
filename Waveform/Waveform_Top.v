`timescale 1 ns / 1 ps

/*

25.07.01 :	최초 생성

 - PS에서 Waveform BRAM에 100000개의 데이터 저장
 - 저장된 데이터는 Waveform Mode 시 DSP_Handler의 Set Point에 바로 값 보내줌
 - 보내주는 주기는 DSP Handler의 W_SETUP임 (i_wf_set_flag)
 - Waveform Mode는 o_wf_en[0], CV / CC는 o_wf_en[1]
 - Waveform Mode 시 BRAM의 마지막 데이터로 Set Point 값 계속 유지
 - Waveform 시작은 i_wf_trg로 시작 (외부 External Trigger. XDC로 Port 뚫어줘야함)
 - 만약 저장하는 데이터가 100000개 이하면 나머지 BRAM의 공간에는 필요한 값의 마지막 값으로 BRAM 데이터를 다 채워야함
 - Waveform 시작 중 100000개에 도달하지 못했는 경우에 Trigger가 입력되면 다시 0부터 시작해야함
 - 100000개가 다 동작한 후에는 마지막 데이터로 계속 유지되야함 (Trigger 입력 전까지 계속)

 - Test Bench는
	1. BRAM 데이터 저장 유무
	2. i_wf_trg 동작 유무 및 동작 중 해당 신호가 다시 동작하는 경우 0부터 시작하는지 유무
	3. wf_cnt 증가 및 Overflow 확인
	4. wf_cnt 100000번 후 마지막 데이터 유지하는지 확인

 - Test는 Test Bench꺼 그대로 다시 확인

*/

module Waveform_Top #
(
	parameter integer C_S_AXI_DATA_WIDTH = 32,								// AXI4-Lite Data Width
	parameter integer C_S_AXI_ADDR_NUM = 5,									// AXI4-Lite Slave Reg Number
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2		// AXI4-Lite Address
)
(
	input i_clk,
	input i_rst,

	input i_wf_trg,						// External Trigger
	input i_wf_set_flag,				// MPS Core
	output [1:0] o_wf_en,				// MNPS_Core, 01 : C, 11 : V
	output [31:0] o_wf_sp,				// MPS Core

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
	wire [16:0] s_addr;
	wire s_ce;
	wire [31:0] s_din;

	reg delay_reg;
	reg [16:0] wf_cnt;
	wire wf_trg;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			delay_reg <= 0;

		else
			delay_reg <= i_wf_trg;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			wf_cnt <= 100000 - 1;

		else if (wf_trg)
			wf_cnt <= 0;

		else if ((i_wf_set_flag) && (wf_cnt < 100000 - 1))
			wf_cnt <= wf_cnt + 1;

		else
			wf_cnt <= wf_cnt;
	end

	AXI4_Lite_Waveform #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_Waveform
	(
		.o_s_addr(s_addr),
		.o_s_ce(s_ce),
		.o_s_din(s_din),

		.o_wf_en(o_wf_en),
		.i_wf_cnt(wf_cnt),

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

	DPBRAM_Single_Clock #
	(
		.DWIDTH(32),
		.RAM_DEPTH(10000)
	)
	u_DPBRAM_Single_Clock
	(
		.s_addr(s_addr),
		.s_ce(s_ce),
		.s_we(1),
		.s_din(s_din),
		.s_dout(),

		.m_addr(wf_cnt),
		.m_ce(o_wf_en[0]),
		.m_we(0),
		.m_din(0),
		.m_dout(o_wf_sp)
	);

	assign wf_trg = (~delay_reg && i_wf_trg);

endmodule