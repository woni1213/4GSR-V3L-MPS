`timescale 1 ns / 1 ps

module SFP_Handler
(
	input i_clk,
	input i_rst,

	input i_zynq_sfp_en,
	input [1:0] i_sfp_id,
	input i_axi_data_valid,

	// SLAVE TX
	input [15:0]	i_slv_state,
	input [31:0]	i_curr_data,
	input [31:0]	i_volt_data,
	input [31:0]	i_dc_data,

	// MASTER TX
	input [7:0]		i_dsp_sfp_cmd,

	input [7:0]		i_zynq_sfp_1_cmd,
	input [31:0]	i_sfp_1_data_1,
	input [31:0]	i_sfp_1_data_2,
	input [31:0]	i_sfp_1_data_3,

	input [7:0]		i_zynq_sfp_2_cmd,
	input [31:0]	i_sfp_2_data_1,
	input [31:0]	i_sfp_2_data_2,
	input [31:0]	i_sfp_2_data_3,

	input [7:0]		i_zynq_sfp_3_cmd,
	input [31:0]	i_sfp_3_data_1,
	input [31:0]	i_sfp_3_data_2,
	input [31:0]	i_sfp_3_data_3,

	// MASTER RX
	output reg [15:0]	o_sfp_1_stat,
	output reg [31:0]	o_sfp_1_curr,
	output reg [31:0]	o_sfp_1_volt,
	output reg [31:0]	o_sfp_1_dc,

	output reg [15:0]	o_sfp_2_stat,
	output reg [31:0]	o_sfp_2_curr,
	output reg [31:0]	o_sfp_2_volt,
	output reg [31:0]	o_sfp_2_dc,

	output reg [15:0]	o_sfp_3_stat,
	output reg [31:0]	o_sfp_3_curr,
	output reg [31:0]	o_sfp_3_volt,
	output reg [31:0]	o_sfp_3_dc,

	// SLAVE RX
	output reg [15:0]	o_sfp_cmd,
	output reg [31:0]	o_sfp_data_1,
	output reg [31:0]	o_sfp_data_2,
	output reg [31:0]	o_sfp_data_3,

	output reg [383:0] o_sfp_tx_data,
	input [383:0] i_sfp_rx_data,
	output reg o_sfp_tx_start_flag,
	input i_sfp_rx_end_flag,
	input i_sfp_tx_end_flag,

	output [2:0] o_state,

	// SLAVE SFP CMD DATA
	output reg o_sfp_pwm_en,
	output reg [31:0] o_sfp_c_factor,
	output reg [31:0] o_sfp_v_factor,
	output reg [15:0] o_sfp_zynq_ver,
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
	output reg o_sfp_intl_clr,
	output reg [31:0] o_sfp_set_c,
	output reg [31:0] o_sfp_set_v
);

	localparam IDLE = 0;
	localparam EN = 1;
	localparam SET = 2;
	localparam RUN = 3;
	localparam DONE = 4;

	reg [2:0] state;
	reg [2:0] n_state;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			state <= IDLE;

		else
			state <= n_state;
	end

	always @(*)
	begin
		case (state)
			IDLE 	: n_state = (i_zynq_sfp_en) ? EN : IDLE;
			EN	 	: n_state = (i_sfp_id == 0) ? SET : ((i_sfp_rx_end_flag) ? SET : EN);
			SET 	: n_state = RUN;
			RUN 	: n_state = DONE;
			DONE 	: n_state = (i_sfp_id == 0) ? ((i_sfp_tx_end_flag) ? EN : DONE) : EN;
			default : n_state = IDLE;
		endcase
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_sfp_tx_data <= 0;

		else if (state == SET)
		begin
			if (i_sfp_id == 0)
			begin
				if (i_axi_data_valid)
					o_sfp_tx_data <= {	16'd3, i_zynq_sfp_3_cmd, i_dsp_sfp_cmd, i_sfp_3_data_1, i_sfp_3_data_2, i_sfp_3_data_3,
										16'd2, i_zynq_sfp_2_cmd, i_dsp_sfp_cmd, i_sfp_2_data_1, i_sfp_2_data_2, i_sfp_2_data_3,
										16'd1, i_zynq_sfp_1_cmd, i_dsp_sfp_cmd, i_sfp_1_data_1, i_sfp_1_data_2, i_sfp_1_data_3	};

				else
					o_sfp_tx_data <= {	16'd3, 8'h0, i_dsp_sfp_cmd, i_sfp_3_data_1, 32'd0, i_sfp_3_data_3,
										16'd2, 8'h0, i_dsp_sfp_cmd, i_sfp_2_data_1, 32'd0, i_sfp_2_data_3,
										16'd1, 8'h0, i_dsp_sfp_cmd, i_sfp_1_data_1, 32'd0, i_sfp_1_data_3	};
			end
				

			else if (i_sfp_id == 1)
				o_sfp_tx_data <= {i_sfp_rx_data[383:128], 16'd1, i_slv_state, i_curr_data, i_volt_data, i_dc_data};

			else if (i_sfp_id == 2)
				o_sfp_tx_data <= {i_sfp_rx_data[383:256], 16'd2, i_slv_state, i_curr_data, i_volt_data, i_dc_data, i_sfp_rx_data[127:0]};

			else if (i_sfp_id == 3)
				o_sfp_tx_data <= {16'd3, i_slv_state, i_curr_data, i_volt_data, i_dc_data, i_sfp_rx_data[255:0]};

			else
				o_sfp_tx_data <= o_sfp_tx_data;
		end

		else
			o_sfp_tx_data <= o_sfp_tx_data;
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
			o_sfp_1_stat	<= 0;
			o_sfp_1_curr	<= 0;
			o_sfp_1_volt	<= 0;
			o_sfp_1_dc		<= 0;
			o_sfp_2_stat	<= 0;
			o_sfp_2_curr	<= 0;
			o_sfp_2_volt	<= 0;
			o_sfp_2_dc		<= 0;
			o_sfp_3_stat	<= 0;
			o_sfp_3_curr	<= 0;
			o_sfp_3_volt	<= 0;
			o_sfp_3_dc		<= 0;
		end

		else if (i_sfp_rx_end_flag)
		begin
			o_sfp_1_stat	<= i_sfp_rx_data[111:96];
			o_sfp_1_curr	<= i_sfp_rx_data[95:64];
			o_sfp_1_volt	<= i_sfp_rx_data[63:32];
			o_sfp_1_dc		<= i_sfp_rx_data[31:0];
			o_sfp_2_stat	<= i_sfp_rx_data[239:224];
			o_sfp_2_curr	<= i_sfp_rx_data[223:192];
			o_sfp_2_volt	<= i_sfp_rx_data[191:160];
			o_sfp_2_dc		<= i_sfp_rx_data[159:128];
			o_sfp_3_stat	<= i_sfp_rx_data[367:352];
			o_sfp_3_curr	<= i_sfp_rx_data[351:320];
			o_sfp_3_volt	<= i_sfp_rx_data[319:288];
			o_sfp_3_dc		<= i_sfp_rx_data[287:256];
		end
		
		else
		begin
			o_sfp_1_stat	<= o_sfp_1_stat;
			o_sfp_1_curr	<= o_sfp_1_curr;
			o_sfp_1_volt	<= o_sfp_1_volt;
			o_sfp_1_dc		<= o_sfp_1_dc;
			o_sfp_2_stat	<= o_sfp_2_stat;
			o_sfp_2_curr	<= o_sfp_2_curr;
			o_sfp_2_volt	<= o_sfp_2_volt;
			o_sfp_2_dc		<= o_sfp_2_dc;
			o_sfp_3_stat	<= o_sfp_3_stat;
			o_sfp_3_curr	<= o_sfp_3_curr;
			o_sfp_3_volt	<= o_sfp_3_volt;
			o_sfp_3_dc		<= o_sfp_3_dc;
		end
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
		begin
			o_sfp_cmd		<= 0;
			o_sfp_data_1	<= 0;
			o_sfp_data_2	<= 0;
			o_sfp_data_3	<= 0;
		end

		else if (i_sfp_rx_end_flag)
		begin
			if (i_sfp_id == 1)
			begin
				o_sfp_cmd		<= i_sfp_rx_data[111:96];
				o_sfp_data_1	<= i_sfp_rx_data[95:64];
				o_sfp_data_2	<= i_sfp_rx_data[63:32];
				o_sfp_data_3	<= i_sfp_rx_data[31:0];
			end

			else if (i_sfp_id == 2)
			begin
				o_sfp_cmd		<= i_sfp_rx_data[239:224];
				o_sfp_data_1	<= i_sfp_rx_data[223:192];
				o_sfp_data_2	<= i_sfp_rx_data[191:160];
				o_sfp_data_3	<= i_sfp_rx_data[159:128];
			end

			else if (i_sfp_id == 3)
			begin
				o_sfp_cmd		<= i_sfp_rx_data[367:352];
				o_sfp_data_1	<= i_sfp_rx_data[351:320];
				o_sfp_data_2	<= i_sfp_rx_data[319:288];
				o_sfp_data_3	<= i_sfp_rx_data[287:256];
			end

			else
			begin
				o_sfp_cmd		<= o_sfp_cmd;
				o_sfp_data_1	<= o_sfp_data_1;
				o_sfp_data_2	<= o_sfp_data_2;
				o_sfp_data_3	<= o_sfp_data_3;
			end
		end

		else
		begin
			o_sfp_cmd		<= o_sfp_cmd;
			o_sfp_data_1	<= o_sfp_data_1;
			o_sfp_data_2	<= o_sfp_data_2;
			o_sfp_data_3	<= o_sfp_data_3;
		end
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
		begin
			o_sfp_c_factor		<= 0;
			o_sfp_v_factor		<= 0;
			o_sfp_min_c			<= 0;
			o_sfp_max_c			<= 0;
			o_sfp_min_v			<= 0;
			o_sfp_max_v			<= 0;
			o_sfp_set_c			<= 0;
			o_sfp_set_v			<= 0;
			o_sfp_p_gain_c		<= 0;
			o_sfp_p_gain_v		<= 0;
			o_sfp_i_gain_c		<= 0;
			o_sfp_i_gain_v		<= 0;
			o_sfp_d_gain_c		<= 0;
			o_sfp_d_gain_v		<= 0;
			o_sfp_pwm_en		<= 0;
			o_sfp_max_duty		<= 0;
			o_sfp_max_phase		<= 0;
			o_sfp_max_freq		<= 0;
			o_sfp_min_freq		<= 0;
			o_sfp_deadband		<= 0;
			o_sfp_sw_freq		<= 0;
			o_sfp_zynq_ver		<= 0;
			o_sfp_intl_clr		<= 0;
		end

		else if (i_sfp_id != 0)	// Slave Mode
		begin
			case (o_sfp_cmd[15:8])
				1 :	o_sfp_c_factor				<= o_sfp_data_2;
				2 :	o_sfp_v_factor				<= o_sfp_data_2;
				3 :	o_sfp_min_c					<= o_sfp_data_2;
				4 :	o_sfp_max_c					<= o_sfp_data_2;
				5 :	o_sfp_min_v					<= o_sfp_data_2;
				6 :	o_sfp_max_v					<= o_sfp_data_2;
				7 :	o_sfp_set_c					<= o_sfp_data_2;
				8:	o_sfp_set_v					<= o_sfp_data_2;
				9 :	o_sfp_p_gain_c				<= o_sfp_data_2;
				10:	o_sfp_p_gain_v				<= o_sfp_data_2;
				11:	o_sfp_i_gain_c				<= o_sfp_data_2;
				12:	o_sfp_i_gain_v				<= o_sfp_data_2;
				13:	o_sfp_d_gain_c				<= o_sfp_data_2;
				14:	o_sfp_d_gain_v				<= o_sfp_data_2;
				15:	o_sfp_pwm_en				<= o_sfp_data_2[0];
				16:	o_sfp_max_duty				<= o_sfp_data_2;
				17:	o_sfp_max_phase				<= o_sfp_data_2;
				18:	o_sfp_max_freq				<= o_sfp_data_2;
				19:	o_sfp_min_freq				<= o_sfp_data_2;
				20:	o_sfp_deadband				<= o_sfp_data_2[15:0];
				21:	o_sfp_sw_freq				<= o_sfp_data_2[15:0];
				22:	o_sfp_zynq_ver				<= o_sfp_data_2[15:0];
				23:	o_sfp_intl_clr				<= o_sfp_data_2[0];
			endcase
		end

		else
		begin
			o_sfp_c_factor		<= o_sfp_c_factor;
			o_sfp_v_factor		<= o_sfp_v_factor;
			o_sfp_min_c			<= o_sfp_min_c;
			o_sfp_max_c			<= o_sfp_max_c;
			o_sfp_min_v			<= o_sfp_min_v;
			o_sfp_max_v			<= o_sfp_max_v;
			o_sfp_set_c			<= o_sfp_set_c;
			o_sfp_set_v			<= o_sfp_set_v;
			o_sfp_p_gain_c		<= o_sfp_p_gain_c;
			o_sfp_p_gain_v		<= o_sfp_p_gain_v;
			o_sfp_i_gain_c		<= o_sfp_i_gain_c;
			o_sfp_i_gain_v		<= o_sfp_i_gain_v;
			o_sfp_d_gain_c		<= o_sfp_d_gain_c;
			o_sfp_d_gain_v		<= o_sfp_d_gain_v;
			o_sfp_pwm_en		<= o_sfp_pwm_en;
			o_sfp_max_duty		<= o_sfp_max_duty;
			o_sfp_max_phase		<= o_sfp_max_phase;
			o_sfp_max_freq		<= o_sfp_max_freq;
			o_sfp_min_freq		<= o_sfp_min_freq;
			o_sfp_deadband		<= o_sfp_deadband;
			o_sfp_sw_freq		<= o_sfp_sw_freq;
			o_sfp_zynq_ver		<= o_sfp_zynq_ver;
			o_sfp_intl_clr		<= o_sfp_intl_clr;
		end
	end
	
	assign o_state = state;

endmodule