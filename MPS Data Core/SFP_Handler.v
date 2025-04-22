`timescale 1 ns / 1 ps

module SFP_Handler
(
	input i_clk,
	input i_rst,

	input i_zynq_sfp_en,
	input i_sfp_id,

	input [1215:0] i_sfp_rx_data,
	output reg o_sfp_tx_start_flag,
	input i_sfp_rx_end_flag,
	input i_sfp_tx_end_flag,

	// Master Rx Data
	output reg [31:0] o_sfp_c,
	output reg [31:0] o_sfp_v,
	output reg [31:0] o_sfp_dc_c,
	output reg [31:0] o_sfp_dc_v,
	output reg [31:0] o_sfp_phase_r_rms,
	output reg [31:0] o_sfp_phase_s_rms,
	output reg [31:0] o_sfp_phase_t_rms,
	output reg [31:0] o_sfp_igbt_t,
	output reg [31:0] o_sfp_i_inductor_t,
	output reg [31:0] o_sfp_o_inductor_t,
	output reg [31:0] o_sfp_intl,
	output reg [31:0] o_sfp_fsm,

	// Slave Rx Data
	output reg [15:0] o_sfp_mps_status,
	output reg o_sfp_intl_clr,
	output reg [3:0] o_sfp_fsm_cmd,
	output reg [31:0] o_sfp_set_c,
	output reg [31:0] o_sfp_set_v,
	output reg [31:0] o_sfp_max_duty,
	output reg [31:0] o_sfp_max_phase,
	output reg [31:0] o_sfp_max_freq,
	output reg [31:0] o_sfp_min_freq,
	output reg [31:0] o_sfp_min_c,
	output reg [31:0] o_sfp_max_c,
	output reg [31:0] o_sfp_min_v,
	output reg [31:0] o_sfp_max_v,
	output reg [15:0] o_sfp_deadband,
	output reg [15:0] o_sfp_sw_freq,
	output reg [31:0] o_sfp_p_gain_c,
	output reg [31:0] o_sfp_i_gain_c,
	output reg [31:0] o_sfp_d_gain_c,
	output reg [31:0] o_sfp_p_gain_v,
	output reg [31:0] o_sfp_i_gain_v,
	output reg [31:0] o_sfp_d_gain_v,

	output reg [31:0] o_sfp_c_over_sp,
	output reg [31:0] o_sfp_v_over_sp,
	output reg [31:0] o_sfp_dc_c_over_sp,
	output reg [31:0] o_sfp_dc_v_over_sp,
	output reg [31:0] o_sfp_igbt_t_over_sp,
	output reg [31:0] o_sfp_i_id_t_over_sp,
	output reg [31:0] o_sfp_o_id_t_over_sp,
	output reg [31:0] o_sfp_c_data_thresh,
	output reg [31:0] o_sfp_c_cnt_thresh,
	output reg [31:0] o_sfp_c_period,
	output reg [31:0] o_sfp_c_cycle_cnt,
	output reg [31:0] o_sfp_c_diff,
	output reg [31:0] o_sfp_c_delay,
	output reg [31:0] o_sfp_v_data_thresh,
	output reg [31:0] o_sfp_v_cnt_thresh,
	output reg [31:0] o_sfp_v_period,
	output reg [31:0] o_sfp_v_cycle_cnt,
	output reg [31:0] o_sfp_v_diff,
	output reg [31:0] o_sfp_v_delay,

	output [2:0] o_state
);

	localparam IDLE = 0;
	localparam EN 	= 1;
	localparam RUN 	= 2;
	localparam DONE = 3;
	localparam HOLD	= 4;

	reg [2:0] state;
	reg [2:0] n_state;

	reg [9:0] hold_cnt;

	wire sfp_slave;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			state <= IDLE;

		else if (~i_zynq_sfp_en)
			state <= IDLE;

		else
			state <= n_state;
	end

	always @(*)
	begin
		case (state)
			IDLE 	: n_state = (i_zynq_sfp_en) ? EN : IDLE;
			EN	 	: n_state = RUN;
			RUN 	: n_state = DONE;
			DONE 	: n_state = (i_sfp_tx_end_flag) ? HOLD : DONE;
			HOLD 	: n_state = (&hold_cnt) ? EN : HOLD;
			default : n_state = IDLE;
		endcase
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			hold_cnt <= 0;

		else
			hold_cnt <= (state == HOLD) ? hold_cnt + 1 : 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_sfp_tx_start_flag <= 0;

		else if (state == RUN)
			o_sfp_tx_start_flag <= 1;

		else
			o_sfp_tx_start_flag <= 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
		begin
			o_sfp_c				<= 0;
			o_sfp_v				<= 0;
			o_sfp_dc_c			<= 0;
			o_sfp_dc_v			<= 0;
			o_sfp_phase_r_rms	<= 0;
			o_sfp_phase_s_rms	<= 0;
			o_sfp_phase_t_rms	<= 0;
			o_sfp_igbt_t		<= 0;
			o_sfp_i_inductor_t	<= 0;
			o_sfp_o_inductor_t	<= 0;
			o_sfp_intl			<= 0;
			o_sfp_fsm			<= 0;
		end

		else
		begin
			o_sfp_c				<= (~sfp_slave) ? i_sfp_rx_data[31:0] : o_sfp_c;
			o_sfp_v				<= (~sfp_slave) ? i_sfp_rx_data[63:32] : o_sfp_v;
			o_sfp_dc_c			<= (~sfp_slave) ? i_sfp_rx_data[95:64] : o_sfp_dc_c;
			o_sfp_dc_v			<= (~sfp_slave) ? i_sfp_rx_data[127:96] : o_sfp_dc_v;
			o_sfp_phase_r_rms	<= (~sfp_slave) ? i_sfp_rx_data[159:128] : o_sfp_phase_r_rms;
			o_sfp_phase_s_rms	<= (~sfp_slave) ? i_sfp_rx_data[191:160] : o_sfp_phase_s_rms;
			o_sfp_phase_t_rms	<= (~sfp_slave) ? i_sfp_rx_data[223:192] : o_sfp_phase_t_rms;
			o_sfp_igbt_t		<= (~sfp_slave) ? i_sfp_rx_data[255:224] : o_sfp_igbt_t;
			o_sfp_i_inductor_t	<= (~sfp_slave) ? i_sfp_rx_data[287:256] : o_sfp_i_inductor_t;
			o_sfp_o_inductor_t	<= (~sfp_slave) ? i_sfp_rx_data[319:288] : o_sfp_o_inductor_t;
			o_sfp_intl			<= (~sfp_slave) ? i_sfp_rx_data[351:320] : o_sfp_intl;
			o_sfp_fsm			<= (~sfp_slave) ? i_sfp_rx_data[383:352] : o_sfp_fsm;
		end
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
		begin
			o_sfp_mps_status<= 0;
			o_sfp_set_c		<= 0;
			o_sfp_set_v		<= 0;
			o_sfp_max_duty	<= 0;
			o_sfp_max_phase	<= 0;
			o_sfp_max_freq	<= 0;
			o_sfp_min_freq	<= 0;
			o_sfp_min_c		<= 0;
			o_sfp_max_c		<= 0;
			o_sfp_min_v		<= 0;
			o_sfp_max_v		<= 0;
			o_sfp_deadband	<= 0;
			o_sfp_sw_freq	<= 0;
			o_sfp_p_gain_c	<= 0;
			o_sfp_i_gain_c	<= 0;
			o_sfp_d_gain_c	<= 0;
			o_sfp_p_gain_v	<= 0;
			o_sfp_i_gain_v	<= 0;
			o_sfp_d_gain_v	<= 0;

			o_sfp_c_over_sp			<= 0;
			o_sfp_v_over_sp			<= 0;
			o_sfp_dc_c_over_sp		<= 0;
			o_sfp_dc_v_over_sp		<= 0;
			o_sfp_igbt_t_over_sp	<= 0;
			o_sfp_i_id_t_over_sp	<= 0;
			o_sfp_o_id_t_over_sp	<= 0;
			o_sfp_c_data_thresh		<= 0;
			o_sfp_c_cnt_thresh		<= 0;
			o_sfp_c_period			<= 0;
			o_sfp_c_cycle_cnt		<= 0;
			o_sfp_c_diff			<= 0;
			o_sfp_c_delay			<= 0;
			o_sfp_v_data_thresh		<= 0;
			o_sfp_v_cnt_thresh		<= 0;
			o_sfp_v_period			<= 0;
			o_sfp_v_cycle_cnt		<= 0;
			o_sfp_v_diff			<= 0;
			o_sfp_v_delay			<= 0;
		end

		else
		begin
			o_sfp_mps_status<= (sfp_slave) ? i_sfp_rx_data[3:0] : o_sfp_mps_status;
			o_sfp_intl_clr	<= (sfp_slave) ? i_sfp_rx_data[10] : o_sfp_intl_clr;
			o_sfp_fsm_cmd	<= (sfp_slave) ? i_sfp_rx_data[15:11] : o_sfp_fsm_cmd;
			o_sfp_set_c		<= (sfp_slave) ? i_sfp_rx_data[47:16] : o_sfp_set_c;
			o_sfp_set_v		<= (sfp_slave) ? i_sfp_rx_data[79:48] : o_sfp_set_v;
			o_sfp_max_duty	<= (sfp_slave) ? i_sfp_rx_data[111:80] : o_sfp_max_duty;
			o_sfp_max_phase	<= (sfp_slave) ? i_sfp_rx_data[143:112] : o_sfp_max_phase;
			o_sfp_max_freq	<= (sfp_slave) ? i_sfp_rx_data[175:144] : o_sfp_max_freq;
			o_sfp_min_freq	<= (sfp_slave) ? i_sfp_rx_data[207:176] : o_sfp_min_freq;
			o_sfp_min_c		<= (sfp_slave) ? i_sfp_rx_data[239:208] : o_sfp_min_c;
			o_sfp_max_c		<= (sfp_slave) ? i_sfp_rx_data[271:240] : o_sfp_max_c;
			o_sfp_min_v		<= (sfp_slave) ? i_sfp_rx_data[303:272] : o_sfp_min_v;
			o_sfp_max_v		<= (sfp_slave) ? i_sfp_rx_data[335:304] : o_sfp_max_v;
			o_sfp_deadband	<= (sfp_slave) ? i_sfp_rx_data[351:336] : o_sfp_deadband;
			o_sfp_sw_freq	<= (sfp_slave) ? i_sfp_rx_data[367:352] : o_sfp_sw_freq;
			o_sfp_p_gain_c	<= (sfp_slave) ? i_sfp_rx_data[399:368] : o_sfp_p_gain_c;
			o_sfp_i_gain_c	<= (sfp_slave) ? i_sfp_rx_data[431:400] : o_sfp_i_gain_c;
			o_sfp_d_gain_c	<= (sfp_slave) ? i_sfp_rx_data[463:432] : o_sfp_d_gain_c;
			o_sfp_p_gain_v	<= (sfp_slave) ? i_sfp_rx_data[495:464] : o_sfp_p_gain_v;
			o_sfp_i_gain_v	<= (sfp_slave) ? i_sfp_rx_data[527:496] : o_sfp_i_gain_v;
			o_sfp_d_gain_v	<= (sfp_slave) ? i_sfp_rx_data[559:528] : o_sfp_d_gain_v;

			o_sfp_c_over_sp			<= (sfp_slave) ? i_sfp_rx_data[591:560] : o_sfp_c_over_sp;
			o_sfp_v_over_sp			<= (sfp_slave) ? i_sfp_rx_data[623:592] : o_sfp_v_over_sp;
			o_sfp_dc_c_over_sp		<= (sfp_slave) ? i_sfp_rx_data[655:624] : o_sfp_dc_c_over_sp;
			o_sfp_dc_v_over_sp		<= (sfp_slave) ? i_sfp_rx_data[687:656] : o_sfp_dc_v_over_sp;
			o_sfp_igbt_t_over_sp	<= (sfp_slave) ? i_sfp_rx_data[719:688] : o_sfp_igbt_t_over_sp;
			o_sfp_i_id_t_over_sp	<= (sfp_slave) ? i_sfp_rx_data[751:720] : o_sfp_i_id_t_over_sp;
			o_sfp_o_id_t_over_sp	<= (sfp_slave) ? i_sfp_rx_data[783:752] : o_sfp_o_id_t_over_sp;
			o_sfp_c_data_thresh		<= (sfp_slave) ? i_sfp_rx_data[815:784] : o_sfp_c_data_thresh;
			o_sfp_c_cnt_thresh		<= (sfp_slave) ? i_sfp_rx_data[847:816] : o_sfp_c_cnt_thresh;
			o_sfp_c_period			<= (sfp_slave) ? i_sfp_rx_data[879:848] : o_sfp_c_period;
			o_sfp_c_cycle_cnt		<= (sfp_slave) ? i_sfp_rx_data[911:880] : o_sfp_c_cycle_cnt;
			o_sfp_c_diff			<= (sfp_slave) ? i_sfp_rx_data[943:912] : o_sfp_c_diff;
			o_sfp_c_delay			<= (sfp_slave) ? i_sfp_rx_data[975:944] : o_sfp_c_delay;
			o_sfp_v_data_thresh		<= (sfp_slave) ? i_sfp_rx_data[1007:976] : o_sfp_v_data_thresh;
			o_sfp_v_cnt_thresh		<= (sfp_slave) ? i_sfp_rx_data[1039:1008] : o_sfp_v_cnt_thresh;
			o_sfp_v_period			<= (sfp_slave) ? i_sfp_rx_data[1071:1040] : o_sfp_v_period;
			o_sfp_v_cycle_cnt		<= (sfp_slave) ? i_sfp_rx_data[1103:1072] : o_sfp_v_cycle_cnt;
			o_sfp_v_diff			<= (sfp_slave) ? i_sfp_rx_data[1135:1104] : o_sfp_v_diff;
			o_sfp_v_delay			<= (sfp_slave) ? i_sfp_rx_data[1167:1136] : o_sfp_v_delay;
		end
	end
	
	assign o_state = state;

	assign sfp_slave = (i_sfp_rx_end_flag && i_sfp_id);

endmodule