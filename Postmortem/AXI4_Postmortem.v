`timescale 1ns / 1ps

module AXI4_Postmortem
(
	input i_clk,
	input i_rst,

	input i_start,
	output o_done,

	input [39:0] i_ddr_addr,
	input [63:0] i_ddr_data,

	output [2:0] o_state,

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

	localparam IDLE = 0;
	localparam ADDR = 1;
	localparam DATA = 2;
	localparam RESP = 3;
	localparam DONE = 4;

	reg [2:0] state;
	reg [2:0] n_state;

	reg awvalid_reg;
	reg wvalid_reg;
	reg bready_reg;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			state <= IDLE;
			
		else
			state <= n_state;
	end

	always @(*)
	begin
		n_state 	= state;
		awvalid_reg = 0;
		wvalid_reg 	= 0;
		bready_reg 	= 0;

		case (state)
			IDLE : n_state = (i_start) ? ADDR : IDLE;
			ADDR : begin awvalid_reg = 1;	n_state = (M_AXI_AWREADY) ? DATA : ADDR;	end
			DATA : begin wvalid_reg = 1;	n_state = (M_AXI_WREADY) ? RESP : DATA;		end
			RESP : begin bready_reg = 1;	n_state = (M_AXI_BVALID) ? DONE : RESP;		end
			DONE : n_state = IDLE;
			default:
				n_state = IDLE;
		endcase
	end

	assign o_state = state;
	assign o_done = (state == DONE);

	// AXI Write Address Channel Signals
	assign M_AXI_AWID 		= 0;
	assign M_AXI_AWADDR 	= i_ddr_addr;
	assign M_AXI_AWLEN 		= 8'h00; 		// 1 beat (AWLEN = Burst Length - 1)
	assign M_AXI_AWSIZE 	= 3'b011; 	// 8 Bytes (64-bit 데이터 버스)
	assign M_AXI_AWBURST 	= 2'b01; 		// INCR (증가) 버스트 타입
	assign M_AXI_AWLOCK 	= 1'b0;     // Normal access
	assign M_AXI_AWCACHE 	= 4'b0011;  // Normal Non-cacheable Bufferable
	assign M_AXI_AWPROT 	= 3'b000;   // Unprivileged, Secure, Data access
	assign M_AXI_AWQOS 		= 4'h0;
	assign M_AXI_AWREGION 	= 4'h0;
	assign M_AXI_AWUSER 	= 8'b0;
	assign M_AXI_AWVALID 	= awvalid_reg;

	// AXI Write Data Channel Signals
	assign M_AXI_WDATA 		= i_ddr_data;
	assign M_AXI_WSTRB 		= 8'hFF; 		// 8개의 모든 바이트 스트로브 활성화
	assign M_AXI_WLAST 		= wvalid_reg; 	// 단일 전송이므로, 데이터 전송 시 항상 LAST
	assign M_AXI_WUSER      = 8'b0;
	assign M_AXI_WVALID 	= wvalid_reg;

	// AXI Write Response Channel Signals
	assign M_AXI_BREADY 	= bready_reg;

	// AXI Read Channels (Unused) - 읽기 동작은 수행하지 않으므로 비활성화
	assign M_AXI_ARID 		= 0;
	assign M_AXI_ARADDR 	= 40'd0;
	assign M_AXI_ARLEN 		= 8'd0;
	assign M_AXI_ARSIZE 	= 3'b011;
	assign M_AXI_ARBURST 	= 2'b01;
	assign M_AXI_ARLOCK 	= 1'b0;
	assign M_AXI_ARCACHE 	= 4'b0011;
	assign M_AXI_ARPROT 	= 3'b000;
	assign M_AXI_ARQOS 		= 4'h0;
	assign M_AXI_ARREGION 	= 4'h0;
	assign M_AXI_ARUSER 	= 8'b0;
	assign M_AXI_ARVALID 	= 1'b0; // 항상 비활성화
	assign M_AXI_RREADY 	= 1'b0; // 항상 비활성화

endmodule