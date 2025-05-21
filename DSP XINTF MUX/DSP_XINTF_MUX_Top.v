`timescale 1 ns / 1 ps

module DSP_XINTF_MUX_Top
(
    input i_clk,
    input i_rst,
	input i_wf_en,

	// DSP XINTF Data Line
	// output o_nZ_WE,
	input i_nZ_B_WE,
	input i_nZ_B_CS,
	input [8:0] i_Z_B_XA,
	inout [15:0] io_Z_B_XD,

	// DPBRMA Read
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM addr1" *) output [8:0] o_z_to_d_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM ce1" *) output o_z_to_d_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM we1" *) output o_z_to_d_we,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM din1" *) output [15:0] o_z_to_d_din,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM dout1" *) input [15:0] i_z_to_d_dout,

	// DPBRAM Write
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM addr0" *) output [8:0] o_d_to_z_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM ce0" *) output o_d_to_z_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM we0" *) output o_d_to_z_we,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM din0" *) output [15:0] o_d_to_z_din,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM dout0" *) input [15:0] i_d_to_z_dout
	
	// output [2:0] o_r_cnt
);

	// reg [2:0] r_cnt;

	// always @(posedge i_clk or negedge i_rst)
	// begin
	// 	if (~i_rst)
	// 		r_cnt <= 0;
			
	// 	else
	// 		r_cnt <= ((~i_nZ_B_CS) && (~i_nZ_B_WE)) ? ((&r_cnt) ? r_cnt : r_cnt + 1) : 0;
	// end
	
	assign o_z_to_d_addr = ((!i_wf_en) && (i_nZ_B_WE)) ? i_Z_B_XA : 0;
	assign o_d_to_z_addr = ((!i_wf_en) && (!i_nZ_B_WE)) ? i_Z_B_XA : 0;

	assign o_z_to_d_ce = ((!i_wf_en) && (i_nZ_B_WE)) ? ~i_nZ_B_CS : 0;
	// assign o_d_to_z_ce = ((!i_wf_en) && (!i_nZ_B_WE) && (r_cnt == 3)) ? ~i_nZ_B_WE : 0;
	assign o_d_to_z_ce = ((!i_wf_en) && (!i_nZ_B_WE)) ? ~i_nZ_B_WE : 0;

	assign o_z_to_d_we = 0;
	assign o_d_to_z_we = 1;

	assign io_Z_B_XD = ((!i_wf_en) && (i_nZ_B_WE)) ? i_z_to_d_dout : 16'hZZZZ;
	// assign o_d_to_z_din = ((!i_wf_en) && (!i_nZ_B_WE) && (r_cnt == 3)) ? io_Z_B_XD : 16'hZZZZ;
	assign o_d_to_z_din = ((!i_wf_en) && (!i_nZ_B_WE)) ? io_Z_B_XD : 16'hZZZZ;
	// assign o_r_cnt = r_cnt;

endmodule