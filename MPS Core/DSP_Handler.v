`timescale 1 ns / 1 ps
/*

24.09.10 :	ìµœì´ˆ ?ƒ?„±

24.09.24 :	TX?˜ FSM?´ Master?¸ ê²½ìš°?—ë§? ?‹¤?–‰?˜?Š” ê²ƒì„ ?‚­? œ


*/

module DSP_Handler
(
	input i_clk,
	input i_rst,

	input [31:0] i_zynq_intl,
	input i_w_ready,
	output o_w_valid,
	input i_r_valid,

	input i_intl_clr,

	// SFP Slave
	input i_sfp_slave,
	input [31:0] i_s_sfp_set_c,
	input [31:0] i_s_sfp_set_v,

	// Waveform
	input [1:0] i_wf_en,
	input [31:0] i_wf_sp,
	output o_wf_set_flag,

	// Zynq to DSP
	output reg [8:0] o_xintf_z_to_d_addr,
	output reg [15:0] o_xintf_z_to_d_din,
	output reg o_xintf_z_to_d_ce,

	input [31:0] i_set_c,
	input [31:0] i_set_v,
	input [31:0] i_d_gain_c,
	input [31:0] i_d_gain_v,
	input [31:0] i_p_gain_c,
	input [31:0] i_i_gain_c,
	input [31:0] i_p_gain_v,
	input [31:0] i_i_gain_v,
	input [31:0] i_c_adc_data,
	input [31:0] i_v_adc_data,
	
	input [31:0] i_max_duty,
    input [31:0] i_max_phase,
    input [31:0] i_max_freq,
    input [31:0] i_min_freq,
	input [31:0] i_min_c,
	input [31:0] i_max_c,
	input [31:0] i_min_v,
	input [31:0] i_max_v,
	input [15:0] i_deadband,
	input [15:0] i_sw_freq,
	input [3:0] i_mps_setup,

	// DSP to Zynq
	input [15:0] i_xintf_d_to_z_dout,
	output reg [8:0] o_xintf_d_to_z_addr,
	output reg o_xintf_d_to_z_ce,

	output reg [31:0] o_dsp_max_duty,
	output reg [31:0] o_dsp_max_phase,
	output reg [31:0] o_dsp_max_frequency,
	output reg [31:0] o_dsp_min_frequency,
	output reg [31:0] o_dsp_min_v,
	output reg [31:0] o_dsp_max_v,
	output reg [31:0] o_dsp_min_c,
	output reg [31:0] o_dsp_max_c,
	output reg [15:0] o_dsp_deadband,
	output reg [15:0] o_dsp_sw_freq,
	output reg [31:0] o_dsp_p_gain_c,
	output reg [31:0] o_dsp_i_gain_c,
	output reg [31:0] o_dsp_d_gain_c,
	output reg [31:0] o_dsp_p_gain_v,
	output reg [31:0] o_dsp_i_gain_v,
	output reg [31:0] o_dsp_d_gain_v,
	output reg [31:0] o_dsp_set_c,
	output reg [31:0] o_dsp_set_v,
	output reg [15:0] o_dsp_status
);

	localparam W_IDLE = 0;
	localparam W_SETUP = 1;
	localparam WRITE = 2;
	localparam DELAY = 3;
	localparam W_DONE = 4;
	
	localparam R_IDLE = 0;
	localparam R_SETUP = 1;
	localparam READ = 2;
	localparam R_DONE = 3;

	reg [1:0] r_state;
	reg [2:0] w_state;

	reg [8:0] w_addr_pointer;
	reg [8:0] r_addr_pointer;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			w_state <= W_IDLE;

		else if (w_state == W_IDLE)
			w_state <= W_SETUP;

		else if(w_state == W_SETUP)
			w_state <= WRITE;

		else if(w_state == WRITE)
			w_state <= (w_addr_pointer == 69) ? DELAY : WRITE;


		else if(w_state == DELAY)
			w_state <= (i_w_ready) ? W_DONE : DELAY;

		else if(w_state == W_DONE)
			w_state <= W_IDLE;

		else
			w_state <= W_IDLE;
	end

	// DPBRAM Read FSM
	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			r_state <= R_IDLE;

		else if (r_state == R_IDLE)
			r_state <= R_SETUP;

		else if(r_state == R_SETUP)
			r_state <= (i_r_valid) ? READ : R_SETUP;
			
		else if(r_state == READ)
			r_state <= (r_addr_pointer == 176) ? R_DONE : READ;

		else if(r_state == R_DONE)
			r_state <= R_IDLE;

		else
			r_state <= R_IDLE;
	end

	// DPBRAM Addr Pointer
	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			w_addr_pointer <= 0;

		else if (w_state == WRITE)
			w_addr_pointer <= w_addr_pointer + 1;

		else if (w_state == W_DONE)
			w_addr_pointer <= 0;

		else
			w_addr_pointer <= w_addr_pointer;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			r_addr_pointer <= 128;

		else if (r_state == READ)
			r_addr_pointer <= r_addr_pointer + 1;

		else if (r_state == R_DONE)
			r_addr_pointer <= 128;

		else
			r_addr_pointer <= r_addr_pointer;
	end

	// DPBRAM CE Control
	always @(posedge i_clk or negedge i_rst)
	begin
			if (~i_rst)
				o_xintf_z_to_d_ce <= 0;

			else if ((w_state == W_SETUP) || (w_state == WRITE))
				o_xintf_z_to_d_ce <= 1;

			else
				o_xintf_z_to_d_ce <= 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
			if (~i_rst)
				o_xintf_d_to_z_ce <= 0;

			else if ((r_state == R_SETUP) || (r_state == READ))
				o_xintf_d_to_z_ce <= 1;

			else
				o_xintf_d_to_z_ce <= 0;
	end

	// DPBRAM WRITE
	always @(posedge i_clk or negedge i_rst)
	begin
			if (~i_rst)
			begin
				o_xintf_z_to_d_din <= 0;
				o_xintf_z_to_d_addr <= 0;
			end

		else if (w_state == WRITE)
		begin
			case (w_addr_pointer)
				8  : begin o_xintf_z_to_d_addr <= 8 ;		o_xintf_z_to_d_din <= i_max_duty[15:0];		end
				9  : begin o_xintf_z_to_d_addr <= 9 ;		o_xintf_z_to_d_din <= i_max_duty[31:16];	end
				10 : begin o_xintf_z_to_d_addr <= 10;		o_xintf_z_to_d_din <= i_max_phase[15:0];	end
				11 : begin o_xintf_z_to_d_addr <= 11;		o_xintf_z_to_d_din <= i_max_phase[31:16];	end
				12 : begin o_xintf_z_to_d_addr <= 12;		o_xintf_z_to_d_din <= i_max_freq[15:0];		end 
				13 : begin o_xintf_z_to_d_addr <= 13;		o_xintf_z_to_d_din <= i_max_freq[31:16];	end
				14 : begin o_xintf_z_to_d_addr <= 14;		o_xintf_z_to_d_din <= i_min_freq[15:0];		end
				15 : begin o_xintf_z_to_d_addr <= 15;		o_xintf_z_to_d_din <= i_min_freq[31:16];	end
				16 : begin o_xintf_z_to_d_addr <= 16;		o_xintf_z_to_d_din <= i_min_v[15:0];		end
				17 : begin o_xintf_z_to_d_addr <= 17;		o_xintf_z_to_d_din <= i_min_v[31:16];		end
				18 : begin o_xintf_z_to_d_addr <= 18;		o_xintf_z_to_d_din <= i_max_v[15:0];		end
				19 : begin o_xintf_z_to_d_addr <= 19;		o_xintf_z_to_d_din <= i_max_v[31:16];		end
				20 : begin o_xintf_z_to_d_addr <= 20;		o_xintf_z_to_d_din <= i_min_c[15:0];		end
				21 : begin o_xintf_z_to_d_addr <= 21;		o_xintf_z_to_d_din <= i_min_c[31:16];		end
				22 : begin o_xintf_z_to_d_addr <= 22;		o_xintf_z_to_d_din <= i_max_c[15:0];		end
				23 : begin o_xintf_z_to_d_addr <= 23;		o_xintf_z_to_d_din <= i_max_c[31:16];		end
				24 : begin o_xintf_z_to_d_addr <= 24;		o_xintf_z_to_d_din <= i_deadband;			end
				25 : begin o_xintf_z_to_d_addr <= 25;		o_xintf_z_to_d_din <= i_sw_freq;			end
				26 : begin o_xintf_z_to_d_addr <= 26;		o_xintf_z_to_d_din <= i_p_gain_c[15:0];		end
				27 : begin o_xintf_z_to_d_addr <= 27;		o_xintf_z_to_d_din <= i_p_gain_c[31:16];	end
				28 : begin o_xintf_z_to_d_addr <= 28;		o_xintf_z_to_d_din <= i_i_gain_c[15:0];		end
				29 : begin o_xintf_z_to_d_addr <= 29;		o_xintf_z_to_d_din <= i_i_gain_c[31:16];	end
				30 : begin o_xintf_z_to_d_addr <= 30;		o_xintf_z_to_d_din <= i_d_gain_c[15:0];		end
				31 : begin o_xintf_z_to_d_addr <= 31;		o_xintf_z_to_d_din <= i_d_gain_c[31:16];	end
				32 : begin o_xintf_z_to_d_addr <= 32;		o_xintf_z_to_d_din <= i_p_gain_v[15:0];		end
				33 : begin o_xintf_z_to_d_addr <= 33;		o_xintf_z_to_d_din <= i_p_gain_v[31:16];	end
				34 : begin o_xintf_z_to_d_addr <= 34;		o_xintf_z_to_d_din <= i_i_gain_v[15:0];		end
				35 : begin o_xintf_z_to_d_addr <= 35;		o_xintf_z_to_d_din <= i_i_gain_v[31:16];	end
				36 : begin o_xintf_z_to_d_addr <= 36;		o_xintf_z_to_d_din <= i_d_gain_v[15:0];		end
				37 : begin o_xintf_z_to_d_addr <= 37;		o_xintf_z_to_d_din <= i_d_gain_v[31:16];	end
				39 : begin o_xintf_z_to_d_addr <= 39;		o_xintf_z_to_d_din <= i_mps_setup;			end
				40 : begin o_xintf_z_to_d_addr <= 40;		o_xintf_z_to_d_din <= i_c_adc_data[15:0];	end
				41 : begin o_xintf_z_to_d_addr <= 41;		o_xintf_z_to_d_din <= i_c_adc_data[31:16];	end
				42 : begin o_xintf_z_to_d_addr <= 42;		o_xintf_z_to_d_din <= i_v_adc_data[15:0];	end
				43 : begin o_xintf_z_to_d_addr <= 43;		o_xintf_z_to_d_din <= i_v_adc_data[31:16];	end
				44 : begin o_xintf_z_to_d_addr <= 44;		o_xintf_z_to_d_din <= (i_sfp_slave) ? i_s_sfp_set_c[15:0]	: (i_wf_en == 1) ? i_wf_sp[15:0] : i_set_c[15:0];	end
				45 : begin o_xintf_z_to_d_addr <= 45;		o_xintf_z_to_d_din <= (i_sfp_slave) ? i_s_sfp_set_c[31:16]	: (i_wf_en == 1) ? i_wf_sp[31:16] : i_set_c[31:16];	end
				46 : begin o_xintf_z_to_d_addr <= 46;		o_xintf_z_to_d_din <= (i_sfp_slave) ? i_s_sfp_set_v[15:0]	: (i_wf_en == 3) ? i_wf_sp[15:0] : i_set_v[15:0];	end
				47 : begin o_xintf_z_to_d_addr <= 47;		o_xintf_z_to_d_din <= (i_sfp_slave) ? i_s_sfp_set_v[31:16]	: (i_wf_en == 3) ? i_wf_sp[31:16] : i_set_v[31:16];	end
				default :
					o_xintf_z_to_d_addr <= 0;
			endcase
		end

		else
			o_xintf_z_to_d_addr <= 0;
	end

	// DPBRAM READ
	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
		begin
			o_xintf_d_to_z_addr <= 0;
			o_dsp_max_duty <= 0;
			o_dsp_max_phase <= 0;
			o_dsp_max_frequency <= 0;
			o_dsp_min_frequency <= 0;
			o_dsp_min_v <= 0;
			o_dsp_max_v <= 0;
			o_dsp_min_c <= 0;
			o_dsp_max_c <= 0;
			o_dsp_deadband <= 0;
			o_dsp_sw_freq <= 0;
			o_dsp_p_gain_c <= 0;
			o_dsp_i_gain_c <= 0;
			o_dsp_d_gain_c <= 0;
			o_dsp_p_gain_v <= 0;
			o_dsp_i_gain_v <= 0;
			o_dsp_d_gain_v <= 0;
			o_dsp_set_c <= 0;
			o_dsp_set_v <= 0;
			o_dsp_status <= 0;
		end

		else if (r_state == R_SETUP)
			o_xintf_d_to_z_addr <= 128;

		else if (r_state == READ)
		begin
			case (r_addr_pointer)
				128 : begin o_xintf_d_to_z_addr <= 129;															 end
				129 : begin o_xintf_d_to_z_addr <= 130;		o_dsp_max_duty[15:0]		<= i_xintf_d_to_z_dout;  end
				130 : begin o_xintf_d_to_z_addr <= 131;		o_dsp_max_duty[31:16]		<= i_xintf_d_to_z_dout;  end
				131 : begin o_xintf_d_to_z_addr <= 132;		o_dsp_max_phase[15:0]		<= i_xintf_d_to_z_dout;  end
				132 : begin o_xintf_d_to_z_addr <= 133;		o_dsp_max_phase[31:16]		<= i_xintf_d_to_z_dout;  end
				133 : begin o_xintf_d_to_z_addr <= 134;		o_dsp_max_frequency[15:0]	<= i_xintf_d_to_z_dout;  end
				134 : begin o_xintf_d_to_z_addr <= 135;		o_dsp_max_frequency[31:16]	<= i_xintf_d_to_z_dout;  end
				135 : begin o_xintf_d_to_z_addr <= 136;		o_dsp_min_frequency[15:0]	<= i_xintf_d_to_z_dout;  end
				136 : begin o_xintf_d_to_z_addr <= 137;		o_dsp_min_frequency[31:16]	<= i_xintf_d_to_z_dout;  end
				137 : begin o_xintf_d_to_z_addr <= 138;		o_dsp_min_v[15:0]			<= i_xintf_d_to_z_dout;  end
				138 : begin o_xintf_d_to_z_addr <= 139;		o_dsp_min_v[31:16]			<= i_xintf_d_to_z_dout;  end
				139 : begin o_xintf_d_to_z_addr <= 140;		o_dsp_max_v[15:0]			<= i_xintf_d_to_z_dout;  end
				140 : begin o_xintf_d_to_z_addr <= 141;		o_dsp_max_v[31:16]			<= i_xintf_d_to_z_dout;  end
				141 : begin o_xintf_d_to_z_addr <= 142;		o_dsp_min_c[15:0]			<= i_xintf_d_to_z_dout;  end
				142 : begin o_xintf_d_to_z_addr <= 143;		o_dsp_min_c[31:16]			<= i_xintf_d_to_z_dout;  end
				143 : begin o_xintf_d_to_z_addr <= 144;		o_dsp_max_c[15:0]			<= i_xintf_d_to_z_dout;  end
				144 : begin o_xintf_d_to_z_addr <= 145;		o_dsp_max_c[31:16]			<= i_xintf_d_to_z_dout;  end
				145 : begin o_xintf_d_to_z_addr <= 146;		o_dsp_deadband				<= i_xintf_d_to_z_dout;  end
				146 : begin o_xintf_d_to_z_addr <= 147;		o_dsp_sw_freq				<= i_xintf_d_to_z_dout;  end
				147 : begin o_xintf_d_to_z_addr <= 148;		o_dsp_p_gain_c[15:0]		<= i_xintf_d_to_z_dout;  end
				148 : begin o_xintf_d_to_z_addr <= 149;		o_dsp_p_gain_c[31:16]		<= i_xintf_d_to_z_dout;  end
				149 : begin o_xintf_d_to_z_addr <= 150;		o_dsp_i_gain_c[15:0]		<= i_xintf_d_to_z_dout;  end
				150 : begin o_xintf_d_to_z_addr <= 151;		o_dsp_i_gain_c[31:16]		<= i_xintf_d_to_z_dout;  end
				151 : begin o_xintf_d_to_z_addr <= 152;		o_dsp_d_gain_c[15:0]		<= i_xintf_d_to_z_dout;  end
				152 : begin o_xintf_d_to_z_addr <= 153;		o_dsp_d_gain_c[31:16]		<= i_xintf_d_to_z_dout;  end
				153 : begin o_xintf_d_to_z_addr <= 154;		o_dsp_p_gain_v[15:0]		<= i_xintf_d_to_z_dout;  end
				154 : begin o_xintf_d_to_z_addr <= 155;		o_dsp_p_gain_v[31:16]		<= i_xintf_d_to_z_dout;  end
				155 : begin o_xintf_d_to_z_addr <= 156;		o_dsp_i_gain_v[15:0]		<= i_xintf_d_to_z_dout;  end
				156 : begin o_xintf_d_to_z_addr <= 157;		o_dsp_i_gain_v[31:16]		<= i_xintf_d_to_z_dout;  end
				157 : begin o_xintf_d_to_z_addr <= 158;		o_dsp_d_gain_v[15:0]		<= i_xintf_d_to_z_dout;  end
				158 : begin o_xintf_d_to_z_addr <= 159;		o_dsp_d_gain_v[31:16]		<= i_xintf_d_to_z_dout;  end
				159 : begin o_xintf_d_to_z_addr <= 160;		o_dsp_set_c[15:0]			<= i_xintf_d_to_z_dout;  end
				160 : begin o_xintf_d_to_z_addr <= 161;		o_dsp_set_c[31:16]			<= i_xintf_d_to_z_dout;  end
				161 : begin o_xintf_d_to_z_addr <= 162;		o_dsp_set_v[15:0]			<= i_xintf_d_to_z_dout;  end
				162 : begin o_xintf_d_to_z_addr <= 163;		o_dsp_set_v[31:16]			<= i_xintf_d_to_z_dout;  end
				162 : begin o_xintf_d_to_z_addr <= 174;		o_dsp_status[31:16]			<= i_xintf_d_to_z_dout;  end
				default :
				begin
					o_xintf_d_to_z_addr <= o_xintf_d_to_z_addr;
					o_dsp_max_duty <= o_dsp_max_duty;
					o_dsp_max_phase <= o_dsp_max_phase;
					o_dsp_max_frequency <= o_dsp_max_frequency;
					o_dsp_min_frequency <= o_dsp_min_frequency;
					o_dsp_min_v <= o_dsp_min_v;
					o_dsp_max_v <= o_dsp_max_v;
					o_dsp_min_c <= o_dsp_min_c;
					o_dsp_max_c <= o_dsp_max_c;
					o_dsp_deadband <= o_dsp_deadband;
					o_dsp_sw_freq <= o_dsp_sw_freq;
					o_dsp_p_gain_c <= o_dsp_p_gain_c;
					o_dsp_i_gain_c <= o_dsp_i_gain_c;
					o_dsp_d_gain_c <= o_dsp_d_gain_c;
					o_dsp_p_gain_v <= o_dsp_p_gain_v;
					o_dsp_i_gain_v <= o_dsp_i_gain_v;
					o_dsp_d_gain_v <= o_dsp_d_gain_v;
					o_dsp_set_c <= o_dsp_set_c;
					o_dsp_set_v <= o_dsp_set_v;
					o_dsp_status <= o_dsp_status;
				end
			endcase
		end

		else
		begin
			o_xintf_d_to_z_addr <= o_xintf_d_to_z_addr;
			o_dsp_max_duty <= o_dsp_max_duty;
			o_dsp_max_phase <= o_dsp_max_phase;
			o_dsp_max_frequency <= o_dsp_max_frequency;
			o_dsp_min_frequency <= o_dsp_min_frequency;
			o_dsp_min_v <= o_dsp_min_v;
			o_dsp_max_v <= o_dsp_max_v;
			o_dsp_min_c <= o_dsp_min_c;
			o_dsp_max_c <= o_dsp_max_c;
			o_dsp_deadband <= o_dsp_deadband;
			o_dsp_sw_freq <= o_dsp_sw_freq;
			o_dsp_p_gain_c <= o_dsp_p_gain_c;
			o_dsp_i_gain_c <= o_dsp_i_gain_c;
			o_dsp_d_gain_c <= o_dsp_d_gain_c;
			o_dsp_p_gain_v <= o_dsp_p_gain_v;
			o_dsp_i_gain_v <= o_dsp_i_gain_v;
			o_dsp_d_gain_v <= o_dsp_d_gain_v;
			o_dsp_set_c <= o_dsp_set_c;
			o_dsp_set_v <= o_dsp_set_v;
			o_dsp_status <= o_dsp_status;
		end
	end

	assign o_w_valid = (w_state == DELAY);
	assign o_wf_set_flag = (w_state == W_SETUP);
endmodule