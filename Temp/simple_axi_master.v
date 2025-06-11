`timescale 1ns / 1ps

module simple_axi_master
(
	// System Signals
	input 								ACLK,
	input 								ARESETn,

	// User Interface
	output 								done,        // 쓰기 완료 신호
	output [2:0] state,

	// =================================================================
	// == AXI4 Master Interface
	// =================================================================

	// Write Address Channel
	output [3:0]						M_AXI_AWID,
	output [39:0] 						M_AXI_AWADDR,
	output [7:0] 						M_AXI_AWLEN,
	output [2:0] 						M_AXI_AWSIZE,
	output [1:0] 						M_AXI_AWBURST,
	output 								M_AXI_AWLOCK,
	output [3:0] 						M_AXI_AWCACHE,
	output [2:0] 						M_AXI_AWPROT,
	output [3:0] 						M_AXI_AWQOS,
	output [3:0] 						M_AXI_AWREGION,
	output 								M_AXI_AWUSER,
	output 								M_AXI_AWVALID,
	input 								M_AXI_AWREADY,

	// Write Data Channel
	output [63:0] 						M_AXI_WDATA,
	output [7:0] 						M_AXI_WSTRB,
	output 								M_AXI_WLAST,
	output 								M_AXI_WUSER,
	output 								M_AXI_WVALID,
	input 								M_AXI_WREADY,

	// Write Response Channel
	input [3:0]							M_AXI_BID,
	input [1:0] 						M_AXI_BRESP,
	input 								M_AXI_BUSER,
	input 								M_AXI_BVALID,
	output 								M_AXI_BREADY,

	// Read Address Channel
	output [3:0]						M_AXI_ARID,
	output [39:0] 						M_AXI_ARADDR,
	output [7:0] 						M_AXI_ARLEN,
	output [2:0] 						M_AXI_ARSIZE,
	output [1:0] 						M_AXI_ARBURST,
	output 								M_AXI_ARLOCK,
	output [3:0] 						M_AXI_ARCACHE,
	output [2:0] 						M_AXI_ARPROT,
	output [3:0] 						M_AXI_ARQOS,
	output [3:0] 						M_AXI_ARREGION,
	output 								M_AXI_ARUSER,
	output 								M_AXI_ARVALID,
	input 								M_AXI_ARREADY,

	// Read Data Channel
	input [3:0]							M_AXI_RID,
	input [63:0] 						M_AXI_RDATA,
	input [1:0] 						M_AXI_RRESP,
	input 								M_AXI_RLAST,
	input 								M_AXI_RUSER,
	input 								M_AXI_RVALID,
	output 								M_AXI_RREADY
);

	// =================================================================
	// == 파라미터: 원하시는 DDR 주소와 데이터를 여기에 설정하십시오.
	// =================================================================
	parameter TARGET_ADDR = 40'h00_2000_0000; // 예시: DDR 주소 0x2000_0000
	// parameter WRITE_DATA  = 64'hDEADBEEF_12345678; // 예시: 쓸 데이터
	parameter MASTER_ID   = 4'b0;                 // AXI 마스터 ID

	// FSM 상태 정의
	localparam S_IDLE 		= 3'd0;
	localparam S_WRITE_ADDR = 3'd1;
	localparam S_WRITE_DATA = 3'd2;
	localparam S_WRITE_RESP = 3'd3;
	localparam S_FINISH 	= 3'd4;

	reg [2:0] current_state, next_state;

	reg [31:0] start_write_cnt;
	wire start_write;
	reg [63:0] WRITE_DATA;

	// 내부 레지스터
	reg awvalid_reg;
	reg wvalid_reg;
	reg bready_reg;
	reg done_reg;

	// FSM의 순차 로직 (State Register)
	always @(posedge ACLK)
	begin
		if (!ARESETn)
			current_state <= S_IDLE;
			
		else
			current_state <= next_state;
	end

	// FSM의 조합 로직 (Next State Logic & Output Logic)
	always @(*)
	begin
		// 모든 레지스터의 기본값을 0으로 설정
		next_state 	= current_state;
		awvalid_reg = 0;
		wvalid_reg 	= 0;
		bready_reg 	= 0;
		done_reg 	= 0;

		case (current_state)
			S_IDLE:
			begin
				if (start_write)
					next_state = S_WRITE_ADDR;
			end

			S_WRITE_ADDR:
			begin
				awvalid_reg = 1;
				if (M_AXI_AWREADY)
					next_state = S_WRITE_DATA;
			end

			S_WRITE_DATA:
			begin
				wvalid_reg = 1;
				if (M_AXI_WREADY)
					next_state = S_WRITE_RESP;
			end

			S_WRITE_RESP:
			begin
				bready_reg = 1;
				// ID 일치 여부 확인 (본 예제에서는 단순화를 위해 생략)
				if (M_AXI_BVALID)
					next_state = S_FINISH;
			end

			S_FINISH:
			begin
				done_reg = 1;
				next_state = S_IDLE; // 한 번의 쓰기 완료 후 IDLE 상태로 복귀
			end

			default:
				next_state = S_IDLE;
		endcase
	end

	always @(posedge ACLK)
	begin
		if (!ARESETn)
			start_write_cnt <= 0;

		else
			start_write_cnt <= (start_write_cnt < 200_000_000 - 1) ? start_write_cnt + 1 : 0;
	end

	always @(posedge ACLK)
	begin
		if (!ARESETn)
			WRITE_DATA <= 0;

		else
			WRITE_DATA <= (start_write) ? WRITE_DATA + 1 : WRITE_DATA;
	end

	assign start_write = (start_write_cnt == 200_000_000 - 1);
	assign state = current_state;

	// 출력 신호 할당
	assign done = done_reg;

	// AXI Write Address Channel Signals
	assign M_AXI_AWID 		= MASTER_ID;
	assign M_AXI_AWADDR 	= TARGET_ADDR;
	assign M_AXI_AWLEN 		= 8'h00; 		// 1 beat (AWLEN = Burst Length - 1)
	assign M_AXI_AWSIZE 	= 3'b011; 	// 8 Bytes (64-bit 데이터 버스)
	assign M_AXI_AWBURST 	= 2'b01; 		// INCR (증가) 버스트 타입
	assign M_AXI_AWLOCK 	= 1'b0;     // Normal access
	assign M_AXI_AWCACHE 	= 4'b0011;  // Normal Non-cacheable Bufferable
	assign M_AXI_AWPROT 	= 3'b000;   // Unprivileged, Secure, Data access
	assign M_AXI_AWQOS 		= 4'h0;
	assign M_AXI_AWREGION 	= 4'h0;
	assign M_AXI_AWUSER 	= 1'b0;
	assign M_AXI_AWVALID 	= awvalid_reg;

	// AXI Write Data Channel Signals
	assign M_AXI_WDATA 		= WRITE_DATA;
	assign M_AXI_WSTRB 		= 8'hFF; 		// 8개의 모든 바이트 스트로브 활성화
	assign M_AXI_WLAST 		= wvalid_reg; 	// 단일 전송이므로, 데이터 전송 시 항상 LAST
	assign M_AXI_WUSER      = 1'b0;
	assign M_AXI_WVALID 	= wvalid_reg;

	// AXI Write Response Channel Signals
	assign M_AXI_BREADY 	= bready_reg;

	// AXI Read Channels (Unused) - 읽기 동작은 수행하지 않으므로 비활성화
	assign M_AXI_ARID 		= MASTER_ID;
	assign M_AXI_ARADDR 	= 40'd0;
	assign M_AXI_ARLEN 		= 8'd0;
	assign M_AXI_ARSIZE 	= 3'b011;
	assign M_AXI_ARBURST 	= 2'b01;
	assign M_AXI_ARLOCK 	= 1'b0;
	assign M_AXI_ARCACHE 	= 4'b0011;
	assign M_AXI_ARPROT 	= 3'b000;
	assign M_AXI_ARQOS 		= 4'h0;
	assign M_AXI_ARREGION 	= 4'h0;
	assign M_AXI_ARUSER 	= 1'b0;
	assign M_AXI_ARVALID 	= 1'b0; // 항상 비활성화
	assign M_AXI_RREADY 	= 1'b0; // 항상 비활성화

endmodule