`timescale 1 ns / 1 ps

module DSP_XINTF_MUX_Top
(
	input i_clk,
	input i_rst,

	// DSP XINTF Data Line
	input i_dsp_we,
	input i_dsp_rd,
	input i_i_dsp_ce,
	input [8:0] i_dsp_xa,
	inout [15:0] io_dsp_xd,

	output o_we,
	output o_rd,

	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_W_RAM ADDR" *) 	output [8:0] o_xintf_w_ram_addr,
	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_W_RAM CLK" *) 	output o_xintf_w_ram_clk,
	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_W_RAM DIN" *) 	output [15:0] o_xintf_w_ram_din,
	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_W_RAM DOUT" *) 	input [15:0] i_xintf_w_ram_dout,
	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_W_RAM EN" *) 	output o_xintf_w_ram_ce,
	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_W_RAM RST" *) 	output o_xintf_w_ram_rst,
	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_W_RAM WE" *)		output o_xintf_w_ram_we,

	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_R_RAM ADDR" *) 	output [8:0] o_xintf_r_ram_addr,
	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_R_RAM CLK" *) 	output o_xintf_r_ram_clk,
	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_R_RAM DIN" *) 	output [15:0] o_xintf_r_ram_din,
	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_R_RAM DOUT" *) 	input [15:0] i_xintf_r_ram_dout,
	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_R_RAM EN" *) 	output o_xintf_r_ram_ce,
	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_R_RAM RST" *) 	output o_xintf_r_ram_rst,
	(* X_INTERFACE_INFO = "xilinx.com:interface:bram_rtl:1.0 XINTF_R_RAM WE" *)		output o_xintf_r_ram_we
);
	
	assign o_xintf_r_ram_addr = (o_rd) ? i_dsp_xa : 0;
	assign o_xintf_w_ram_addr = (o_we) ? i_dsp_xa : 0;

	assign o_xintf_r_ram_ce = (o_rd);
	assign o_xintf_w_ram_ce = (o_we);

	assign o_xintf_r_ram_we = 0;
	assign o_xintf_w_ram_we = 1;

	assign io_dsp_xd = (o_we) ? i_xintf_r_ram_dout : 16'hZZZZ;
	assign o_xintf_w_ram_din = (o_rd) ? io_dsp_xd : 16'hZZZZ;

	assign o_we = ~((i_i_dsp_ce) || (i_dsp_we));
	assign o_rd = ~((i_i_dsp_ce) || (i_dsp_rd));

	assign o_xintf_w_ram_clk = i_clk;
	assign i_xintf_w_ram_dout = 0;
	assign o_xintf_w_ram_rst = 0;

	assign o_xintf_r_ram_clk = i_clk;
	assign o_xintf_r_ram_din = 0;
	assign o_xintf_r_ram_rst = 0;

endmodule