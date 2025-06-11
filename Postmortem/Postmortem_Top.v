`timescale 1 ns / 1 ps

/*

BR MPS Postmortem Module
개발 2팀 전경원 부장

25.06.10 :	최초 생성

*/
module Postmortem_Top
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

	output [39:0] o_ddr_addr_pointer,

	output [2:0] o_state,

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

	AXI4_Postmortem u_AXI4_Postmortem
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_start(start),
		.o_done(done),

		.i_ddr_addr(ddr_addr),
		.i_ddr_data(ddr_data),

		.o_state(o_state),

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

	Postmortem_Handler u_Postmortem_Handler
	(
		.i_clk(i_clk),
		.i_rst(i_rst),
		
		.i_c(i_c),
		.i_v(i_v),
		.i_dc_c(i_dc_c),
		.i_dc_v(i_dc_v),
		.i_igbt_t(i_igbt_t),
		.i_i_inductor_t(i_i_inductor_t),
		.i_o_inductor_t(i_o_inductor_t),
		.i_phase_rms_r(i_phase_rms_r),
		.i_phase_rms_s(i_phase_rms_s),
		.i_phase_rms_t(i_phase_rms_t),

		.i_intl_flag(i_intl_flag),
		.o_start(start),
		.i_done(done),

		.o_ddr_addr(ddr_addr),
		.o_ddr_data(ddr_data)
	);

	assign o_ddr_addr_pointer = ddr_addr;

endmodule