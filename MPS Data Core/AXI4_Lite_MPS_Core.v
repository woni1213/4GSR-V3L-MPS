`timescale 1 ns / 1 ps

module AXI4_Lite_MPS_Core #
(
	parameter integer C_S_AXI_DATA_WIDTH	= 0,
	parameter integer C_S_AXI_ADDR_NUM 		= 0,
	parameter integer C_S_AXI_ADDR_WIDTH	= 0
)
(
	input [8:0]			i_xintf_addr,
	output [15:0]		o_xintf_z_to_d_data,
	input [15:0]		i_xintf_d_to_z_data,
	input				i_dsp_we,

	input [15:0] 		i_zynq_status,
	// ADC Data
	input [31:0]		i_c_data,
	input [31:0]		i_v_data,
	input [31:0]		i_dc_c_data,
	input [31:0]		i_dc_v_data,
	input [31:0]		i_phase_r_data,
	input [31:0]		i_phase_s_data,
	input [31:0]		i_phase_t_data,
	input [31:0]		i_igbt_t_data,
	input [31:0]		i_i_inductor_t_data,
	input [31:0]		i_o_inductor_t_data,
	input [31:0]		i_phase_rms_r,
	input [31:0]		i_phase_rms_s,
	input [31:0]		i_phase_rms_t,

	output reg [3:0] 	o_mps_status,
	output reg [31:0] 	o_set_c,
	output reg [31:0] 	o_set_v,
	output reg [31:0] 	o_max_duty,
	output reg [31:0] 	o_max_phase,
	output reg [31:0] 	o_max_freq,
	output reg [31:0] 	o_min_freq,
	output reg [31:0] 	o_min_c,
	output reg [31:0] 	o_max_c,
	output reg [31:0] 	o_min_v,
	output reg [31:0] 	o_max_v,
	output reg [15:0] 	o_deadband,
	output reg [15:0] 	o_sw_freq,
	output reg [31:0] 	o_p_gain_c,
	output reg [31:0] 	o_i_gain_c,
	output reg [31:0] 	o_d_gain_c,
	output reg [31:0] 	o_p_gain_v,
	output reg [31:0] 	o_i_gain_v,
	output reg [31:0] 	o_d_gain_v,

	input [31:0] i_dsp_max_duty,
	input [31:0] i_dsp_max_phase,
	input [31:0] i_dsp_max_frequency,
	input [31:0] i_dsp_min_frequency,
	input [31:0] i_dsp_min_v,
	input [31:0] i_dsp_max_v,
	input [31:0] i_dsp_min_c,
	input [31:0] i_dsp_max_c,
	input [15:0] i_dsp_deadband,
	input [15:0] i_dsp_sw_freq,
	input [31:0] i_dsp_p_gain_c,
	input [31:0] i_dsp_i_gain_c,
	input [31:0] i_dsp_d_gain_c,
	input [31:0] i_dsp_p_gain_v,
	input [31:0] i_dsp_i_gain_v,
	input [31:0] i_dsp_d_gain_v,
	input [31:0] i_dsp_set_c,
	input [31:0] i_dsp_set_v,
	input [31:0] i_dsp_status,

	output reg o_sfp_en,
	output reg o_sfp_id,

	output reg [1279:0] o_m_sfp_data,

	input [31:0] i_sfp_c,
	input [31:0] i_sfp_v,
	input [31:0] i_sfp_dc_c,
	input [31:0] i_sfp_dc_v,
	input [31:0] i_sfp_phase_r_rms,
	input [31:0] i_sfp_phase_s_rms,
	input [31:0] i_sfp_phase_t_rms,
	input [31:0] i_sfp_igbt_t,
	input [31:0] i_sfp_i_inductor_t,
	input [31:0] i_sfp_o_inductor_t,
	input [31:0] i_sfp_intl,
	input [31:0] i_sfp_fsm,

	input [31:0] i_sfp_c_over_sp,
	input [31:0] i_sfp_v_over_sp,
	input [31:0] i_sfp_dc_c_over_sp,
	input [31:0] i_sfp_dc_v_over_sp,
	input [31:0] i_sfp_igbt_t_over_sp,
	input [31:0] i_sfp_i_id_t_over_sp,
	input [31:0] i_sfp_o_id_t_over_sp,
	input [31:0] i_sfp_c_data_thresh,
	input [31:0] i_sfp_c_cnt_thresh,
	input [31:0] i_sfp_c_period,
	input [31:0] i_sfp_c_cycle_cnt,
	input [31:0] i_sfp_c_diff,
	input [31:0] i_sfp_c_delay,
	input [31:0] i_sfp_v_data_thresh,
	input [31:0] i_sfp_v_cnt_thresh,
	input [31:0] i_sfp_v_period,
	input [31:0] i_sfp_v_cycle_cnt,
	input [31:0] i_sfp_v_diff,
	input [31:0] i_sfp_v_delay,

	input S_AXI_ACLK,
	input S_AXI_ARESETN,
	input [C_S_AXI_ADDR_WIDTH - 1 : 0] S_AXI_AWADDR,
	input [2:0] S_AXI_AWPROT,
	input S_AXI_AWVALID,
	output S_AXI_AWREADY,
	input [C_S_AXI_DATA_WIDTH - 1 : 0] S_AXI_WDATA,
	input [(C_S_AXI_DATA_WIDTH / 8) - 1 : 0] S_AXI_WSTRB,
	input S_AXI_WVALID,
	output S_AXI_WREADY,
	output [1:0] S_AXI_BRESP,
	output wire S_AXI_BVALID,
	input S_AXI_BREADY,
	input [C_S_AXI_ADDR_WIDTH - 1 : 0] S_AXI_ARADDR,
	input [2 : 0] S_AXI_ARPROT,
	input S_AXI_ARVALID,
	output S_AXI_ARREADY,
	output [C_S_AXI_DATA_WIDTH - 1 : 0] S_AXI_RDATA,
	output [1 : 0] S_AXI_RRESP,
	output S_AXI_RVALID,
	input S_AXI_RREADY
);

	reg [C_S_AXI_ADDR_WIDTH - 1 : 0] axi_awaddr;
	reg axi_awready;
	reg axi_wready;
	reg [1:0] axi_bresp;
	reg axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
	reg axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
	reg [1:0] axi_rresp;
	reg axi_rvalid;

	localparam integer ADDR_LSB = 2;
	localparam integer OPT_MEM_ADDR_BITS = $clog2(C_S_AXI_ADDR_NUM) - 1;

	// slv_reg IO Type Select. 0 : Input, 1 : Output
	// slv_reg Start to LSB
	localparam [C_S_AXI_ADDR_NUM - 1 : 0] io_sel = 64'hFFFF_FFFF_FFFF_FFFF;	// 0 : Input, 1 : Output

	reg [C_S_AXI_DATA_WIDTH - 1 : 0] slv_reg[C_S_AXI_ADDR_NUM - 1 : 0];

	wire slv_reg_rden;
	wire slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
	integer byte_index;
	reg aw_en;

	genvar i;
	integer j;

	// Address Write (AW) Flag
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_awready <= 1'b0;
			aw_en <= 1'b1;
		end

		else
		begin
			if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
			begin
				axi_awready <= 1'b1;
				aw_en <= 1'b0;
			end

			else if (S_AXI_BREADY && axi_bvalid)
			begin
				aw_en <= 1'b1;
				axi_awready <= 1'b0;
			end

			else
	          axi_awready <= 1'b0;
	    end 
	end

	// Address Write (AW)
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
			axi_awaddr <= 0;

		else
		begin
			if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
				axi_awaddr <= S_AXI_AWADDR;
		end

	end

	// Write Data Flag (W)
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
			axi_wready <= 1'b0;

		else
		begin
			if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
				axi_wready <= 1'b1;
			else
				axi_wready <= 1'b0;
		end 
	end

	// Write Data (M to S)
	generate
	for (i = 0; i < C_S_AXI_ADDR_NUM; i = i + 1)
	begin
		always @( posedge S_AXI_ACLK )
		begin
		if (io_sel[i])
		begin
			if (S_AXI_ARESETN == 1'b0)
				slv_reg[i] <= 0;

			else if (slv_reg_wren)
				if (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == i)
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
						if ( S_AXI_WSTRB[byte_index] == 1 ) 
							slv_reg[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];

			else
				slv_reg[i] <= slv_reg[i];
			end
		end
	end
	endgenerate

	// Response Flag (B)
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_bvalid  <= 0;
			axi_bresp   <= 2'b0;
		end

		else
		begin
			if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
			begin
				axi_bvalid <= 1'b1;
				axi_bresp  <= 2'b0;
			end

			else
			begin
				if (S_AXI_BREADY && axi_bvalid) 
					axi_bvalid <= 1'b0; 
			end
		end
	end

	// Address Read Flag (AR)
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_arready <= 1'b0;
			axi_araddr  <= 32'b0;
		end

		else
		begin
			if (~axi_arready && S_AXI_ARVALID)
			begin
				axi_arready <= 1'b1;
				axi_araddr  <= S_AXI_ARADDR;
			end

			else
				axi_arready <= 1'b0;
		end
	end

	// Read Data Flag (R)
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_rvalid <= 0;
			axi_rresp  <= 0;
		end 

		else
		begin
			if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
			begin
				axi_rvalid <= 1'b1;
				axi_rresp  <= 2'b0;
			end

			else if (axi_rvalid && S_AXI_RREADY)
				axi_rvalid <= 1'b0;
		end
	end

	// Read Data (S to M)
	always @(*)
	begin
		reg_data_out = 0;

		for (j = 0; j < C_S_AXI_ADDR_NUM; j = j + 1)
			if (axi_araddr[ADDR_LSB + OPT_MEM_ADDR_BITS : ADDR_LSB] == j)
				reg_data_out = slv_reg[j];
	end

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
			axi_rdata  <= 0;

		else
		begin
			if (slv_reg_rden)
				axi_rdata <= reg_data_out;
		end
	end

	assign o_xintf_z_to_d_data = 	(i_xintf_addr == 8) ? 	slv_reg[3][15:0] :
									(i_xintf_addr == 9) ? 	slv_reg[3][31:16] :
									(i_xintf_addr == 10) ? 	slv_reg[4][15:0] :
									(i_xintf_addr == 11) ? 	slv_reg[4][31:16] :
									(i_xintf_addr == 12) ? 	slv_reg[5][15:0] :
									(i_xintf_addr == 13) ? 	slv_reg[5][31:16] :
									(i_xintf_addr == 14) ? 	slv_reg[6][15:0] :
									(i_xintf_addr == 15) ? 	slv_reg[6][31:16] :
									(i_xintf_addr == 16) ? 	slv_reg[9][15:0] :
									(i_xintf_addr == 17) ? 	slv_reg[9][31:16] :
									(i_xintf_addr == 18) ? 	slv_reg[10][15:0] :
									(i_xintf_addr == 19) ? 	slv_reg[10][31:16] :
									(i_xintf_addr == 20) ? 	slv_reg[7][15:0] :
									(i_xintf_addr == 21) ? 	slv_reg[7][31:16] :
									(i_xintf_addr == 22) ? 	slv_reg[8][15:0] :
									(i_xintf_addr == 23) ? 	slv_reg[8][31:16] :
									(i_xintf_addr == 24) ? 	slv_reg[11][15:0] :
									(i_xintf_addr == 25) ? 	slv_reg[12][15:0] :
									(i_xintf_addr == 26) ? 	slv_reg[13][15:0] :
									(i_xintf_addr == 27) ? 	slv_reg[13][31:16] :
									(i_xintf_addr == 28) ? 	slv_reg[14][15:0] :
									(i_xintf_addr == 29) ? 	slv_reg[14][31:16] :
									(i_xintf_addr == 30) ? 	slv_reg[15][15:0] :
									(i_xintf_addr == 31) ? 	slv_reg[15][31:16] :
									(i_xintf_addr == 32) ? 	slv_reg[16][15:0] :
									(i_xintf_addr == 33) ? 	slv_reg[16][31:16] :
									(i_xintf_addr == 34) ? 	slv_reg[17][15:0] :
									(i_xintf_addr == 35) ? 	slv_reg[17][31:16] :
									(i_xintf_addr == 36) ? 	slv_reg[18][15:0] :
									(i_xintf_addr == 37) ? 	slv_reg[18][31:16] :
									(i_xintf_addr == 39) ? 	i_zynq_status :
									(i_xintf_addr == 40) ? 	i_c_data[15:0] :
									(i_xintf_addr == 41) ? 	i_c_data[31:16] :
									(i_xintf_addr == 42) ? 	i_v_data[15:0] :
									(i_xintf_addr == 43) ? 	i_v_data[31:16] :
									(i_xintf_addr == 44) ? 	slv_reg[1][15:0] :
									(i_xintf_addr == 45) ? 	slv_reg[1][31:16] :
									(i_xintf_addr == 46) ? 	slv_reg[2][15:0] :
									(i_xintf_addr == 47) ? 	slv_reg[2][31:16] : 0;

	always @(posedge S_AXI_ACLK)
	begin
		slv_reg[64] 	<= i_c_data;
		slv_reg[65] 	<= i_v_data;
		slv_reg[66] 	<= i_dc_c_data;
		slv_reg[67] 	<= i_dc_v_data;
		slv_reg[68] 	<= i_phase_r_data;
		slv_reg[69] 	<= i_phase_s_data;
		slv_reg[70] 	<= i_phase_t_data;
		slv_reg[71] 	<= i_igbt_t_data;
		slv_reg[72] 	<= i_i_inductor_t_data;
		slv_reg[73] 	<= i_o_inductor_t_data;
		slv_reg[74] 	<= i_phase_rms_r;
		slv_reg[75] 	<= i_phase_rms_s;
		slv_reg[76] 	<= i_phase_rms_t;

		slv_reg[77][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 128)) ? i_xintf_d_to_z_data : slv_reg[77][15:0];
		slv_reg[77][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 129)) ? i_xintf_d_to_z_data : slv_reg[77][31:16];
		slv_reg[78][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 130)) ? i_xintf_d_to_z_data : slv_reg[78][15:0];
		slv_reg[78][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 131)) ? i_xintf_d_to_z_data : slv_reg[78][31:16];
		slv_reg[79][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 132)) ? i_xintf_d_to_z_data : slv_reg[79][15:0];
		slv_reg[79][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 133)) ? i_xintf_d_to_z_data : slv_reg[79][31:16];
		slv_reg[80][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 134)) ? i_xintf_d_to_z_data : slv_reg[80][15:0];
		slv_reg[80][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 135)) ? i_xintf_d_to_z_data : slv_reg[80][31:16];
		slv_reg[81][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 136)) ? i_xintf_d_to_z_data : slv_reg[81][15:0];
		slv_reg[81][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 137)) ? i_xintf_d_to_z_data : slv_reg[81][31:16];
		slv_reg[82][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 138)) ? i_xintf_d_to_z_data : slv_reg[82][15:0];
		slv_reg[82][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 139)) ? i_xintf_d_to_z_data : slv_reg[82][31:16];
		slv_reg[83][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 140)) ? i_xintf_d_to_z_data : slv_reg[83][15:0];
		slv_reg[83][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 141)) ? i_xintf_d_to_z_data : slv_reg[83][31:16];
		slv_reg[84][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 142)) ? i_xintf_d_to_z_data : slv_reg[84][15:0];
		slv_reg[84][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 143)) ? i_xintf_d_to_z_data : slv_reg[84][31:16];
		slv_reg[85][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 144)) ? i_xintf_d_to_z_data : slv_reg[85][15:0];
		slv_reg[86][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 145)) ? i_xintf_d_to_z_data : slv_reg[86][15:0];
		slv_reg[87][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 146)) ? i_xintf_d_to_z_data : slv_reg[87][15:0];
		slv_reg[87][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 147)) ? i_xintf_d_to_z_data : slv_reg[87][31:16];
		slv_reg[88][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 148)) ? i_xintf_d_to_z_data : slv_reg[88][15:0];
		slv_reg[88][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 149)) ? i_xintf_d_to_z_data : slv_reg[88][31:16];
		slv_reg[89][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 150)) ? i_xintf_d_to_z_data : slv_reg[89][15:0];
		slv_reg[89][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 151)) ? i_xintf_d_to_z_data : slv_reg[89][31:16];
		slv_reg[90][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 152)) ? i_xintf_d_to_z_data : slv_reg[90][15:0];
		slv_reg[90][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 153)) ? i_xintf_d_to_z_data : slv_reg[90][31:16];
		slv_reg[91][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 154)) ? i_xintf_d_to_z_data : slv_reg[91][15:0];
		slv_reg[91][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 155)) ? i_xintf_d_to_z_data : slv_reg[91][31:16];
		slv_reg[92][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 156)) ? i_xintf_d_to_z_data : slv_reg[92][15:0];
		slv_reg[92][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 157)) ? i_xintf_d_to_z_data : slv_reg[92][31:16];
		slv_reg[93][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 158)) ? i_xintf_d_to_z_data : slv_reg[93][15:0];
		slv_reg[93][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 159)) ? i_xintf_d_to_z_data : slv_reg[93][31:16];
		slv_reg[94][15:0] 	<= ((~i_dsp_we) && (i_xintf_addr == 160)) ? i_xintf_d_to_z_data : slv_reg[94][15:0];
		slv_reg[94][31:16] 	<= ((~i_dsp_we) && (i_xintf_addr == 161)) ? i_xintf_d_to_z_data : slv_reg[94][31:16];

		slv_reg[95]		<= i_dsp_status;

		slv_reg[96]		<= i_sfp_c;
		slv_reg[97]		<= i_sfp_v;
		slv_reg[98]		<= i_sfp_dc_c;
		slv_reg[99]		<= i_sfp_dc_v;
		slv_reg[100]	<= i_sfp_phase_r_rms;
		slv_reg[101]	<= i_sfp_phase_s_rms;
		slv_reg[102]	<= i_sfp_phase_t_rms;
		slv_reg[103]	<= i_sfp_igbt_t;
		slv_reg[104]	<= i_sfp_i_inductor_t;
		slv_reg[105]	<= i_sfp_o_inductor_t;
		slv_reg[106]	<= i_sfp_intl;
		slv_reg[107]	<= i_sfp_fsm;

		slv_reg[108] 	<= i_sfp_c_over_sp;
		slv_reg[109] 	<= i_sfp_v_over_sp;
		slv_reg[110] 	<= i_sfp_dc_c_over_sp;
		slv_reg[111] 	<= i_sfp_dc_v_over_sp;
		slv_reg[112] 	<= i_sfp_igbt_t_over_sp;
		slv_reg[113] 	<= i_sfp_i_id_t_over_sp;
		slv_reg[114] 	<= i_sfp_o_id_t_over_sp;
		slv_reg[115] 	<= i_sfp_c_data_thresh;
		slv_reg[116] 	<= i_sfp_c_cnt_thresh;
		slv_reg[117] 	<= i_sfp_c_period;
		slv_reg[118] 	<= i_sfp_c_cycle_cnt;
		slv_reg[119] 	<= i_sfp_c_diff;
		slv_reg[120] 	<= i_sfp_c_delay;
		slv_reg[121] 	<= i_sfp_v_data_thresh;
		slv_reg[122] 	<= i_sfp_v_cnt_thresh;
		slv_reg[123] 	<= i_sfp_v_period;
		slv_reg[124] 	<= i_sfp_v_cycle_cnt;
		slv_reg[125] 	<= i_sfp_v_diff;
		slv_reg[126] 	<= i_sfp_v_delay;
	end

	assign S_AXI_AWREADY = axi_awready;
	assign S_AXI_WREADY = axi_wready;
	assign S_AXI_BRESP = axi_bresp;
	assign S_AXI_BVALID = axi_bvalid;
	assign S_AXI_ARREADY = axi_arready;
	assign S_AXI_RDATA = axi_rdata;
	assign S_AXI_RRESP = axi_rresp;
	assign S_AXI_RVALID = axi_rvalid;

	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	

endmodule