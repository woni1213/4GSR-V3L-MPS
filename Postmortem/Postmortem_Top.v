`timescale 1 ns / 1 ps

/*

BR MPS Postmortem Module
개발 2팀 전경원 부장

25.06.10 :	최초 생성

*/
module Postmortem_Top #
(
	parameter integer C_S_AXI_DATA_WIDTH = 32,								// AXI4-Lite Data Width
	parameter integer C_S_AXI_ADDR_NUM = 12,								// AXI4-Lite Slave Reg Number
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2		// AXI4-Lite Address
)
(
	input i_clk,
	input i_rst,

	input [31:0] i_c,
	input [31:0] i_v,
	input [31:0] i_dc_c,
	input [31:0] i_dc_v,
	input [31:0] i_igbt_t,
	input [31:0] i_i_inductor_t,
	input [31:0] i_o_inductor_t,
	input [31:0] i_phase_rms_r,
	input [31:0] i_phase_rms_s,
	input [31:0] i_phase_rms_t,

	input i_intl_flag,

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

	reg [15:0] w_cnt;
	reg [15:0] w_ram_addr;

	wire [15:0] r_ram_addr;
	wire [31:0] r_curr_ram_data;
	wire [31:0] r_volt_ram_data;
	wire [31:0] r_dc_c_ram_data;
	wire [31:0] r_dc_v_ram_data;
	wire [31:0] r_igbt_ram_data;
	wire [31:0] r_i_idt_ram_data;
	wire [31:0] r_o_idt_ram_data;
	wire [31:0] r_rms_r_ram_data;
	wire [31:0] r_rms_s_ram_data;
	wire [31:0] r_rms_t_ram_data;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			w_cnt <= 0;

		else
			w_cnt <= ((w_cnt < 50000 - 1) && (~i_intl_flag)) ? w_cnt + 1 : 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			w_ram_addr <= 0;

		else
			w_ram_addr <= (w_cnt == 50000 - 1) ? ((w_ram_addr == 50000 - 1) ? 0 : w_ram_addr + 1) : w_ram_addr;
	end

	AXI4_Lite_MPS_System #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_MPS_System
	(
		.o_r_ram_addr(r_ram_addr),
		.i_w_ram_addr(w_ram_addr),
		
		.i_r_curr_ram_data(r_curr_ram_data),
		.i_r_volt_ram_data(r_volt_ram_data),
		.i_r_dc_c_ram_data(r_dc_c_ram_data),
		.i_r_dc_v_ram_data(r_dc_v_ram_data),
		.i_r_igbt_ram_data(r_igbt_ram_data),
		.i_r_i_idt_ram_data(r_i_idt_ram_data),
		.i_r_o_idt_ram_data(r_o_idt_ram_data),
		.i_r_rms_r_ram_data(r_rms_r_ram_data),
		.i_r_rms_s_ram_data(r_rms_s_ram_data),
		.i_r_rms_t_ram_data(r_rms_t_ram_data),

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

	Postmortem_DPBRAM u_DPBRAM_C
	(
		.i_clk(i_clk),

		.s_addr(w_ram_addr),
		.s_ce(~i_intl_flag),
		.s_we(1),
		.s_din(i_c),
		.s_dout(),

		.m_addr(r_ram_addr),
		.m_ce(1),
		.m_we(0),
		.m_din(0),
		.m_dout(r_curr_ram_data)
	);

	Postmortem_DPBRAM u_DPBRAM_V
	(
		.i_clk(i_clk),

		.s_addr(w_ram_addr),
		.s_ce(~i_intl_flag),
		.s_we(1),
		.s_din(i_v),
		.s_dout(),

		.m_addr(r_ram_addr),
		.m_ce(1),
		.m_we(0),
		.m_din(0),
		.m_dout(r_volt_ram_data)
	);

	Postmortem_DPBRAM u_DPBRAM_DC_C
	(
		.i_clk(i_clk),

		.s_addr(w_ram_addr),
		.s_ce(~i_intl_flag),
		.s_we(1),
		.s_din(i_dc_c),
		.s_dout(),

		.m_addr(r_ram_addr),
		.m_ce(1),
		.m_we(0),
		.m_din(0),
		.m_dout(r_dc_c_ram_data)
	);

	Postmortem_DPBRAM u_DPBRAM_DC_V
	(
		.i_clk(i_clk),

		.s_addr(w_ram_addr),
		.s_ce(~i_intl_flag),
		.s_we(1),
		.s_din(i_dc_v),
		.s_dout(),

		.m_addr(r_ram_addr),
		.m_ce(1),
		.m_we(0),
		.m_din(0),
		.m_dout(r_dc_v_ram_data)
	);

	Postmortem_DPBRAM u_DPBRAM_IGBT
	(
		.i_clk(i_clk),

		.s_addr(w_ram_addr),
		.s_ce(~i_intl_flag),
		.s_we(1),
		.s_din(i_igbt_t),
		.s_dout(),

		.m_addr(r_ram_addr),
		.m_ce(1),
		.m_we(0),
		.m_din(0),
		.m_dout(r_igbt_ram_data)
	);

	Postmortem_DPBRAM u_DPBRAM_I_IDT
	(
		.i_clk(i_clk),

		.s_addr(w_ram_addr),
		.s_ce(~i_intl_flag),
		.s_we(1),
		.s_din(i_i_inductor_t),
		.s_dout(),

		.m_addr(r_ram_addr),
		.m_ce(1),
		.m_we(0),
		.m_din(0),
		.m_dout(r_i_idt_ram_data)
	);

	Postmortem_DPBRAM u_DPBRAM_O_IDT
	(
		.i_clk(i_clk),

		.s_addr(w_ram_addr),
		.s_ce(~i_intl_flag),
		.s_we(1),
		.s_din(i_o_inductor_t),
		.s_dout(),

		.m_addr(r_ram_addr),
		.m_ce(1),
		.m_we(0),
		.m_din(0),
		.m_dout(r_o_idt_ram_data)
	);

	Postmortem_DPBRAM u_DPBRAM_RMS_R
	(
		.i_clk(i_clk),

		.s_addr(w_ram_addr),
		.s_ce(~i_intl_flag),
		.s_we(1),
		.s_din(i_phase_rms_r),
		.s_dout(),

		.m_addr(r_ram_addr),
		.m_ce(1),
		.m_we(0),
		.m_din(0),
		.m_dout(r_rms_r_ram_data)
	);

	Postmortem_DPBRAM u_DPBRAM_RMS_S
	(
		.i_clk(i_clk),

		.s_addr(w_ram_addr),
		.s_ce(~i_intl_flag),
		.s_we(1),
		.s_din(i_phase_rms_s),
		.s_dout(),

		.m_addr(r_ram_addr),
		.m_ce(1),
		.m_we(0),
		.m_din(0),
		.m_dout(r_rms_s_ram_data)
	);

	Postmortem_DPBRAM u_DPBRAM_RMS_T
	(
		.i_clk(i_clk),

		.s_addr(w_ram_addr),
		.s_ce(~i_intl_flag),
		.s_we(1),
		.s_din(i_phase_rms_t),
		.s_dout(),

		.m_addr(r_ram_addr),
		.m_ce(1),
		.m_we(0),
		.m_din(0),
		.m_dout(r_rms_t_ram_data)
	);

endmodule