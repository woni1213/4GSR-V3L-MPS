`timescale 1 ns / 1 ps

/*

BR MPS Calculation Parameter Module
媛쒕컻 2?? ?쟾寃쎌썝 遺??옣

25.03.31 :	理쒖큹 ?깮?꽦

1. 媛쒖슂
 ?뿰?궛?떇?뿉 ?븘?슂?븳 ?긽?닔
 1 Step : 0.00000059604644775390625 V (0.59604 uV)

 Offset : -10 (0xc1200000)
 Gain : 0.0000011920928955078125 (0x35a00000)

*/

module ADC_Calc_Val
(
	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] i_gain_m_axis_tdata,
	output i_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] i_offset_m_axis_tdata,
	output i_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] v_gain_m_axis_tdata,
	output v_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] v_offset_m_axis_tdata,
	output v_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_0_gain_m_axis_tdata,
	output sub_0_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_0_offset_m_axis_tdata,
	output sub_0_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_1_gain_m_axis_tdata,
	output sub_1_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_1_offset_m_axis_tdata,
	output sub_1_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_2_gain_m_axis_tdata,
	output sub_2_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_2_offset_m_axis_tdata,
	output sub_2_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_3_gain_m_axis_tdata,
	output sub_3_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_3_offset_m_axis_tdata,
	output sub_3_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_4_gain_m_axis_tdata,
	output sub_4_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_4_offset_m_axis_tdata,
	output sub_4_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_5_gain_m_axis_tdata,
	output sub_5_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_5_offset_m_axis_tdata,
	output sub_5_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_6_gain_m_axis_tdata,
	output sub_6_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_6_offset_m_axis_tdata,
	output sub_6_offset_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_7_gain_m_axis_tdata,
	output sub_7_gain_m_axis_tvalid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output [31:0] sub_7_offset_m_axis_tdata,
	output sub_7_offset_m_axis_tvalid
);

	assign i_gain_m_axis_tdata = 32'h35a0_0000;
	assign i_offset_m_axis_tdata = 32'hc120_0000;
	assign v_gain_m_axis_tdata = 32'h35a0_0000;
	assign v_offset_m_axis_tdata = 32'hc120_0000;
	assign sub_0_gain_m_axis_tdata = 32'h39a000a0;
	assign sub_0_offset_m_axis_tvalid = 32'hc120_0000;
	assign sub_1_gain_m_axis_tdata = 32'h39a000a0;
	assign sub_1_offset_m_axis_tvalid = 32'hc120_0000;
	assign sub_2_gain_m_axis_tdata = 32'h39a000a0;
	assign sub_2_offset_m_axis_tvalid = 32'hc120_0000;
	assign sub_3_gain_m_axis_tdata = 32'h39a000a0;
	assign sub_3_offset_m_axis_tvalid = 32'hc120_0000;
	assign sub_4_gain_m_axis_tdata = 32'h39a000a0;
	assign sub_4_offset_m_axis_tvalid = 32'hc120_0000;
	assign sub_5_gain_m_axis_tdata = 32'h39a000a0;
	assign sub_5_offset_m_axis_tvalid = 32'hc120_0000;
	assign sub_6_gain_m_axis_tdata = 32'h39a000a0;
	assign sub_6_offset_m_axis_tvalid = 32'hc120_0000;
	assign sub_7_gain_m_axis_tdata = 32'h39a000a0;
	assign sub_7_offset_m_axis_tvalid = 32'hc120_0000;

	assign i_gain_m_axis_tvalid = 1;
	assign i_offset_m_axis_tvalid = 1;
	assign v_gain_m_axis_tvalid = 1;
	assign v_offset_m_axis_tvalid = 1;
	assign sub_0_gain_m_axis_tvalid = 1;
	assign sub_0_offset_m_axis_tvalid = 1;
	assign sub_1_gain_m_axis_tvalid = 1;
	assign sub_1_offset_m_axis_tvalid = 1;
	assign sub_2_gain_m_axis_tvalid = 1;
	assign sub_2_offset_m_axis_tvalid = 1;
	assign sub_3_gain_m_axis_tvalid = 1;
	assign sub_3_offset_m_axis_tvalid = 1;
	assign sub_4_gain_m_axis_tvalid = 1;
	assign sub_4_offset_m_axis_tvalid = 1;
	assign sub_5_gain_m_axis_tvalid = 1;
	assign sub_5_offset_m_axis_tvalid = 1;
	assign sub_6_gain_m_axis_tvalid = 1;
	assign sub_6_offset_m_axis_tvalid = 1;
	assign sub_7_gain_m_axis_tvalid = 1;
	assign sub_7_offset_m_axis_tvalid = 1;

endmodule