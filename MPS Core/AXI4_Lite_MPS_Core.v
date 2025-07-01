`timescale 1 ns / 1 ps

module AXI4_Lite_MPS_Core #
(
	parameter integer C_S_AXI_DATA_WIDTH	= 0,
	parameter integer C_S_AXI_ADDR_NUM 		= 0,
	parameter integer C_S_AXI_ADDR_WIDTH	= 0
)
(
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

	output reg [3:0] 	o_mps_setup,
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

	always @(posedge S_AXI_ACLK)
	begin
		o_mps_setup		<= slv_reg[0];
		o_set_c			<= slv_reg[1];
		o_set_v 		<= slv_reg[2];
		o_max_duty 		<= slv_reg[3];
		o_max_phase 	<= slv_reg[4];
		o_max_freq 		<= slv_reg[5];
		o_min_freq 		<= slv_reg[6];
		o_min_c 		<= slv_reg[7];
		o_max_c 		<= slv_reg[8];
		o_min_v 		<= slv_reg[9];
		o_max_v 		<= slv_reg[10];
		o_deadband 		<= slv_reg[11];
		o_sw_freq 		<= slv_reg[12];
		o_p_gain_c 		<= slv_reg[13];
		o_i_gain_c 		<= slv_reg[14];
		o_d_gain_c 		<= slv_reg[15];
		o_p_gain_v 		<= slv_reg[16];
		o_i_gain_v 		<= slv_reg[17];
		o_d_gain_v 		<= slv_reg[18];
	end

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

		slv_reg[77]		<= i_dsp_max_duty;
		slv_reg[78]		<= i_dsp_max_phase;
		slv_reg[79]		<= i_dsp_max_frequency;
		slv_reg[80]		<= i_dsp_min_frequency;
		slv_reg[81]		<= i_dsp_min_v;
		slv_reg[82]		<= i_dsp_max_v;
		slv_reg[83]		<= i_dsp_min_c;
		slv_reg[84]		<= i_dsp_max_c;
		slv_reg[85]		<= i_dsp_deadband;
		slv_reg[86]		<= i_dsp_sw_freq;
		slv_reg[87]		<= i_dsp_p_gain_c;
		slv_reg[88]		<= i_dsp_i_gain_c;
		slv_reg[89]		<= i_dsp_d_gain_c;
		slv_reg[90]		<= i_dsp_p_gain_v;
		slv_reg[91]		<= i_dsp_i_gain_v;
		slv_reg[92]		<= i_dsp_d_gain_v;
		slv_reg[93]		<= i_dsp_set_c;
		slv_reg[94]		<= i_dsp_set_v;
		slv_reg[95]		<= i_dsp_status;
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