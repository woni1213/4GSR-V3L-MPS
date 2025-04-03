`timescale 1 ns / 1 ps

module AXI4_Lite_MPS_Core #
(
	parameter integer C_S_AXI_DATA_WIDTH	= 0,
	parameter integer C_S_AXI_ADDR_NUM 		= 0,
	parameter integer C_S_AXI_ADDR_WIDTH	= 0,

	parameter integer C_DATA_FRAME_BIT = 0
)
(
	// ADC Calc Factor
	output reg [31:0]	o_c_factor,
	output reg [31:0]	o_v_factor,

	// ADC Data
	input [31:0]		i_c_adc_data,
	input [31:0]		i_v_adc_data,

	// DPBRAM Write
	output reg [15:0]	o_write_index,
	output reg [31:0]	o_index_data,
	output reg [12:0]	o_zynq_status,
    output reg [31:0]	o_set_c,
	output reg			o_write_index_flag,
	output reg [31:0] 	o_max_duty,
    output reg [31:0] 	o_max_phase,
    output reg [31:0] 	o_max_freq,
    output reg [31:0] 	o_min_freq,
	output reg [31:0] 	o_set_v,
	output reg [2:0]    o_slave_count,
	output reg		    o_slave_1_ram_cs,
	output reg [7:0]    o_slave_1_ram_addr,
	output reg		    o_slave_2_ram_cs,
	output reg [7:0]    o_slave_2_ram_addr,
	output reg		    o_slave_3_ram_cs,
	output reg [7:0]    o_slave_3_ram_addr,
	output reg		    o_axi_pwm_en,

	// DPBRAM Read
	input [31:0]		i_dsp_max_duty,
	input [31:0]		i_dsp_max_phase,
	input [31:0]		i_dsp_max_frequency,
	input [31:0]		i_dsp_min_frequency,
	input [31:0]		i_dsp_min_v,
	input [31:0]		i_dsp_max_v,
	input [31:0]		i_dsp_min_c,
	input [31:0]		i_dsp_max_c,
	input [15:0]		i_dsp_deadband,
	input [15:0]		i_dsp_sw_freq,
	input [31:0]		i_dsp_p_gain_c,
	input [31:0]		i_dsp_i_gain_c,
	input [31:0]		i_dsp_d_gain_c,
	input [31:0]		i_dsp_p_gain_v,
	input [31:0]		i_dsp_i_gain_v,
	input [31:0]		i_dsp_d_gain_v,
	input [31:0]		i_dsp_set_c,
	input [31:0]		i_dsp_set_v,
	input [31:0]		i_dsp_pi_param,
	input [31:0]		i_slave_c,
	input [31:0]		i_slave_v,
	input [31:0]		i_slave_status,
	input [31:0]		i_dc_adc_data,
	input [15:0]		i_dsp_status,
	input [15:0]		i_dsp_ver,
	input [31:0]		i_slave_1_ram_data,
	input [31:0]		i_slave_2_ram_data,
	input [31:0]		i_slave_3_ram_data,

	input [31:0]		i_sfp_c_factor,
	input [31:0]		i_sfp_v_factor,
	input [31:0] 		i_sfp_max_duty,
	input [31:0] 		i_sfp_max_phase,
	input [31:0] 		i_sfp_max_freq,
	input [31:0] 		i_sfp_min_freq,
	output reg			o_axi_data_valid,

	/////////////////////////////////////////////////////////
	output reg o_sfp_en,
	output reg [1:0] o_sfp_id,

	input [15:0] i_sfp_cmd,
	input [31:0] i_sfp_data_1,
	input [31:0] i_sfp_data_2,
	input [31:0] i_sfp_data_3,

	output reg [7:0] o_m_sfp_1_cmd,
	output reg [31:0] o_m_sfp_1_data,

	output reg [7:0] o_m_sfp_2_cmd,
	output reg [31:0] o_m_sfp_2_data,

	output reg [7:0] o_m_sfp_3_cmd,
	output reg [31:0] o_m_sfp_3_data,

	input [15:0] i_s_sfp_1_cmd,
	input [31:0] i_s_sfp_1_data_1,
	input [31:0] i_s_sfp_1_data_2,
	input [31:0] i_s_sfp_1_data_3,

	input [15:0] i_s_sfp_2_cmd,
	input [31:0] i_s_sfp_2_data_1,
	input [31:0] i_s_sfp_2_data_2,
	input [31:0] i_s_sfp_2_data_3,

	input [15:0] i_s_sfp_3_cmd,
	input [31:0] i_s_sfp_3_data_1,
	input [31:0] i_s_sfp_3_data_2,
	input [31:0] i_s_sfp_3_data_3,
/////////////////////////////////////////////////////////

	output reg [C_DATA_FRAME_BIT - 1 : 0] o_master_stream_data,
	input [C_DATA_FRAME_BIT - 1: 0] i_master_stream_data,

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

	// DSP Write DPBRAM
	always @(posedge S_AXI_ACLK)
	begin
		o_c_factor 			<= (o_sfp_en && (o_sfp_id != 0)) ? i_sfp_c_factor : slv_reg[1];
		o_v_factor 			<= (o_sfp_en && (o_sfp_id != 0)) ? i_sfp_v_factor : slv_reg[2];
		o_write_index		<= slv_reg[3][15:0];
		o_index_data		<= slv_reg[4];
		o_zynq_status 		<= slv_reg[5][12:0];
		o_set_c				<= slv_reg[6];
		o_write_index_flag	<= slv_reg[7][0];
		o_max_duty 			<= (o_sfp_en && (o_sfp_id != 0)) ? i_sfp_max_duty : slv_reg[8];
		o_max_phase			<= (o_sfp_en && (o_sfp_id != 0)) ? i_sfp_max_phase : slv_reg[9];
		o_max_freq 			<= (o_sfp_en && (o_sfp_id != 0)) ? i_sfp_max_freq : slv_reg[10];
		o_min_freq 			<= (o_sfp_en && (o_sfp_id != 0)) ? i_sfp_min_freq : slv_reg[11];
		o_set_v				<= slv_reg[12];
		o_slave_count		<= slv_reg[13][2:0];
		o_slave_1_ram_cs	<= slv_reg[14][0];
		o_slave_1_ram_addr	<= slv_reg[15][7:0];
		o_slave_2_ram_cs	<= slv_reg[16][0];
		o_slave_2_ram_addr	<= slv_reg[17][7:0];
		o_slave_3_ram_cs	<= slv_reg[18][0];
		o_slave_3_ram_addr	<= slv_reg[19][7:0];
		o_axi_pwm_en		<= slv_reg[20][0];

		o_axi_data_valid	<= slv_reg[57];
		o_m_sfp_1_cmd		<= slv_reg[58][7:0];
		o_m_sfp_1_data		<= slv_reg[59];
		o_m_sfp_2_cmd		<= slv_reg[60][7:0];
		o_m_sfp_2_data		<= slv_reg[61];
		o_m_sfp_3_cmd		<= slv_reg[62][7:0];
		o_m_sfp_3_data		<= slv_reg[63];
	end

	// SFP Control
	always @(posedge S_AXI_ACLK)
	begin
		o_sfp_id 			<= slv_reg[0][1:0];
		o_sfp_en			<= slv_reg[0][3];
	end

	// Zynq, DSP Data
	always @(posedge S_AXI_ACLK)
	begin
		slv_reg[65]			<= i_c_adc_data;
		slv_reg[66]			<= i_v_adc_data;
		slv_reg[67]			<= i_dsp_pi_param;
		slv_reg[68]			<= i_dsp_set_c;
		slv_reg[69]			<= i_dsp_set_v;
		slv_reg[70]			<= i_dsp_p_gain_v;
		slv_reg[71]			<= i_dsp_i_gain_v;
		slv_reg[72]			<= i_dsp_p_gain_c;
		slv_reg[73]			<= i_dsp_i_gain_c;
		slv_reg[74]			<= i_dsp_max_duty;
		slv_reg[75][15:0]	<= i_dsp_deadband;
		slv_reg[76]			<= i_dsp_max_phase;
		slv_reg[77]			<= i_dsp_max_frequency;
		slv_reg[78]			<= i_dsp_min_frequency;
		slv_reg[79]			<= i_dsp_max_v;
		slv_reg[80]			<= i_dsp_min_v;
		slv_reg[81]			<= i_dsp_max_c;
		slv_reg[82]			<= i_dsp_min_c;
		slv_reg[83][15:0]	<= i_dsp_sw_freq;
		slv_reg[84][15:0]	<= i_dsp_status;
		slv_reg[85]			<= i_slave_c;
		slv_reg[86]			<= i_slave_v;
		slv_reg[87]			<= i_slave_status;
		slv_reg[88]			<= i_dc_adc_data;
		slv_reg[89]			<= i_slave_1_ram_data;
		slv_reg[90]			<= i_slave_2_ram_data;
		slv_reg[91]			<= i_slave_3_ram_data;
		slv_reg[92]			<= i_dsp_ver;
		slv_reg[94]			<= i_dsp_d_gain_v;
		slv_reg[95]			<= i_dsp_d_gain_c;
	end

	always @(posedge S_AXI_ACLK)
	begin
		slv_reg[93]			<= {slv_reg[0][3], 1'd0, slv_reg[0][1:0]};
	    slv_reg[112][15:0]	<= i_sfp_cmd;
		slv_reg[113]		<= i_sfp_data_1;
		slv_reg[114]		<= i_sfp_data_2;
		slv_reg[115]		<= i_sfp_data_3;
		slv_reg[116][15:0]	<= i_s_sfp_1_cmd;
		slv_reg[117]		<= i_s_sfp_1_data_1;
		slv_reg[118]		<= i_s_sfp_1_data_2;
		slv_reg[119]		<= i_s_sfp_1_data_3;
		slv_reg[120][15:0]	<= i_s_sfp_2_cmd;
		slv_reg[121]		<= i_s_sfp_2_data_1;
		slv_reg[122]		<= i_s_sfp_2_data_2;
		slv_reg[123]		<= i_s_sfp_2_data_3;
		slv_reg[124][15:0]	<= i_s_sfp_3_cmd;
		slv_reg[125]		<= i_s_sfp_3_data_1;
		slv_reg[126]		<= i_s_sfp_3_data_2;
		slv_reg[127]		<= i_s_sfp_3_data_3;
	end

	// User logic ends

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