`timescale 1 ns / 1 ps

/*

25.07.01 :	최초 생성

 - 100KHz 200_000개의 ADC 데이터를 Queue로 PS DDR4에 저장 (1초에 100_000개)
 - 원래는 100_000개였는데 PS에서 읽어가는 시간도 걸려서 그냥 2배로 넣음
 - 따라서 Low쪽 읽고 High쪽 읽고 번갈아가면서 PS에서 읽으면 됨. (이건 1st, 2nd irq로 처리)
 - Trigger와 상관없이 계속 동작함

 - Trigger는 실수값을 assign으로 비교해서 넘김
 - irq로 넘기는데 mode에 따라서 1, 0이 반전됨 (Rising, Falling Edge)
 - Trigger가 걸리는 순간 addr_cnt값이 저장됨 (Postmortem과 비슷)
 - PS에서는 irq가 들어오면 addr_cnt 값으로 알아서 데이터 가져가면 됨

 - Test Bench
	1. irq 동작 확인
	2. Trigger 관련 확인 (실수값 비교 포함)

 - Test
	1. DDR4 데이터 저장 확인
	2. Test Bench 꺼 확인

*/

module Osc_Top #
(
	parameter integer C_S_AXI_DATA_WIDTH = 5,								// AXI4-Lite Data Width
	parameter integer C_S_AXI_ADDR_NUM = 20,								// AXI4-Lite Slave Reg Number
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2		// AXI4-Lite Address
)
(
	input i_clk,
	input i_rst,

	input [31:0] i_c,
	input [31:0] i_v,
	input [31:0] i_dc_c,
	input [31:0] i_dc_v,

	output o_osc_1st_irq,
	output o_osc_2nd_irq,
	output o_osc_trg_irq,

	output [2:0] o_axi4_state,
	output [1:0] o_osc_state,

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
	input s00_axi_rready,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	// Write Address Channel
	output [3:0]	M_AXI_AWID,
	output [39:0] 	M_AXI_AWADDR,
	output [7:0] 	M_AXI_AWLEN,
	output [2:0] 	M_AXI_AWSIZE,
	output [1:0] 	M_AXI_AWBURST,
	output 			M_AXI_AWLOCK,
	output [3:0] 	M_AXI_AWCACHE,
	output [2:0] 	M_AXI_AWPROT,
	output [3:0] 	M_AXI_AWQOS,
	output [3:0] 	M_AXI_AWREGION,
	output [7:0]	M_AXI_AWUSER,
	output 			M_AXI_AWVALID,
	input 			M_AXI_AWREADY,

	// Write Data Channel
	output [63:0] 	M_AXI_WDATA,
	output [7:0] 	M_AXI_WSTRB,
	output 			M_AXI_WLAST,
	output [7:0]	M_AXI_WUSER,
	output 			M_AXI_WVALID,
	input 			M_AXI_WREADY,

	// Write Response Channel
	input [3:0]		M_AXI_BID,
	input [1:0] 	M_AXI_BRESP,
	input [7:0]		M_AXI_BUSER,
	input 			M_AXI_BVALID,
	output 			M_AXI_BREADY,

	// Read Address Channel
	output [3:0]	M_AXI_ARID,
	output [39:0] 	M_AXI_ARADDR,
	output [7:0] 	M_AXI_ARLEN,
	output [2:0] 	M_AXI_ARSIZE,
	output [1:0] 	M_AXI_ARBURST,
	output 			M_AXI_ARLOCK,
	output [3:0] 	M_AXI_ARCACHE,
	output [2:0] 	M_AXI_ARPROT,
	output [3:0] 	M_AXI_ARQOS,
	output [3:0] 	M_AXI_ARREGION,
	output [7:0]	M_AXI_ARUSER,
	output 			M_AXI_ARVALID,
	input 			M_AXI_ARREADY,

	// Read Data Channel
	input [3:0]		M_AXI_RID,
	input [63:0] 	M_AXI_RDATA,
	input [1:0] 	M_AXI_RRESP,
	input 			M_AXI_RLAST,
	input [7:0]		M_AXI_RUSER,
	input 			M_AXI_RVALID,
	output 			M_AXI_RREADY
);

	wire start;
	wire done;
	wire [39:0] ddr_addr;
	wire [63:0] ddr_data;
	wire [17:0] addr_cnt;

	wire [31:0] osc_trg_val;
	reg [17:0] osc_trg_cnt;
	wire [1:0] osc_trg_ch;
	wire osc_trg_mode;
	wire osc_trg_irq;

	wire [31:0] adc_buf;

	reg delay_reg;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			delay_reg <= 0;

		else
			delay_reg <= o_osc_trg_irq;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			osc_trg_cnt <= 0;

		else
			osc_trg_cnt <= (~delay_reg && o_osc_trg_irq) ? addr_cnt : osc_trg_cnt;
	end

	AXI4_Lite_Osc #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_Osc
	(
		.o_osc_trg_val(osc_trg_val),
		.o_osc_trg_ch(osc_trg_ch),
		.o_osc_trg_mode(osc_trg_mode),

		.i_osc_cnt(addr_cnt),
		.i_osc_trg_cnt(osc_trg_cnt),

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

	AXI4_Osc u_AXI4_Osc
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_start(start),
		.o_done(done),

		.i_ddr_addr(ddr_addr),
		.i_ddr_data(ddr_data),

		.o_state(o_axi4_state),

		.M_AXI_AWID(M_AXI_AWID),
		.M_AXI_AWADDR(M_AXI_AWADDR),
		.M_AXI_AWLEN(M_AXI_AWLEN),
		.M_AXI_AWSIZE(M_AXI_AWSIZE),
		.M_AXI_AWBURST(M_AXI_AWBURST),
		.M_AXI_AWLOCK(M_AXI_AWLOCK),
		.M_AXI_AWCACHE(M_AXI_AWCACHE),
		.M_AXI_AWPROT(M_AXI_AWPROT),
		.M_AXI_AWQOS(M_AXI_AWQOS),
		.M_AXI_AWREGION(M_AXI_AWREGION),
		.M_AXI_AWUSER(M_AXI_AWUSER),
		.M_AXI_AWVALID(M_AXI_AWVALID),
		.M_AXI_AWREADY(M_AXI_AWREADY),
		.M_AXI_WDATA(M_AXI_WDATA),
		.M_AXI_WSTRB(M_AXI_WSTRB),
		.M_AXI_WLAST(M_AXI_WLAST),
		.M_AXI_WUSER(M_AXI_WUSER),
		.M_AXI_WVALID(M_AXI_WVALID),
		.M_AXI_WREADY(M_AXI_WREADY),
		.M_AXI_BID(M_AXI_BID),
		.M_AXI_BRESP(M_AXI_BRESP),
		.M_AXI_BUSER(M_AXI_BUSER),
		.M_AXI_BVALID(M_AXI_BVALID),
		.M_AXI_BREADY(M_AXI_BREADY),
		.M_AXI_ARID(M_AXI_ARID),
		.M_AXI_ARADDR(M_AXI_ARADDR),
		.M_AXI_ARLEN(M_AXI_ARLEN),
		.M_AXI_ARSIZE(M_AXI_ARSIZE),
		.M_AXI_ARBURST(M_AXI_ARBURST),
		.M_AXI_ARLOCK(M_AXI_ARLOCK),
		.M_AXI_ARCACHE(M_AXI_ARCACHE),
		.M_AXI_ARPROT(M_AXI_ARPROT),
		.M_AXI_ARQOS(M_AXI_ARQOS),
		.M_AXI_ARREGION(M_AXI_ARREGION),
		.M_AXI_ARUSER(M_AXI_ARUSER),
		.M_AXI_ARVALID(M_AXI_ARVALID),
		.M_AXI_ARREADY(M_AXI_ARREADY),
		.M_AXI_RID(M_AXI_RID),
		.M_AXI_RDATA(M_AXI_RDATA),
		.M_AXI_RRESP(M_AXI_RRESP),
		.M_AXI_RLAST(M_AXI_RLAST),
		.M_AXI_RUSER(M_AXI_RUSER),
		.M_AXI_RVALID(M_AXI_RVALID),
		.M_AXI_RREADY(M_AXI_RREADY)
	);

	Osc_Handler u_Osc_Handler
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_c(i_c),
		.i_v(i_v),
		.i_dc_c(i_dc_c),
		.i_dc_v(i_dc_v),

		.o_start(start),
		.i_done(done),

		.o_ddr_addr(ddr_addr),
		.o_ddr_data(ddr_data),
		.o_addr_cnt(addr_cnt),

		.i_osc_trg_ch(osc_trg_ch),
		.o_adc_buf(adc_buf),

		.o_state(o_osc_state)
	);

	assign o_osc_1st_irq = (addr_cnt == 100000 - 1);
	assign o_osc_2nd_irq = (addr_cnt == 200000 - 1);

	assign osc_trg_irq = 	(adc_buf[31] != osc_trg_val[31]) ? (adc_buf[31] == 0) :			// 부호 비교. 부호가 다르고 A가 양수일 경우 1
							(adc_buf[31] == 0) ? 												// 둘다 양수
							((adc_buf[30:23] > osc_trg_val[30:23]) ? 1 :						// 지수 비교. A 지수가 더 크면 1
							(adc_buf[30:23] < osc_trg_val[30:23]) ? 0 : 						// A 지수가 더 작으면 0
							(adc_buf[22:0] > osc_trg_val[22:0]) ? 1 : 0)						// 가수 비교. 지수랑 같음
							:																	// 둘다 음수
							((adc_buf[30:23] < osc_trg_val[30:23]) ? 1 :						// 지수 비교. A 지수가 더 크면 1
							(adc_buf[30:23] > osc_trg_val[30:23]) ? 0 : 						// A 지수가 더 작으면 0
							(adc_buf[22:0] < osc_trg_val[22:0]) ? 1 : 0);						// 가수 비교. 지수랑 같음

	assign o_osc_trg_irq = (osc_trg_mode) ? osc_trg_irq : ~osc_trg_irq;

endmodule