`timescale 1 ns / 1 ps
/*

24.09.10 :	ìµœì´ˆ ?ƒ?„±

24.09.24 :	TX?˜ FSM?´ Master?¸ ê²½ìš°?—ë§? ?‹¤?–‰?˜?Š” ê²ƒì„ ?‚­? œ


*/

module DSP_Handler
(
    input i_clk,
    input i_rst,

	input i_zynq_sfp_en,
	input [1:0] i_sfp_id,
	input i_axi_pwm_en,

	input [31:0] i_zynq_intl,
	input i_w_ready,
	output o_w_valid,
	input i_r_valid,

    // DPBRAM WRITE
	output reg [8:0] o_xintf_w_ram_addr,
	output reg [15:0] o_xintf_w_ram_din,
	output reg o_xintf_w_ram_ce,

    // WRITE
	input [15:0] i_aurora_set_mode,
	input [15:0] i_aurora_set_cmd,
	input [31:0] i_d_gain_c,
	input [31:0] i_d_gain_v,
	//
	input [31:0] i_p_gain_c,
	input [31:0] i_i_gain_c,
	input [31:0] i_p_gain_v,
	input [31:0] i_i_gain_v,
	//
	input [31:0] i_c_adc_data,
    input [31:0] i_v_adc_data,
	input [12:0] i_zynq_status,
    input [15:0] i_write_index,
	input [31:0] i_index_data,
	input [31:0] i_set_c,
	input [31:0] i_max_duty,
    input [31:0] i_max_phase,
    input [31:0] i_max_freq,
    input [31:0] i_min_freq,
	//
	input [31:0] i_min_c,
	input [31:0] i_max_c,
	input [31:0] i_min_v,
	input [31:0] i_max_v,
	input [15:0] i_deadband,
	input [15:0] i_sw_freq,
	//
	input [31:0] i_set_v,
	input [31:0] i_master_pi_param,
	input [31:0] i_slave_1_c,
	input [31:0] i_slave_1_v,
	input [31:0] i_slave_2_c,
	input [31:0] i_slave_2_v,
	input [31:0] i_slave_3_c,
	input [31:0] i_slave_3_v,
	input [31:0] i_slave_1_status,
	input [31:0] i_slave_2_status,
	input [31:0] i_slave_3_status,
	input [2:0] i_slave_count,

    // DPBRAM READ
    input [15:0] i_xintf_r_ram_dout,
	output reg [8:0] o_xintf_r_ram_addr,
	output reg o_xintf_r_ram_ce,

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
	output reg [31:0] o_dsp_pi_param,				// ?˜„?¬ dsp duty ê°?
	output reg [31:0] o_slave_c,
	output reg [31:0] o_slave_v,
	output reg [31:0] o_slave_status,
	output reg [31:0] o_wf_read_cnt,
	output reg [15:0] o_dsp_status,
	output reg [15:0] o_dsp_cmd,
	output reg [15:0] o_dsp_ver,

	// SFP CMD Data
	input i_sfp_pwm_en,
	input [15:0] i_sfp_zynq_ver,
	input [31:0] i_sfp_min_c,
	input [31:0] i_sfp_max_c,
	input [31:0] i_sfp_min_v,
	input [31:0] i_sfp_max_v,
	input [15:0] i_sfp_deadband,
	input [15:0] i_sfp_sw_freq,
	input [31:0] i_sfp_p_gain_c,
	input [31:0] i_sfp_i_gain_c,
	input [31:0] i_sfp_d_gain_c,
	input [31:0] i_sfp_p_gain_v,
	input [31:0] i_sfp_i_gain_v,
	input [31:0] i_sfp_d_gain_v,
	input i_sfp_intl_clr,
	input [31:0] i_sfp_set_c,
	input [31:0] i_sfp_set_v,
	input [15:0] i_sfp_1_stat,
	input [15:0] i_sfp_2_stat,
	input [15:0] i_sfp_3_stat,

	input [31:0] i_m_sfp_1_data,
	input [31:0] i_m_sfp_2_data,
	input [31:0] i_m_sfp_3_data,

	output o_hw_pwm_en,
	output o_intl_clr,
	output o_dsp_pwm_en,
	
	// DC
	input [31:0] i_dc_v_adc,
	input [31:0] i_dc_c_adc
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
    
    reg [31:0] index_array [0:30];

    reg [1:0] r_state;
    reg [2:0] w_state;

    reg [8:0] w_addr_pointer;
    reg [8:0] r_addr_pointer;

	reg [15:0] prev_write_index;
	reg [15:0] prev_index_data;

	wire [31:0] set_c;
	wire [31:0] set_v;
//	wire dsp_pwm_en;
	reg [25:0] on_cnt;
    reg [25:0] off_cnt;
	wire [32:0] zynq_intl;
	wire [15:0] zynq_status;

	// SFP
	wire pwm_en;
	wire [15:0] zynq_firmware_ver;
	wire [31:0] min_c;
	wire [31:0] max_c;
	wire [31:0] min_v;
	wire [31:0] max_v;
	wire [15:0] deadband;
	wire [15:0] sw_freq;
	wire [31:0] p_gain_c;
	wire [31:0] i_gain_c;
	wire [31:0] d_gain_c;
	wire [31:0] p_gain_v;
	wire [31:0] i_gain_v;
	wire [31:0] d_gain_v;
	wire [32:0] total_zynq_intl;
	
	
	genvar i;

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			w_state <= W_IDLE;

		else if (w_state == W_IDLE)
			w_state <= W_SETUP;

		else if(w_state == W_SETUP)
			w_state <= WRITE;

		else if(w_state == WRITE)
		begin
			if (w_addr_pointer == 69)
				w_state <= DELAY;

			else
				w_state <= WRITE;
		end

		else if(w_state == DELAY)
		begin
			if (i_w_ready)
				w_state <= W_DONE;

			else
				w_state <= DELAY;
		end

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
		begin
			if (i_r_valid)
				r_state <= READ;

			else
				r_state <= R_SETUP;
		end
			
		else if(r_state == READ)
		begin
			if (r_addr_pointer == 176)
				r_state <= R_DONE;

			else
				r_state <= READ;
		end
		

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
				o_xintf_w_ram_ce <= 0;

			else if ((w_state == W_SETUP) || (w_state == WRITE))
				o_xintf_w_ram_ce <= 1;

			else
				o_xintf_w_ram_ce <= 0;
	end

	always @(posedge i_clk or negedge i_rst)
    begin
            if (~i_rst)
				o_xintf_r_ram_ce <= 0;

			else if ((r_state == R_SETUP) || (r_state == READ))
				o_xintf_r_ram_ce <= 1;

			else
				o_xintf_r_ram_ce <= 0;
	end

    // DPBRAM WRITE
    always @(posedge i_clk or negedge i_rst)
    begin
            if (~i_rst)
            begin
                o_xintf_w_ram_din <= 0;
                o_xintf_w_ram_addr <= 0;
            end

        else if (w_state == WRITE)
        begin
            case (w_addr_pointer)
				0  : begin o_xintf_w_ram_addr <= 0 ;		o_xintf_w_ram_din <= i_aurora_set_mode;				end
				1  : begin o_xintf_w_ram_addr <= 1 ;		o_xintf_w_ram_din <= i_aurora_set_cmd;				end
//				2  : begin o_xintf_w_ram_addr <= 2 ;		o_xintf_w_ram_din <= i_m_sfp_1_data[15:0];			end		// aurora_set_value_0
//				3  : begin o_xintf_w_ram_addr <= 3 ;		o_xintf_w_ram_din <= i_m_sfp_1_data[31:16];			end		// aurora_set_value_0
//				4  : begin o_xintf_w_ram_addr <= 4 ;		o_xintf_w_ram_din <= i_m_sfp_2_data[15:0];			end		// aurora_set_value_1
//				5  : begin o_xintf_w_ram_addr <= 5 ;		o_xintf_w_ram_din <= i_m_sfp_2_data[31:16];			end		// aurora_set_value_1
                2  : begin o_xintf_w_ram_addr <= 2 ;		o_xintf_w_ram_din <= i_dc_v_adc[15:0];			    end		// i_dc_v_adc
				3  : begin o_xintf_w_ram_addr <= 3 ;		o_xintf_w_ram_din <= i_dc_v_adc[31:16];			    end		// i_dc_v_adc
				4  : begin o_xintf_w_ram_addr <= 4 ;		o_xintf_w_ram_din <= i_dc_c_adc[15:0];			    end		// i_dc_c_adc
				5  : begin o_xintf_w_ram_addr <= 5 ;		o_xintf_w_ram_din <= i_dc_c_adc[31:16];			    end		// i_dc_c_adc
				6  : begin o_xintf_w_ram_addr <= 6 ;		o_xintf_w_ram_din <= i_m_sfp_3_data[15:0];			end		// aurora_set_value_2
				7  : begin o_xintf_w_ram_addr <= 7 ;		o_xintf_w_ram_din <= i_m_sfp_3_data[31:16];			end		// aurora_set_value_2
				8  : begin o_xintf_w_ram_addr <= 8 ;		o_xintf_w_ram_din <= i_max_duty[15:0];				end
				9  : begin o_xintf_w_ram_addr <= 9 ;		o_xintf_w_ram_din <= i_max_duty[31:16];				end
				10 : begin o_xintf_w_ram_addr <= 10;		o_xintf_w_ram_din <= i_max_phase[15:0];				end
				11 : begin o_xintf_w_ram_addr <= 11;		o_xintf_w_ram_din <= i_max_phase[31:16];			end
				12 : begin o_xintf_w_ram_addr <= 12;		o_xintf_w_ram_din <= i_max_freq[15:0];				end 
				13 : begin o_xintf_w_ram_addr <= 13;		o_xintf_w_ram_din <= i_max_freq[31:16];				end
				14 : begin o_xintf_w_ram_addr <= 14;		o_xintf_w_ram_din <= i_min_freq[15:0];				end
				15 : begin o_xintf_w_ram_addr <= 15;		o_xintf_w_ram_din <= i_min_freq[31:16];				end
				16 : begin o_xintf_w_ram_addr <= 16;		o_xintf_w_ram_din <= i_min_v[15:0];					end
				17 : begin o_xintf_w_ram_addr <= 17;		o_xintf_w_ram_din <= i_min_v[31:16];					end
				18 : begin o_xintf_w_ram_addr <= 18;		o_xintf_w_ram_din <= i_max_v[15:0];					end
				19 : begin o_xintf_w_ram_addr <= 19;		o_xintf_w_ram_din <= i_max_v[31:16];					end
				20 : begin o_xintf_w_ram_addr <= 20;		o_xintf_w_ram_din <= i_min_c[15:0];					end
				21 : begin o_xintf_w_ram_addr <= 21;		o_xintf_w_ram_din <= i_min_c[31:16];					end
				22 : begin o_xintf_w_ram_addr <= 22;		o_xintf_w_ram_din <= i_max_c[15:0];					end
				23 : begin o_xintf_w_ram_addr <= 23;		o_xintf_w_ram_din <= i_max_c[31:16];					end
				24 : begin o_xintf_w_ram_addr <= 24;		o_xintf_w_ram_din <= i_deadband;						end
				25 : begin o_xintf_w_ram_addr <= 25;		o_xintf_w_ram_din <= i_sw_freq;						end
				26 : begin o_xintf_w_ram_addr <= 26;		o_xintf_w_ram_din <= i_p_gain_c[15:0];				end
				27 : begin o_xintf_w_ram_addr <= 27;		o_xintf_w_ram_din <= i_p_gain_c[31:16];				end
				28 : begin o_xintf_w_ram_addr <= 28;		o_xintf_w_ram_din <= i_i_gain_c[15:0];				end
				29 : begin o_xintf_w_ram_addr <= 29;		o_xintf_w_ram_din <= i_i_gain_c[31:16];				end
				30 : begin o_xintf_w_ram_addr <= 30;		o_xintf_w_ram_din <= i_d_gain_c[15:0];				end
				31 : begin o_xintf_w_ram_addr <= 31;		o_xintf_w_ram_din <= i_d_gain_c[31:16];				end
				32 : begin o_xintf_w_ram_addr <= 32;		o_xintf_w_ram_din <= i_p_gain_v[15:0];				end
				33 : begin o_xintf_w_ram_addr <= 33;		o_xintf_w_ram_din <= i_p_gain_v[31:16];				end
				34 : begin o_xintf_w_ram_addr <= 34;		o_xintf_w_ram_din <= i_i_gain_v[15:0];				end
				35 : begin o_xintf_w_ram_addr <= 35;		o_xintf_w_ram_din <= i_i_gain_v[31:16];				end
				36 : begin o_xintf_w_ram_addr <= 36;		o_xintf_w_ram_din <= i_d_gain_v[15:0];				end
				37 : begin o_xintf_w_ram_addr <= 37;		o_xintf_w_ram_din <= i_d_gain_v[31:16];				end
				38 : begin o_xintf_w_ram_addr <= 38;		o_xintf_w_ram_din <= 0;				end
                39 : begin o_xintf_w_ram_addr <= 39;		o_xintf_w_ram_din <= 0;			        end
                40 : begin o_xintf_w_ram_addr <= 40;		o_xintf_w_ram_din <= i_c_adc_data[15:0];			end
                41 : begin o_xintf_w_ram_addr <= 41;		o_xintf_w_ram_din <= i_c_adc_data[31:16];			end
                42 : begin o_xintf_w_ram_addr <= 42;		o_xintf_w_ram_din <= i_v_adc_data[15:0];			end
				43 : begin o_xintf_w_ram_addr <= 43;		o_xintf_w_ram_din <= i_v_adc_data[31:16];			end
                44 : begin o_xintf_w_ram_addr <= 44;		o_xintf_w_ram_din <= i_set_c[15:0];					end
                45 : begin o_xintf_w_ram_addr <= 45;		o_xintf_w_ram_din <= i_set_c[31:16];					end
                46 : begin o_xintf_w_ram_addr <= 46;		o_xintf_w_ram_din <= i_set_v[15:0];					end
                47 : begin o_xintf_w_ram_addr <= 47;		o_xintf_w_ram_din <= i_set_v[31:16];					end
                48 : begin o_xintf_w_ram_addr <= 48;		o_xintf_w_ram_din <= i_master_pi_param[15:0];		end
                49 : begin o_xintf_w_ram_addr <= 49;		o_xintf_w_ram_din <= i_master_pi_param[31:16];		end
				50 : begin o_xintf_w_ram_addr <= 50;		o_xintf_w_ram_din <= i_slave_1_c[15:0];				end
				51 : begin o_xintf_w_ram_addr <= 51;		o_xintf_w_ram_din <= i_slave_1_c[31:16];			end
				52 : begin o_xintf_w_ram_addr <= 52;		o_xintf_w_ram_din <= i_slave_1_v[15:0];				end
				53 : begin o_xintf_w_ram_addr <= 53;		o_xintf_w_ram_din <= i_slave_1_v[31:16];			end
				54 : begin o_xintf_w_ram_addr <= 54;		o_xintf_w_ram_din <= i_slave_2_c[15:0];				end
				55 : begin o_xintf_w_ram_addr <= 55;		o_xintf_w_ram_din <= i_slave_2_c[31:16];			end
				56 : begin o_xintf_w_ram_addr <= 56;		o_xintf_w_ram_din <= i_slave_2_v[15:0];				end
				57 : begin o_xintf_w_ram_addr <= 57;		o_xintf_w_ram_din <= i_slave_2_v[31:16];			end
				58 : begin o_xintf_w_ram_addr <= 58;		o_xintf_w_ram_din <= i_slave_3_c[15:0];				end
				59 : begin o_xintf_w_ram_addr <= 59;		o_xintf_w_ram_din <= i_slave_3_c[31:16];			end
				60 : begin o_xintf_w_ram_addr <= 60;		o_xintf_w_ram_din <= i_slave_3_v[15:0];				end
				61 : begin o_xintf_w_ram_addr <= 61;		o_xintf_w_ram_din <= i_slave_3_v[31:16];			end
				62 : begin o_xintf_w_ram_addr <= 62;		o_xintf_w_ram_din <= i_slave_1_status[15:0];		end
				63 : begin o_xintf_w_ram_addr <= 63;		o_xintf_w_ram_din <= i_slave_1_status[31:16];		end
				64 : begin o_xintf_w_ram_addr <= 64;		o_xintf_w_ram_din <= i_slave_2_status[15:0];		end
				65 : begin o_xintf_w_ram_addr <= 65;		o_xintf_w_ram_din <= i_slave_2_status[31:16];		end
				66 : begin o_xintf_w_ram_addr <= 66;		o_xintf_w_ram_din <= i_slave_3_status[15:0];		end
				67 : begin o_xintf_w_ram_addr <= 67;		o_xintf_w_ram_din <= i_slave_3_status[31:16];		end
				68 : begin o_xintf_w_ram_addr <= 68;		o_xintf_w_ram_din <= i_slave_count;		            end

                default :
                    o_xintf_w_ram_addr <= 0;
            endcase
        end

        else
            o_xintf_w_ram_addr <= 0;
    end

    // DPBRAM READ
    always @(posedge i_clk or negedge i_rst)
    begin
		if (~i_rst)
        begin
			o_xintf_r_ram_addr <= 0;
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
			o_dsp_pi_param <= 0;
			o_slave_c <= 0;
			o_slave_v <= 0;
			o_slave_status <= 0;
			o_wf_read_cnt <= 0;
			o_dsp_status <= 0;
			o_dsp_cmd <= 0;
        end

        else if (r_state == R_SETUP)
            o_xintf_r_ram_addr <= 128;

        else if (r_state == READ)
        begin
            case (r_addr_pointer)
            	128 : begin o_xintf_r_ram_addr <= 129;															end
				129 : begin o_xintf_r_ram_addr <= 130;		o_dsp_max_duty[15:0]		<= i_xintf_r_ram_dout;  end
				130 : begin o_xintf_r_ram_addr <= 131;		o_dsp_max_duty[31:16]		<= i_xintf_r_ram_dout;  end
				131 : begin o_xintf_r_ram_addr <= 132;		o_dsp_max_phase[15:0]		<= i_xintf_r_ram_dout;  end
				132 : begin o_xintf_r_ram_addr <= 133;		o_dsp_max_phase[31:16]		<= i_xintf_r_ram_dout;  end
				133 : begin o_xintf_r_ram_addr <= 134;		o_dsp_max_frequency[15:0]	<= i_xintf_r_ram_dout;  end
				134 : begin o_xintf_r_ram_addr <= 135;		o_dsp_max_frequency[31:16]	<= i_xintf_r_ram_dout;  end
				135 : begin o_xintf_r_ram_addr <= 136;		o_dsp_min_frequency[15:0]	<= i_xintf_r_ram_dout;  end
                136 : begin o_xintf_r_ram_addr <= 137;		o_dsp_min_frequency[31:16]	<= i_xintf_r_ram_dout;  end
                137 : begin o_xintf_r_ram_addr <= 138;		o_dsp_min_v[15:0]			<= i_xintf_r_ram_dout;  end
				138 : begin o_xintf_r_ram_addr <= 139;		o_dsp_min_v[31:16]			<= i_xintf_r_ram_dout;  end
				139 : begin o_xintf_r_ram_addr <= 140;		o_dsp_max_v[15:0]			<= i_xintf_r_ram_dout;  end
				140 : begin o_xintf_r_ram_addr <= 141;		o_dsp_max_v[31:16]			<= i_xintf_r_ram_dout;  end
				141 : begin o_xintf_r_ram_addr <= 142;		o_dsp_min_c[15:0]			<= i_xintf_r_ram_dout;  end
				142 : begin o_xintf_r_ram_addr <= 143;		o_dsp_min_c[31:16]			<= i_xintf_r_ram_dout;  end
				143 : begin o_xintf_r_ram_addr <= 144;		o_dsp_max_c[15:0]			<= i_xintf_r_ram_dout;  end
                144 : begin o_xintf_r_ram_addr <= 145;		o_dsp_max_c[31:16]			<= i_xintf_r_ram_dout;  end
                145 : begin o_xintf_r_ram_addr <= 146;		o_dsp_deadband				<= i_xintf_r_ram_dout;  end
				146 : begin o_xintf_r_ram_addr <= 147;		o_dsp_sw_freq				<= i_xintf_r_ram_dout;  end
				147 : begin o_xintf_r_ram_addr <= 148;		o_dsp_p_gain_c[15:0]		<= i_xintf_r_ram_dout;  end
				148 : begin o_xintf_r_ram_addr <= 149;		o_dsp_p_gain_c[31:16]		<= i_xintf_r_ram_dout;  end
				149 : begin o_xintf_r_ram_addr <= 150;		o_dsp_i_gain_c[15:0]		<= i_xintf_r_ram_dout;  end
				150 : begin o_xintf_r_ram_addr <= 151;		o_dsp_i_gain_c[31:16]		<= i_xintf_r_ram_dout;  end
				151 : begin o_xintf_r_ram_addr <= 152;		o_dsp_d_gain_c[15:0]		<= i_xintf_r_ram_dout;  end
                152 : begin o_xintf_r_ram_addr <= 153;		o_dsp_d_gain_c[31:16]		<= i_xintf_r_ram_dout;  end
                153 : begin o_xintf_r_ram_addr <= 154;		o_dsp_p_gain_v[15:0]		<= i_xintf_r_ram_dout;  end
				154 : begin o_xintf_r_ram_addr <= 155;		o_dsp_p_gain_v[31:16]		<= i_xintf_r_ram_dout;  end
				155 : begin o_xintf_r_ram_addr <= 156;		o_dsp_i_gain_v[15:0]		<= i_xintf_r_ram_dout;  end
				156 : begin o_xintf_r_ram_addr <= 157;		o_dsp_i_gain_v[31:16]		<= i_xintf_r_ram_dout;  end
				157 : begin o_xintf_r_ram_addr <= 158;		o_dsp_d_gain_v[15:0]		<= i_xintf_r_ram_dout;  end
				158 : begin o_xintf_r_ram_addr <= 159;		o_dsp_d_gain_v[31:16]		<= i_xintf_r_ram_dout;  end
                159 : begin o_xintf_r_ram_addr <= 160;		o_dsp_set_c[15:0]			<= i_xintf_r_ram_dout;  end
                160 : begin o_xintf_r_ram_addr <= 161;		o_dsp_set_c[31:16]			<= i_xintf_r_ram_dout;  end
				161 : begin o_xintf_r_ram_addr <= 162;		o_dsp_set_v[15:0]			<= i_xintf_r_ram_dout;  end
				162 : begin o_xintf_r_ram_addr <= 163;		o_dsp_set_v[31:16]			<= i_xintf_r_ram_dout;  end
				163 : begin o_xintf_r_ram_addr <= 164;		o_dsp_pi_param[15:0]		<= i_xintf_r_ram_dout;  end
				164 : begin o_xintf_r_ram_addr <= 165;		o_dsp_pi_param[31:16]		<= i_xintf_r_ram_dout;  end
				165 : begin o_xintf_r_ram_addr <= 166;		o_slave_c[15:0]				<= i_xintf_r_ram_dout;  end
				166 : begin o_xintf_r_ram_addr <= 167;		o_slave_c[31:16]			<= i_xintf_r_ram_dout;  end
                167 : begin o_xintf_r_ram_addr <= 168;		o_slave_v[15:0]				<= i_xintf_r_ram_dout;  end
                168 : begin o_xintf_r_ram_addr <= 169;		o_slave_v[31:16]			<= i_xintf_r_ram_dout;  end
				169 : begin o_xintf_r_ram_addr <= 170;		o_slave_status[15:0]		<= i_xintf_r_ram_dout;	end
				170 : begin o_xintf_r_ram_addr <= 171;		o_slave_status[31:16]		<= i_xintf_r_ram_dout;	end
				171 : begin o_xintf_r_ram_addr <= 172;		o_wf_read_cnt[15:0]			<= i_xintf_r_ram_dout;  end
				172 : begin o_xintf_r_ram_addr <= 173;		o_wf_read_cnt[31:16]		<= i_xintf_r_ram_dout;  end
				173 : begin o_xintf_r_ram_addr <= 174;		o_dsp_status					<= i_xintf_r_ram_dout;  end
				174 : begin o_xintf_r_ram_addr <= 175;		o_dsp_cmd					<= i_xintf_r_ram_dout;  end
				175 : begin o_xintf_r_ram_addr <= 176;															end
				176 : begin o_xintf_r_ram_addr <= 177;		o_dsp_ver					<= i_xintf_r_ram_dout;  end
                 
                default :
                begin
					o_xintf_r_ram_addr <= o_xintf_r_ram_addr;
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
					o_dsp_pi_param <= o_dsp_pi_param;
					o_slave_c <= o_slave_c;
					o_slave_v <= o_slave_v;
					o_slave_status <= o_slave_status;
					o_wf_read_cnt <= o_wf_read_cnt;
					o_dsp_status <= o_dsp_status;
					o_dsp_cmd <= o_dsp_cmd;
                end
            endcase
        end

        else
        begin
			o_xintf_r_ram_addr <= o_xintf_r_ram_addr;
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
			o_dsp_pi_param <= o_dsp_pi_param;
			o_slave_c <= o_slave_c;
			o_slave_v <= o_slave_v;
			o_slave_status <= o_slave_status;
			o_wf_read_cnt <= o_wf_read_cnt;
			o_dsp_status <= o_dsp_status;
			o_dsp_cmd <= o_dsp_cmd;
		end
    end
    
	assign o_w_valid = (w_state == DELAY) ? 1 : 0;					
endmodule