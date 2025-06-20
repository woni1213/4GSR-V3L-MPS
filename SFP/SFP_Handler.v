`timescale 1 ns / 1 ps

module SFP_Handler
(
	input i_clk,
	input i_rst,
	
	input i_channel_up,

	input i_sfp_en,
	input [1:0] i_sfp_id,

	output reg [63:0] m_tx_sfp_tdata,
	input m_tx_sfp_tready,
	output reg m_tx_sfp_tvalid,

	input [63:0] s_rx_sfp_tdata,
	output s_rx_sfp_tready,
	input s_rx_sfp_tvalid,

	// Master
	input [31:0] i_m_sfp_cmd,
	input [31:0] i_m_sfp_data,
	input i_m_sfp_flag,

	output reg [63:0] o_m_sfp_rsp,

	output reg [31:0] o_s0_analog_intl,
	output reg [31:0] o_s0_digital_intl,
	output reg [31:0] o_s0_c,
	output reg [31:0] o_s0_v,
	output reg [31:0] o_s0_dc_c,
	output reg [31:0] o_s0_dc_v,
	output reg [31:0] o_s0_phase_rms_r,
	output reg [31:0] o_s0_phase_rms_s,
	output reg [31:0] o_s0_phase_rms_t,

	// Slave
	// SFP -> PS
	output reg [31:0] o_s_sfp_cmd,
	output reg [31:0] o_s_sfp_data,

	// PS -> SFP
	input [63:0] i_s_sfp_rsp,
	input i_s_sfp_flag,

	output reg [63:0] m_peer_tdata,
	input m_peer_tready,
	output reg m_peer_tvalid,

	output reg [63:0] m_local_tdata,
	input m_local_tready,
	output reg m_local_tvalid,

	input [63:0] s_peer_tdata,
	output reg s_peer_tready,
	input s_peer_tvalid,

	input [63:0] s_local_tdata,
	output reg s_local_tready,
	input s_local_tvalid,

	input [31:0] i_peer_wr_data_cnt,
	input [31:0] i_local_wr_data_cnt,

	input [31:0] i_analog_intl,
	input [31:0] i_digital_intl,
	input [31:0] i_c,
	input [31:0] i_v,
	input [31:0] i_dc_c,
	input [31:0] i_dc_v,
	input [31:0] i_phase_rms_r,
	input [31:0] i_phase_rms_s,
	input [31:0] i_phase_rms_t,

	output [1:0] o_m_tx_state,
	output [1:0] o_s_peer_tx_state,
	output [3:0] o_s_local_tx_state,
	output [2:0] o_s_tx_state
);

	localparam IDLE	= 0;
	localparam RUN	= 1;
	localparam DONE	= 2;
	localparam L_RUN= 3;
	localparam P_RUN= 4;
	localparam STAT = 5;
	localparam INTL = 6;
	localparam CULL = 7;
	localparam VOLT = 8;
	localparam DC_C = 9;
	localparam DC_V = 10;
	localparam PH_R = 11;
	localparam PH_S = 12;
	localparam PH_T = 13;

	reg [1:0] m_tx_state;
	reg [1:0] s_peer_tx_state;
	reg [3:0] s_local_tx_state;
	reg [2:0] s_tx_state;

	reg [15:0] local_tx_period_cnt;

	wire sfp_master;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			m_tx_state <= IDLE;
			
		else
		begin
			case (m_tx_state)
				IDLE : 	m_tx_state <= (sfp_master && i_m_sfp_flag) ? RUN : IDLE;
				RUN : 	m_tx_state <= (m_tx_sfp_tready) ? DONE : RUN;
				DONE : 	m_tx_state <= (~i_m_sfp_flag) ? IDLE : DONE;
				default : m_tx_state <= m_tx_state;
			endcase
		end
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			s_peer_tx_state <= IDLE;
			
		else
		begin
			case (s_peer_tx_state)
				IDLE : 	s_peer_tx_state <= (~sfp_master && i_s_sfp_flag) ? RUN : IDLE;
				RUN : 	s_peer_tx_state <= (m_peer_tready) ? DONE : RUN;
				DONE : 	s_peer_tx_state <= (~i_s_sfp_flag) ? IDLE : DONE;
				default : s_peer_tx_state <= s_peer_tx_state;
			endcase
		end
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			s_local_tx_state <= IDLE;
			
		else
		begin
			case (s_local_tx_state)
				IDLE : 	s_local_tx_state <= ((local_tx_period_cnt < 40000) && (~sfp_master) && i_channel_up) ? STAT : IDLE;
				STAT :	s_local_tx_state <= INTL;
				INTL :	s_local_tx_state <= CULL;
				CULL :	s_local_tx_state <= VOLT;
				VOLT :	s_local_tx_state <= DC_C;
				DC_C :	s_local_tx_state <= DC_V;
				DC_V :	s_local_tx_state <= PH_R;
				PH_R :	s_local_tx_state <= PH_S;
				PH_S :	s_local_tx_state <= PH_T;
				PH_T :	s_local_tx_state <= DONE;
				DONE :	s_local_tx_state <= IDLE;
				default : s_local_tx_state <= s_local_tx_state;
			endcase
		end
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			s_tx_state <= IDLE;
			
		else
		begin
			case (s_tx_state)
				IDLE : 	s_tx_state <= (((|i_peer_wr_data_cnt) || (|i_local_wr_data_cnt)) && (~sfp_master)) ? L_RUN : IDLE;
				L_RUN : s_tx_state <= P_RUN;
				P_RUN : s_tx_state <= DONE;
				DONE : 	s_tx_state <= IDLE;
				default : s_tx_state <= s_tx_state;
			endcase
		end
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			local_tx_period_cnt <= 0;

		else
			local_tx_period_cnt <= (local_tx_period_cnt < 40000) ? local_tx_period_cnt + 1 : 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
		begin
			m_tx_sfp_tdata <= 0;
			m_tx_sfp_tvalid <= 0;
		end

		else if (m_tx_state == RUN)
		begin
			m_tx_sfp_tdata <= {i_m_sfp_cmd, i_m_sfp_data};
			m_tx_sfp_tvalid <= 1;
		end

		else if (s_tx_state == L_RUN)
		begin
			m_tx_sfp_tdata <= s_local_tdata;
			m_tx_sfp_tvalid <= s_local_tvalid;
		end

		else if (s_tx_state == P_RUN)
		begin
			m_tx_sfp_tdata <= s_peer_tdata;
			m_tx_sfp_tvalid <= s_peer_tvalid;
		end

		else
		begin
			m_tx_sfp_tdata <= 0;
			m_tx_sfp_tvalid <= 0;
		end
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			s_peer_tready <= 0;

		else
			s_peer_tready <= (s_tx_state == P_RUN);
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			s_local_tready <= 0;

		else
			s_local_tready <= (s_tx_state == L_RUN);
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
		begin
			m_peer_tdata <= 0;
			m_peer_tvalid <= 0;
		end

		else if (s_peer_tx_state == RUN)
		begin
			m_peer_tdata <= i_s_sfp_rsp;
			m_peer_tvalid <= 1;
		end

		else
		begin
			m_peer_tdata <= 0;
			m_peer_tvalid <= 0;
		end
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
		begin
			m_local_tdata <= 0;
			m_local_tvalid <= 0;
		end

		else if (~((s_local_tx_state == IDLE) || (s_local_tx_state == DONE)))
		begin
			m_local_tvalid <= 1;

			if (s_local_tx_state == STAT)		m_local_tdata <= {i_sfp_id, 28'h200_0000, i_analog_intl};
			else if (s_local_tx_state == INTL)	m_local_tdata <= {i_sfp_id, 28'h200_0001, i_digital_intl};
			else if (s_local_tx_state == CULL)	m_local_tdata <= {i_sfp_id, 28'h200_0002, i_c};
			else if (s_local_tx_state == VOLT)	m_local_tdata <= {i_sfp_id, 28'h200_0003, i_v};
			else if (s_local_tx_state == DC_C)	m_local_tdata <= {i_sfp_id, 28'h200_0004, i_dc_c};
			else if (s_local_tx_state == DC_V)	m_local_tdata <= {i_sfp_id, 28'h200_0005, i_dc_v};
			else if (s_local_tx_state == PH_R)	m_local_tdata <= {i_sfp_id, 28'h200_0006, i_phase_rms_r};
			else if (s_local_tx_state == PH_S)	m_local_tdata <= {i_sfp_id, 28'h200_0007, i_phase_rms_s};
			else if (s_local_tx_state == PH_T)	m_local_tdata <= {i_sfp_id, 28'h200_0008, i_phase_rms_t};
		end

		else
		begin
			m_local_tdata <= 0;
			m_local_tvalid <= 0;
		end
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
		begin
			o_m_sfp_rsp <= 0;
			o_s0_analog_intl <= 0;
			o_s0_digital_intl <= 0;
			o_s0_c <= 0;
			o_s0_v <= 0;
			o_s0_dc_c <= 0;
			o_s0_dc_v <= 0;
			o_s0_phase_rms_r <= 0;
			o_s0_phase_rms_s <= 0;
			o_s0_phase_rms_t <= 0;
		end

		else if (s_rx_sfp_tready && s_rx_sfp_tvalid && sfp_master)
		begin
			case (s_rx_sfp_tdata[63:32])
				32'h1200_0000 : o_s0_analog_intl <= s_rx_sfp_tdata[31:0];
				32'h1200_0001 : o_s0_digital_intl <= s_rx_sfp_tdata[31:0];
				32'h1200_0002 : o_s0_c <= s_rx_sfp_tdata[31:0];
				32'h1200_0003 : o_s0_v <= s_rx_sfp_tdata[31:0];
				32'h1200_0004 : o_s0_dc_c <= s_rx_sfp_tdata[31:0];
				32'h1200_0005 : o_s0_dc_v <= s_rx_sfp_tdata[31:0];
				32'h1200_0006 : o_s0_phase_rms_r <= s_rx_sfp_tdata[31:0];
				32'h1200_0007 : o_s0_phase_rms_s <= s_rx_sfp_tdata[31:0];
				32'h1200_0008 : o_s0_phase_rms_t <= s_rx_sfp_tdata[31:0];
				default :
					o_m_sfp_rsp <= s_rx_sfp_tdata;
			endcase
		end
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
		begin
			o_s_sfp_cmd <= 0;
			o_s_sfp_data <= 0;
		end

		else if (s_rx_sfp_tready && s_rx_sfp_tvalid && ~sfp_master)
		begin
			o_s_sfp_cmd <= s_rx_sfp_tdata[63:32];
			o_s_sfp_data <= s_rx_sfp_tdata[31:0];
		end
	end

	assign sfp_master = (i_sfp_en && (i_sfp_id == 0));
	assign s_rx_sfp_tready = 1;

	assign o_m_tx_state = m_tx_state;
	assign o_s_peer_tx_state = s_peer_tx_state;
	assign o_s_local_tx_state = s_local_tx_state;
	assign o_s_tx_state = s_tx_state;

endmodule