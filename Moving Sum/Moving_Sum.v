`timescale 1 ns / 1 ps

/*

MPS ADC Module
개발 4팀 전경원 차장

24.05.08 :	최초 생성

1. 개요
 총 16개의 ADC Data의 합산
 ADC 주기마다 Shift하여 연산함

2. 연산식
 n-15 + n-14 + ... + n = Output Data
 n은 현재 ADC 값
 해당 값을 Floating Point로 변환 시 공식에 의해서 1개의 데이터로 연산됨
 
*/

module Moving_Sum
(
	input i_clk,
	input i_rst,

	input [23:0] i_adc_data,
	input i_adc_valid,

	(* X_INTERFACE_PARAMETER = "FREQ_HZ 199998001" *)
	output reg [31:0] adc_m_axis_tdata,
	output adc_m_axis_tvalid
);

	localparam IDLE		= 0;
	localparam DELAY	= 1;
	localparam ADD_1	= 2;
	localparam ADD_2	= 3;
	localparam ADD_3	= 4;
	localparam ADD_4	= 5;
	localparam ADD_5	= 6;
	localparam ADD_6	= 7;
	localparam ADD_7	= 8;
	localparam SHIFT	= 9;
	localparam DONE		= 10;

	// FSM
	reg [3:0] state;
	reg [3:0] n_state;

	reg [23:0] adc_tmp [127:0];

	reg [31:0] add_1_buf[63:0];
	reg [31:0] add_2_buf[31:0];
	reg [31:0] add_3_buf[15:0];
	reg [31:0] add_4_buf[7:0];
	reg [31:0] add_5_buf[3:0];
	reg [31:0] add_6_buf[1:0];
	reg [31:0] add_7_buf;

	// FSM Control
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            state <= IDLE;

        else 
            state <= n_state;
    end

	// FSM
	always @(*)
    begin
        case (state)
            IDLE	: n_state = (i_adc_valid) ? DELAY : IDLE;
            DELAY	: n_state = ADD_1;
            ADD_1 	: n_state = ADD_2;
            ADD_2 	: n_state = ADD_3;
            ADD_3 	: n_state = ADD_4;
			ADD_4 	: n_state = ADD_5;
            ADD_5 	: n_state = ADD_6;
            ADD_6 	: n_state = ADD_7;
            ADD_7 	: n_state = SHIFT;
            SHIFT 	: n_state = DONE;
            DONE 	: n_state = IDLE;
			default	: n_state = IDLE;
		endcase
	end

		always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
		begin
			add_1_buf[0 ] <= 0;
			add_1_buf[1 ] <= 0;
			add_1_buf[2 ] <= 0;
			add_1_buf[3 ] <= 0;
			add_1_buf[4 ] <= 0;
			add_1_buf[5 ] <= 0;
			add_1_buf[6 ] <= 0;
			add_1_buf[7 ] <= 0;
			add_1_buf[8 ] <= 0;
			add_1_buf[9 ] <= 0;
			add_1_buf[10] <= 0;
			add_1_buf[11] <= 0;
			add_1_buf[12] <= 0;
			add_1_buf[13] <= 0;
			add_1_buf[14] <= 0;
			add_1_buf[15] <= 0;
			add_1_buf[16] <= 0;
			add_1_buf[17] <= 0;
			add_1_buf[18] <= 0;
			add_1_buf[19] <= 0;
			add_1_buf[20] <= 0;
			add_1_buf[21] <= 0;
			add_1_buf[22] <= 0;
			add_1_buf[23] <= 0;
			add_1_buf[24] <= 0;
			add_1_buf[25] <= 0;
			add_1_buf[26] <= 0;
			add_1_buf[27] <= 0;
			add_1_buf[28] <= 0;
			add_1_buf[29] <= 0;
			add_1_buf[30] <= 0;
			add_1_buf[31] <= 0;
			add_1_buf[32] <= 0;
			add_1_buf[33] <= 0;
			add_1_buf[34] <= 0;
			add_1_buf[35] <= 0;
			add_1_buf[36] <= 0;
			add_1_buf[37] <= 0;
			add_1_buf[38] <= 0;
			add_1_buf[39] <= 0;
			add_1_buf[40] <= 0;
			add_1_buf[41] <= 0;
			add_1_buf[42] <= 0;
			add_1_buf[43] <= 0;
			add_1_buf[44] <= 0;
			add_1_buf[45] <= 0;
			add_1_buf[46] <= 0;
			add_1_buf[47] <= 0;
			add_1_buf[48] <= 0;
			add_1_buf[49] <= 0;
			add_1_buf[50] <= 0;
			add_1_buf[51] <= 0;
			add_1_buf[52] <= 0;
			add_1_buf[53] <= 0;
			add_1_buf[54] <= 0;
			add_1_buf[55] <= 0;
			add_1_buf[56] <= 0;
			add_1_buf[57] <= 0;
			add_1_buf[58] <= 0;
			add_1_buf[59] <= 0;
			add_1_buf[60] <= 0;
			add_1_buf[61] <= 0;
			add_1_buf[62] <= 0;
			add_1_buf[63] <= 0;
		end

		else if (state == ADD_1)
		begin
			add_1_buf[0 ] <= adc_tmp[0  ] + adc_tmp[1  ];
			add_1_buf[1 ] <= adc_tmp[2  ] + adc_tmp[3  ];
			add_1_buf[2 ] <= adc_tmp[4  ] + adc_tmp[5  ];
			add_1_buf[3 ] <= adc_tmp[6  ] + adc_tmp[7  ];
			add_1_buf[4 ] <= adc_tmp[8  ] + adc_tmp[9  ];
			add_1_buf[5 ] <= adc_tmp[10 ] + adc_tmp[11 ];
			add_1_buf[6 ] <= adc_tmp[12 ] + adc_tmp[13 ];
			add_1_buf[7 ] <= adc_tmp[14 ] + adc_tmp[15 ];
			add_1_buf[8 ] <= adc_tmp[16 ] + adc_tmp[17 ];
			add_1_buf[9 ] <= adc_tmp[18 ] + adc_tmp[19 ];
			add_1_buf[10] <= adc_tmp[20 ] + adc_tmp[21 ];
			add_1_buf[11] <= adc_tmp[22 ] + adc_tmp[23 ];
			add_1_buf[12] <= adc_tmp[24 ] + adc_tmp[25 ];
			add_1_buf[13] <= adc_tmp[26 ] + adc_tmp[27 ];
			add_1_buf[14] <= adc_tmp[28 ] + adc_tmp[29 ];
			add_1_buf[15] <= adc_tmp[30 ] + adc_tmp[31 ];
			add_1_buf[16] <= adc_tmp[32 ] + adc_tmp[33 ];
			add_1_buf[17] <= adc_tmp[34 ] + adc_tmp[35 ];
			add_1_buf[18] <= adc_tmp[36 ] + adc_tmp[37 ];
			add_1_buf[19] <= adc_tmp[38 ] + adc_tmp[39 ];
			add_1_buf[20] <= adc_tmp[40 ] + adc_tmp[41 ];
			add_1_buf[21] <= adc_tmp[42 ] + adc_tmp[43 ];
			add_1_buf[22] <= adc_tmp[44 ] + adc_tmp[45 ];
			add_1_buf[23] <= adc_tmp[46 ] + adc_tmp[47 ];
			add_1_buf[24] <= adc_tmp[48 ] + adc_tmp[49 ];
			add_1_buf[25] <= adc_tmp[50 ] + adc_tmp[51 ];
			add_1_buf[26] <= adc_tmp[52 ] + adc_tmp[53 ];
			add_1_buf[27] <= adc_tmp[54 ] + adc_tmp[55 ];
			add_1_buf[28] <= adc_tmp[56 ] + adc_tmp[57 ];
			add_1_buf[29] <= adc_tmp[58 ] + adc_tmp[59 ];
			add_1_buf[30] <= adc_tmp[60 ] + adc_tmp[61 ];
			add_1_buf[31] <= adc_tmp[62 ] + adc_tmp[63 ];
			add_1_buf[32] <= adc_tmp[64 ] + adc_tmp[65 ];
			add_1_buf[33] <= adc_tmp[66 ] + adc_tmp[67 ];
			add_1_buf[34] <= adc_tmp[68 ] + adc_tmp[69 ];
			add_1_buf[35] <= adc_tmp[70 ] + adc_tmp[71 ];
			add_1_buf[36] <= adc_tmp[72 ] + adc_tmp[73 ];
			add_1_buf[37] <= adc_tmp[74 ] + adc_tmp[75 ];
			add_1_buf[38] <= adc_tmp[76 ] + adc_tmp[77 ];
			add_1_buf[39] <= adc_tmp[78 ] + adc_tmp[79 ];
			add_1_buf[40] <= adc_tmp[80 ] + adc_tmp[81 ];
			add_1_buf[41] <= adc_tmp[82 ] + adc_tmp[83 ];
			add_1_buf[42] <= adc_tmp[84 ] + adc_tmp[85 ];
			add_1_buf[43] <= adc_tmp[86 ] + adc_tmp[87 ];
			add_1_buf[44] <= adc_tmp[88 ] + adc_tmp[89 ];
			add_1_buf[45] <= adc_tmp[90 ] + adc_tmp[91 ];
			add_1_buf[46] <= adc_tmp[92 ] + adc_tmp[93 ];
			add_1_buf[47] <= adc_tmp[94 ] + adc_tmp[95 ];
			add_1_buf[48] <= adc_tmp[96 ] + adc_tmp[97 ];
			add_1_buf[49] <= adc_tmp[98 ] + adc_tmp[99 ];
			add_1_buf[50] <= adc_tmp[100] + adc_tmp[101];
			add_1_buf[51] <= adc_tmp[102] + adc_tmp[103];
			add_1_buf[52] <= adc_tmp[104] + adc_tmp[105];
			add_1_buf[53] <= adc_tmp[106] + adc_tmp[107];
			add_1_buf[54] <= adc_tmp[108] + adc_tmp[109];
			add_1_buf[55] <= adc_tmp[110] + adc_tmp[111];
			add_1_buf[56] <= adc_tmp[112] + adc_tmp[113];
			add_1_buf[57] <= adc_tmp[114] + adc_tmp[115];
			add_1_buf[58] <= adc_tmp[116] + adc_tmp[117];
			add_1_buf[59] <= adc_tmp[118] + adc_tmp[119];
			add_1_buf[60] <= adc_tmp[120] + adc_tmp[121];
			add_1_buf[61] <= adc_tmp[122] + adc_tmp[123];
			add_1_buf[62] <= adc_tmp[124] + adc_tmp[125];
			add_1_buf[63] <= adc_tmp[126] + adc_tmp[127];
		end

		else
		begin
			add_1_buf[0 ] <= add_1_buf[0 ];
			add_1_buf[1 ] <= add_1_buf[1 ];
			add_1_buf[2 ] <= add_1_buf[2 ];
			add_1_buf[3 ] <= add_1_buf[3 ];
			add_1_buf[4 ] <= add_1_buf[4 ];
			add_1_buf[5 ] <= add_1_buf[5 ];
			add_1_buf[6 ] <= add_1_buf[6 ];
			add_1_buf[7 ] <= add_1_buf[7 ];
			add_1_buf[8 ] <= add_1_buf[8 ];
			add_1_buf[9 ] <= add_1_buf[9 ];
			add_1_buf[10] <= add_1_buf[10];
			add_1_buf[11] <= add_1_buf[11];
			add_1_buf[12] <= add_1_buf[12];
			add_1_buf[13] <= add_1_buf[13];
			add_1_buf[14] <= add_1_buf[14];
			add_1_buf[15] <= add_1_buf[15];
			add_1_buf[16] <= add_1_buf[16];
			add_1_buf[17] <= add_1_buf[17];
			add_1_buf[18] <= add_1_buf[18];
			add_1_buf[19] <= add_1_buf[19];
			add_1_buf[20] <= add_1_buf[20];
			add_1_buf[21] <= add_1_buf[21];
			add_1_buf[22] <= add_1_buf[22];
			add_1_buf[23] <= add_1_buf[23];
			add_1_buf[24] <= add_1_buf[24];
			add_1_buf[25] <= add_1_buf[25];
			add_1_buf[26] <= add_1_buf[26];
			add_1_buf[27] <= add_1_buf[27];
			add_1_buf[28] <= add_1_buf[28];
			add_1_buf[29] <= add_1_buf[29];
			add_1_buf[30] <= add_1_buf[30];
			add_1_buf[31] <= add_1_buf[31];
			add_1_buf[32] <= add_1_buf[32];
			add_1_buf[33] <= add_1_buf[33];
			add_1_buf[34] <= add_1_buf[34];
			add_1_buf[35] <= add_1_buf[35];
			add_1_buf[36] <= add_1_buf[36];
			add_1_buf[37] <= add_1_buf[37];
			add_1_buf[38] <= add_1_buf[38];
			add_1_buf[39] <= add_1_buf[39];
			add_1_buf[40] <= add_1_buf[40];
			add_1_buf[41] <= add_1_buf[41];
			add_1_buf[42] <= add_1_buf[42];
			add_1_buf[43] <= add_1_buf[43];
			add_1_buf[44] <= add_1_buf[44];
			add_1_buf[45] <= add_1_buf[45];
			add_1_buf[46] <= add_1_buf[46];
			add_1_buf[47] <= add_1_buf[47];
			add_1_buf[48] <= add_1_buf[48];
			add_1_buf[49] <= add_1_buf[49];
			add_1_buf[50] <= add_1_buf[50];
			add_1_buf[51] <= add_1_buf[51];
			add_1_buf[52] <= add_1_buf[52];
			add_1_buf[53] <= add_1_buf[53];
			add_1_buf[54] <= add_1_buf[54];
			add_1_buf[55] <= add_1_buf[55];
			add_1_buf[56] <= add_1_buf[56];
			add_1_buf[57] <= add_1_buf[57];
			add_1_buf[58] <= add_1_buf[58];
			add_1_buf[59] <= add_1_buf[59];
			add_1_buf[60] <= add_1_buf[60];
			add_1_buf[61] <= add_1_buf[61];
			add_1_buf[62] <= add_1_buf[62];
			add_1_buf[63] <= add_1_buf[63];
		end
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
		begin
			add_2_buf[0 ] <= 0;
			add_2_buf[1 ] <= 0;
			add_2_buf[2 ] <= 0;
			add_2_buf[3 ] <= 0;
			add_2_buf[4 ] <= 0;
			add_2_buf[5 ] <= 0;
			add_2_buf[6 ] <= 0;
			add_2_buf[7 ] <= 0;
			add_2_buf[8 ] <= 0;
			add_2_buf[9 ] <= 0;
			add_2_buf[10] <= 0;
			add_2_buf[11] <= 0;
			add_2_buf[12] <= 0;
			add_2_buf[13] <= 0;
			add_2_buf[14] <= 0;
			add_2_buf[15] <= 0;
			add_2_buf[16] <= 0;
			add_2_buf[17] <= 0;
			add_2_buf[18] <= 0;
			add_2_buf[19] <= 0;
			add_2_buf[20] <= 0;
			add_2_buf[21] <= 0;
			add_2_buf[22] <= 0;
			add_2_buf[23] <= 0;
			add_2_buf[24] <= 0;
			add_2_buf[25] <= 0;
			add_2_buf[26] <= 0;
			add_2_buf[27] <= 0;
			add_2_buf[28] <= 0;
			add_2_buf[29] <= 0;
			add_2_buf[30] <= 0;
			add_2_buf[31] <= 0;
		end

		else if (state == ADD_2)
		begin
			add_2_buf[0 ] <= add_1_buf[0 ] + add_1_buf[1 ];
			add_2_buf[1 ] <= add_1_buf[2 ] + add_1_buf[3 ];
			add_2_buf[2 ] <= add_1_buf[4 ] + add_1_buf[5 ];
			add_2_buf[3 ] <= add_1_buf[6 ] + add_1_buf[7 ];
			add_2_buf[4 ] <= add_1_buf[8 ] + add_1_buf[9 ];
			add_2_buf[5 ] <= add_1_buf[10] + add_1_buf[11];
			add_2_buf[6 ] <= add_1_buf[12] + add_1_buf[13];
			add_2_buf[7 ] <= add_1_buf[14] + add_1_buf[15];
			add_2_buf[8 ] <= add_1_buf[16] + add_1_buf[17];
			add_2_buf[9 ] <= add_1_buf[18] + add_1_buf[19];
			add_2_buf[10] <= add_1_buf[20] + add_1_buf[21];
			add_2_buf[11] <= add_1_buf[22] + add_1_buf[23];
			add_2_buf[12] <= add_1_buf[24] + add_1_buf[25];
			add_2_buf[13] <= add_1_buf[26] + add_1_buf[27];
			add_2_buf[14] <= add_1_buf[28] + add_1_buf[29];
			add_2_buf[15] <= add_1_buf[30] + add_1_buf[31];
			add_2_buf[16] <= add_1_buf[32] + add_1_buf[33];
			add_2_buf[17] <= add_1_buf[34] + add_1_buf[35];
			add_2_buf[18] <= add_1_buf[36] + add_1_buf[37];
			add_2_buf[19] <= add_1_buf[38] + add_1_buf[39];
			add_2_buf[20] <= add_1_buf[40] + add_1_buf[41];
			add_2_buf[21] <= add_1_buf[42] + add_1_buf[43];
			add_2_buf[22] <= add_1_buf[44] + add_1_buf[45];
			add_2_buf[23] <= add_1_buf[46] + add_1_buf[47];
			add_2_buf[24] <= add_1_buf[48] + add_1_buf[49];
			add_2_buf[25] <= add_1_buf[50] + add_1_buf[51];
			add_2_buf[26] <= add_1_buf[52] + add_1_buf[53];
			add_2_buf[27] <= add_1_buf[54] + add_1_buf[55];
			add_2_buf[28] <= add_1_buf[56] + add_1_buf[57];
			add_2_buf[29] <= add_1_buf[58] + add_1_buf[59];
			add_2_buf[30] <= add_1_buf[60] + add_1_buf[61];
			add_2_buf[31] <= add_1_buf[62] + add_1_buf[63];
		end

		else
		begin
			add_2_buf[0 ] <= add_2_buf[0 ];
			add_2_buf[1 ] <= add_2_buf[1 ];
			add_2_buf[2 ] <= add_2_buf[2 ];
			add_2_buf[3 ] <= add_2_buf[3 ];
			add_2_buf[4 ] <= add_2_buf[4 ];
			add_2_buf[5 ] <= add_2_buf[5 ];
			add_2_buf[6 ] <= add_2_buf[6 ];
			add_2_buf[7 ] <= add_2_buf[7 ];
			add_2_buf[8 ] <= add_2_buf[8 ];
			add_2_buf[9 ] <= add_2_buf[9 ];
			add_2_buf[10] <= add_2_buf[10];
			add_2_buf[11] <= add_2_buf[11];
			add_2_buf[12] <= add_2_buf[12];
			add_2_buf[13] <= add_2_buf[13];
			add_2_buf[14] <= add_2_buf[14];
			add_2_buf[15] <= add_2_buf[15];
			add_2_buf[16] <= add_2_buf[16];
			add_2_buf[17] <= add_2_buf[17];
			add_2_buf[18] <= add_2_buf[18];
			add_2_buf[19] <= add_2_buf[19];
			add_2_buf[20] <= add_2_buf[20];
			add_2_buf[21] <= add_2_buf[21];
			add_2_buf[22] <= add_2_buf[22];
			add_2_buf[23] <= add_2_buf[23];
			add_2_buf[24] <= add_2_buf[24];
			add_2_buf[25] <= add_2_buf[25];
			add_2_buf[26] <= add_2_buf[26];
			add_2_buf[27] <= add_2_buf[27];
			add_2_buf[28] <= add_2_buf[28];
			add_2_buf[29] <= add_2_buf[29];
			add_2_buf[30] <= add_2_buf[30];
			add_2_buf[31] <= add_2_buf[31];
		end
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
		begin
			add_3_buf[0 ] <= 0;
			add_3_buf[1 ] <= 0;
			add_3_buf[2 ] <= 0;
			add_3_buf[3 ] <= 0;
			add_3_buf[4 ] <= 0;
			add_3_buf[5 ] <= 0;
			add_3_buf[6 ] <= 0;
			add_3_buf[7 ] <= 0;
			add_3_buf[8 ] <= 0;
			add_3_buf[9 ] <= 0;
			add_3_buf[10] <= 0;
			add_3_buf[11] <= 0;
			add_3_buf[12] <= 0;
			add_3_buf[13] <= 0;
			add_3_buf[14] <= 0;
			add_3_buf[15] <= 0;
		end

		else if (state == ADD_3)
		begin
			add_3_buf[0 ] <= add_2_buf[0 ] + add_2_buf[1 ];
			add_3_buf[1 ] <= add_2_buf[2 ] + add_2_buf[3 ];
			add_3_buf[2 ] <= add_2_buf[4 ] + add_2_buf[5 ];
			add_3_buf[3 ] <= add_2_buf[6 ] + add_2_buf[7 ];
			add_3_buf[4 ] <= add_2_buf[8 ] + add_2_buf[9 ];
			add_3_buf[5 ] <= add_2_buf[10] + add_2_buf[11];
			add_3_buf[6 ] <= add_2_buf[12] + add_2_buf[13];
			add_3_buf[7 ] <= add_2_buf[14] + add_2_buf[15];
			add_3_buf[8 ] <= add_2_buf[16] + add_2_buf[17];
			add_3_buf[9 ] <= add_2_buf[18] + add_2_buf[19];
			add_3_buf[10] <= add_2_buf[20] + add_2_buf[21];
			add_3_buf[11] <= add_2_buf[22] + add_2_buf[23];
			add_3_buf[12] <= add_2_buf[24] + add_2_buf[25];
			add_3_buf[13] <= add_2_buf[26] + add_2_buf[27];
			add_3_buf[14] <= add_2_buf[28] + add_2_buf[29];
			add_3_buf[15] <= add_2_buf[30] + add_2_buf[31];
		end

		else
		begin
			add_3_buf[0 ] <= add_3_buf[0 ];
			add_3_buf[1 ] <= add_3_buf[1 ];
			add_3_buf[2 ] <= add_3_buf[2 ];
			add_3_buf[3 ] <= add_3_buf[3 ];
			add_3_buf[4 ] <= add_3_buf[4 ];
			add_3_buf[5 ] <= add_3_buf[5 ];
			add_3_buf[6 ] <= add_3_buf[6 ];
			add_3_buf[7 ] <= add_3_buf[7 ];
			add_3_buf[8 ] <= add_3_buf[8 ];
			add_3_buf[9 ] <= add_3_buf[9 ];
			add_3_buf[10] <= add_3_buf[10];
			add_3_buf[11] <= add_3_buf[11];
			add_3_buf[12] <= add_3_buf[12];
			add_3_buf[13] <= add_3_buf[13];
			add_3_buf[14] <= add_3_buf[14];
			add_3_buf[15] <= add_3_buf[15];
		end
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
		begin
			add_4_buf[0] <= 0;
			add_4_buf[1] <= 0;
			add_4_buf[2] <= 0;
			add_4_buf[3] <= 0;
			add_4_buf[4] <= 0;
			add_4_buf[5] <= 0;
			add_4_buf[6] <= 0;
			add_4_buf[7] <= 0;
		end

		else if (state == ADD_4)
		begin
			add_4_buf[0] <= add_3_buf[0 ] + add_3_buf[1 ];
			add_4_buf[1] <= add_3_buf[2 ] + add_3_buf[3 ];
			add_4_buf[2] <= add_3_buf[4 ] + add_3_buf[5 ];
			add_4_buf[3] <= add_3_buf[6 ] + add_3_buf[7 ];
			add_4_buf[4] <= add_3_buf[8 ] + add_3_buf[9 ];
			add_4_buf[5] <= add_3_buf[10] + add_3_buf[11];
			add_4_buf[6] <= add_3_buf[12] + add_3_buf[13];
			add_4_buf[7] <= add_3_buf[14] + add_3_buf[15];
		end

		else
		begin
			add_4_buf[0] <= add_4_buf[0];
			add_4_buf[1] <= add_4_buf[1];
			add_4_buf[2] <= add_4_buf[2];
			add_4_buf[3] <= add_4_buf[3];
			add_4_buf[4] <= add_4_buf[4];
			add_4_buf[5] <= add_4_buf[5];
			add_4_buf[6] <= add_4_buf[6];
			add_4_buf[7] <= add_4_buf[7];
		end
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
		begin
			add_5_buf[0] <= 0;
			add_5_buf[1] <= 0;
			add_5_buf[2] <= 0;
			add_5_buf[3] <= 0;
		end

		else if (state == ADD_5)
		begin
			add_5_buf[0] <= add_4_buf[0] + add_4_buf[1];
			add_5_buf[1] <= add_4_buf[2] + add_4_buf[3];
			add_5_buf[2] <= add_4_buf[4] + add_4_buf[5];
			add_5_buf[3] <= add_4_buf[6] + add_4_buf[7];
		end

		else
		begin
			add_5_buf[0] <= add_5_buf[0];
			add_5_buf[1] <= add_5_buf[1];
			add_5_buf[2] <= add_5_buf[2];
			add_5_buf[3] <= add_5_buf[3];
		end
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
		begin
			add_6_buf[0] <= 0;
			add_6_buf[1] <= 0;
		end

		else if (state == ADD_6)
		begin
			add_6_buf[0] <= add_5_buf[0] + add_5_buf[1];
			add_6_buf[1] <= add_5_buf[2] + add_5_buf[3];
		end

		else
		begin
			add_6_buf[0] <= add_6_buf[0];
			add_6_buf[1] <= add_6_buf[1];
		end
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			add_7_buf <= 0;

		else
			add_7_buf <= (state == ADD_7) ? (add_6_buf[0] + add_6_buf[1]) : add_7_buf;
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			adc_m_axis_tdata <= 0;

		else
			adc_m_axis_tdata <= (state == SHIFT) ? (add_7_buf >> 7) : adc_m_axis_tdata;
	end

	always @(posedge i_clk or negedge i_rst) 
    begin
		if (~i_rst)
		begin
			adc_tmp[0  ] <= 0;
			adc_tmp[1  ] <= 0;
			adc_tmp[2  ] <= 0;
			adc_tmp[3  ] <= 0;
			adc_tmp[4  ] <= 0;
			adc_tmp[5  ] <= 0;
			adc_tmp[6  ] <= 0;
			adc_tmp[7  ] <= 0;
			adc_tmp[8  ] <= 0;
			adc_tmp[9  ] <= 0;
			adc_tmp[10 ] <= 0;
			adc_tmp[11 ] <= 0;
			adc_tmp[12 ] <= 0;
			adc_tmp[13 ] <= 0;
			adc_tmp[14 ] <= 0;
			adc_tmp[15 ] <= 0;
			adc_tmp[16 ] <= 0;
			adc_tmp[17 ] <= 0;
			adc_tmp[18 ] <= 0;
			adc_tmp[19 ] <= 0;
			adc_tmp[20 ] <= 0;
			adc_tmp[21 ] <= 0;
			adc_tmp[22 ] <= 0;
			adc_tmp[23 ] <= 0;
			adc_tmp[24 ] <= 0;
			adc_tmp[25 ] <= 0;
			adc_tmp[26 ] <= 0;
			adc_tmp[27 ] <= 0;
			adc_tmp[28 ] <= 0;
			adc_tmp[29 ] <= 0;
			adc_tmp[30 ] <= 0;
			adc_tmp[31 ] <= 0;
			adc_tmp[32 ] <= 0;
			adc_tmp[33 ] <= 0;
			adc_tmp[34 ] <= 0;
			adc_tmp[35 ] <= 0;
			adc_tmp[36 ] <= 0;
			adc_tmp[37 ] <= 0;
			adc_tmp[38 ] <= 0;
			adc_tmp[39 ] <= 0;
			adc_tmp[40 ] <= 0;
			adc_tmp[41 ] <= 0;
			adc_tmp[42 ] <= 0;
			adc_tmp[43 ] <= 0;
			adc_tmp[44 ] <= 0;
			adc_tmp[45 ] <= 0;
			adc_tmp[46 ] <= 0;
			adc_tmp[47 ] <= 0;
			adc_tmp[48 ] <= 0;
			adc_tmp[49 ] <= 0;
			adc_tmp[50 ] <= 0;
			adc_tmp[51 ] <= 0;
			adc_tmp[52 ] <= 0;
			adc_tmp[53 ] <= 0;
			adc_tmp[54 ] <= 0;
			adc_tmp[55 ] <= 0;
			adc_tmp[56 ] <= 0;
			adc_tmp[57 ] <= 0;
			adc_tmp[58 ] <= 0;
			adc_tmp[59 ] <= 0;
			adc_tmp[60 ] <= 0;
			adc_tmp[61 ] <= 0;
			adc_tmp[62 ] <= 0;
			adc_tmp[63 ] <= 0;
			adc_tmp[64 ] <= 0;
			adc_tmp[65 ] <= 0;
			adc_tmp[66 ] <= 0;
			adc_tmp[67 ] <= 0;
			adc_tmp[68 ] <= 0;
			adc_tmp[69 ] <= 0;
			adc_tmp[70 ] <= 0;
			adc_tmp[71 ] <= 0;
			adc_tmp[72 ] <= 0;
			adc_tmp[73 ] <= 0;
			adc_tmp[74 ] <= 0;
			adc_tmp[75 ] <= 0;
			adc_tmp[76 ] <= 0;
			adc_tmp[77 ] <= 0;
			adc_tmp[78 ] <= 0;
			adc_tmp[79 ] <= 0;
			adc_tmp[80 ] <= 0;
			adc_tmp[81 ] <= 0;
			adc_tmp[82 ] <= 0;
			adc_tmp[83 ] <= 0;
			adc_tmp[84 ] <= 0;
			adc_tmp[85 ] <= 0;
			adc_tmp[86 ] <= 0;
			adc_tmp[87 ] <= 0;
			adc_tmp[88 ] <= 0;
			adc_tmp[89 ] <= 0;
			adc_tmp[90 ] <= 0;
			adc_tmp[91 ] <= 0;
			adc_tmp[92 ] <= 0;
			adc_tmp[93 ] <= 0;
			adc_tmp[94 ] <= 0;
			adc_tmp[95 ] <= 0;
			adc_tmp[96 ] <= 0;
			adc_tmp[97 ] <= 0;
			adc_tmp[98 ] <= 0;
			adc_tmp[99 ] <= 0;
			adc_tmp[100] <= 0;
			adc_tmp[101] <= 0;
			adc_tmp[102] <= 0;
			adc_tmp[103] <= 0;
			adc_tmp[104] <= 0;
			adc_tmp[105] <= 0;
			adc_tmp[106] <= 0;
			adc_tmp[107] <= 0;
			adc_tmp[108] <= 0;
			adc_tmp[109] <= 0;
			adc_tmp[110] <= 0;
			adc_tmp[111] <= 0;
			adc_tmp[112] <= 0;
			adc_tmp[113] <= 0;
			adc_tmp[114] <= 0;
			adc_tmp[115] <= 0;
			adc_tmp[116] <= 0;
			adc_tmp[117] <= 0;
			adc_tmp[118] <= 0;
			adc_tmp[119] <= 0;
			adc_tmp[120] <= 0;
			adc_tmp[121] <= 0;
			adc_tmp[122] <= 0;
			adc_tmp[123] <= 0;
			adc_tmp[124] <= 0;
			adc_tmp[125] <= 0;
			adc_tmp[126] <= 0;
			adc_tmp[127] <= 0;
		end

		else if (i_adc_valid)
		begin
			adc_tmp[0  ] <= {~i_adc_data[23], i_adc_data[22:0]};
			adc_tmp[1  ] <= adc_tmp[0  ];
			adc_tmp[2  ] <= adc_tmp[1  ];
			adc_tmp[3  ] <= adc_tmp[2  ];
			adc_tmp[4  ] <= adc_tmp[3  ];
			adc_tmp[5  ] <= adc_tmp[4  ];
			adc_tmp[6  ] <= adc_tmp[5  ];
			adc_tmp[7  ] <= adc_tmp[6  ];
			adc_tmp[8  ] <= adc_tmp[7  ];
			adc_tmp[9  ] <= adc_tmp[8  ];
			adc_tmp[10 ] <= adc_tmp[9  ];
			adc_tmp[11 ] <= adc_tmp[10 ];
			adc_tmp[12 ] <= adc_tmp[11 ];
			adc_tmp[13 ] <= adc_tmp[12 ];
			adc_tmp[14 ] <= adc_tmp[13 ];
			adc_tmp[15 ] <= adc_tmp[14 ];
			adc_tmp[16 ] <= adc_tmp[15 ];
			adc_tmp[17 ] <= adc_tmp[16 ];
			adc_tmp[18 ] <= adc_tmp[17 ];
			adc_tmp[19 ] <= adc_tmp[18 ];
			adc_tmp[20 ] <= adc_tmp[19 ];
			adc_tmp[21 ] <= adc_tmp[20 ];
			adc_tmp[22 ] <= adc_tmp[21 ];
			adc_tmp[23 ] <= adc_tmp[22 ];
			adc_tmp[24 ] <= adc_tmp[23 ];
			adc_tmp[25 ] <= adc_tmp[24 ];
			adc_tmp[26 ] <= adc_tmp[25 ];
			adc_tmp[27 ] <= adc_tmp[26 ];
			adc_tmp[28 ] <= adc_tmp[27 ];
			adc_tmp[29 ] <= adc_tmp[28 ];
			adc_tmp[30 ] <= adc_tmp[29 ];
			adc_tmp[31 ] <= adc_tmp[30 ];
			adc_tmp[32 ] <= adc_tmp[31 ];
			adc_tmp[33 ] <= adc_tmp[32 ];
			adc_tmp[34 ] <= adc_tmp[33 ];
			adc_tmp[35 ] <= adc_tmp[34 ];
			adc_tmp[36 ] <= adc_tmp[35 ];
			adc_tmp[37 ] <= adc_tmp[36 ];
			adc_tmp[38 ] <= adc_tmp[37 ];
			adc_tmp[39 ] <= adc_tmp[38 ];
			adc_tmp[40 ] <= adc_tmp[39 ];
			adc_tmp[41 ] <= adc_tmp[40 ];
			adc_tmp[42 ] <= adc_tmp[41 ];
			adc_tmp[43 ] <= adc_tmp[42 ];
			adc_tmp[44 ] <= adc_tmp[43 ];
			adc_tmp[45 ] <= adc_tmp[44 ];
			adc_tmp[46 ] <= adc_tmp[45 ];
			adc_tmp[47 ] <= adc_tmp[46 ];
			adc_tmp[48 ] <= adc_tmp[47 ];
			adc_tmp[49 ] <= adc_tmp[48 ];
			adc_tmp[50 ] <= adc_tmp[49 ];
			adc_tmp[51 ] <= adc_tmp[50 ];
			adc_tmp[52 ] <= adc_tmp[51 ];
			adc_tmp[53 ] <= adc_tmp[52 ];
			adc_tmp[54 ] <= adc_tmp[53 ];
			adc_tmp[55 ] <= adc_tmp[54 ];
			adc_tmp[56 ] <= adc_tmp[55 ];
			adc_tmp[57 ] <= adc_tmp[56 ];
			adc_tmp[58 ] <= adc_tmp[57 ];
			adc_tmp[59 ] <= adc_tmp[58 ];
			adc_tmp[60 ] <= adc_tmp[59 ];
			adc_tmp[61 ] <= adc_tmp[60 ];
			adc_tmp[62 ] <= adc_tmp[61 ];
			adc_tmp[63 ] <= adc_tmp[62 ];
			adc_tmp[64 ] <= adc_tmp[63 ];
			adc_tmp[65 ] <= adc_tmp[64 ];
			adc_tmp[66 ] <= adc_tmp[65 ];
			adc_tmp[67 ] <= adc_tmp[66 ];
			adc_tmp[68 ] <= adc_tmp[67 ];
			adc_tmp[69 ] <= adc_tmp[68 ];
			adc_tmp[70 ] <= adc_tmp[69 ];
			adc_tmp[71 ] <= adc_tmp[70 ];
			adc_tmp[72 ] <= adc_tmp[71 ];
			adc_tmp[73 ] <= adc_tmp[72 ];
			adc_tmp[74 ] <= adc_tmp[73 ];
			adc_tmp[75 ] <= adc_tmp[74 ];
			adc_tmp[76 ] <= adc_tmp[75 ];
			adc_tmp[77 ] <= adc_tmp[76 ];
			adc_tmp[78 ] <= adc_tmp[77 ];
			adc_tmp[79 ] <= adc_tmp[78 ];
			adc_tmp[80 ] <= adc_tmp[79 ];
			adc_tmp[81 ] <= adc_tmp[80 ];
			adc_tmp[82 ] <= adc_tmp[81 ];
			adc_tmp[83 ] <= adc_tmp[82 ];
			adc_tmp[84 ] <= adc_tmp[83 ];
			adc_tmp[85 ] <= adc_tmp[84 ];
			adc_tmp[86 ] <= adc_tmp[85 ];
			adc_tmp[87 ] <= adc_tmp[86 ];
			adc_tmp[88 ] <= adc_tmp[87 ];
			adc_tmp[89 ] <= adc_tmp[88 ];
			adc_tmp[90 ] <= adc_tmp[89 ];
			adc_tmp[91 ] <= adc_tmp[90 ];
			adc_tmp[92 ] <= adc_tmp[91 ];
			adc_tmp[93 ] <= adc_tmp[92 ];
			adc_tmp[94 ] <= adc_tmp[93 ];
			adc_tmp[95 ] <= adc_tmp[94 ];
			adc_tmp[96 ] <= adc_tmp[95 ];
			adc_tmp[97 ] <= adc_tmp[96 ];
			adc_tmp[98 ] <= adc_tmp[97 ];
			adc_tmp[99 ] <= adc_tmp[98 ];
			adc_tmp[100] <= adc_tmp[99 ];
			adc_tmp[101] <= adc_tmp[100];
			adc_tmp[102] <= adc_tmp[101];
			adc_tmp[103] <= adc_tmp[102];
			adc_tmp[104] <= adc_tmp[103];
			adc_tmp[105] <= adc_tmp[104];
			adc_tmp[106] <= adc_tmp[105];
			adc_tmp[107] <= adc_tmp[106];
			adc_tmp[108] <= adc_tmp[107];
			adc_tmp[109] <= adc_tmp[108];
			adc_tmp[110] <= adc_tmp[109];
			adc_tmp[111] <= adc_tmp[110];
			adc_tmp[112] <= adc_tmp[111];
			adc_tmp[113] <= adc_tmp[112];
			adc_tmp[114] <= adc_tmp[113];
			adc_tmp[115] <= adc_tmp[114];
			adc_tmp[116] <= adc_tmp[115];
			adc_tmp[117] <= adc_tmp[116];
			adc_tmp[118] <= adc_tmp[117];
			adc_tmp[119] <= adc_tmp[118];
			adc_tmp[120] <= adc_tmp[119];
			adc_tmp[121] <= adc_tmp[120];
			adc_tmp[122] <= adc_tmp[121];
			adc_tmp[123] <= adc_tmp[122];
			adc_tmp[124] <= adc_tmp[123];
			adc_tmp[125] <= adc_tmp[124];
			adc_tmp[126] <= adc_tmp[125];
			adc_tmp[127] <= adc_tmp[126];
		end

		else
		begin
			adc_tmp[0  ] <= adc_tmp[0  ];
			adc_tmp[1  ] <= adc_tmp[1  ];
			adc_tmp[2  ] <= adc_tmp[2  ];
			adc_tmp[3  ] <= adc_tmp[3  ];
			adc_tmp[4  ] <= adc_tmp[4  ];
			adc_tmp[5  ] <= adc_tmp[5  ];
			adc_tmp[6  ] <= adc_tmp[6  ];
			adc_tmp[7  ] <= adc_tmp[7  ];
			adc_tmp[8  ] <= adc_tmp[8  ];
			adc_tmp[9  ] <= adc_tmp[9  ];
			adc_tmp[10 ] <= adc_tmp[10 ];
			adc_tmp[11 ] <= adc_tmp[11 ];
			adc_tmp[12 ] <= adc_tmp[12 ];
			adc_tmp[13 ] <= adc_tmp[13 ];
			adc_tmp[14 ] <= adc_tmp[14 ];
			adc_tmp[15 ] <= adc_tmp[15 ];
			adc_tmp[16 ] <= adc_tmp[16 ];
			adc_tmp[17 ] <= adc_tmp[17 ];
			adc_tmp[18 ] <= adc_tmp[18 ];
			adc_tmp[19 ] <= adc_tmp[19 ];
			adc_tmp[20 ] <= adc_tmp[20 ];
			adc_tmp[21 ] <= adc_tmp[21 ];
			adc_tmp[22 ] <= adc_tmp[22 ];
			adc_tmp[23 ] <= adc_tmp[23 ];
			adc_tmp[24 ] <= adc_tmp[24 ];
			adc_tmp[25 ] <= adc_tmp[25 ];
			adc_tmp[26 ] <= adc_tmp[26 ];
			adc_tmp[27 ] <= adc_tmp[27 ];
			adc_tmp[28 ] <= adc_tmp[28 ];
			adc_tmp[29 ] <= adc_tmp[29 ];
			adc_tmp[30 ] <= adc_tmp[30 ];
			adc_tmp[31 ] <= adc_tmp[31 ];
			adc_tmp[32 ] <= adc_tmp[32 ];
			adc_tmp[33 ] <= adc_tmp[33 ];
			adc_tmp[34 ] <= adc_tmp[34 ];
			adc_tmp[35 ] <= adc_tmp[35 ];
			adc_tmp[36 ] <= adc_tmp[36 ];
			adc_tmp[37 ] <= adc_tmp[37 ];
			adc_tmp[38 ] <= adc_tmp[38 ];
			adc_tmp[39 ] <= adc_tmp[39 ];
			adc_tmp[40 ] <= adc_tmp[40 ];
			adc_tmp[41 ] <= adc_tmp[41 ];
			adc_tmp[42 ] <= adc_tmp[42 ];
			adc_tmp[43 ] <= adc_tmp[43 ];
			adc_tmp[44 ] <= adc_tmp[44 ];
			adc_tmp[45 ] <= adc_tmp[45 ];
			adc_tmp[46 ] <= adc_tmp[46 ];
			adc_tmp[47 ] <= adc_tmp[47 ];
			adc_tmp[48 ] <= adc_tmp[48 ];
			adc_tmp[49 ] <= adc_tmp[49 ];
			adc_tmp[50 ] <= adc_tmp[50 ];
			adc_tmp[51 ] <= adc_tmp[51 ];
			adc_tmp[52 ] <= adc_tmp[52 ];
			adc_tmp[53 ] <= adc_tmp[53 ];
			adc_tmp[54 ] <= adc_tmp[54 ];
			adc_tmp[55 ] <= adc_tmp[55 ];
			adc_tmp[56 ] <= adc_tmp[56 ];
			adc_tmp[57 ] <= adc_tmp[57 ];
			adc_tmp[58 ] <= adc_tmp[58 ];
			adc_tmp[59 ] <= adc_tmp[59 ];
			adc_tmp[60 ] <= adc_tmp[60 ];
			adc_tmp[61 ] <= adc_tmp[61 ];
			adc_tmp[62 ] <= adc_tmp[62 ];
			adc_tmp[63 ] <= adc_tmp[63 ];
			adc_tmp[64 ] <= adc_tmp[64 ];
			adc_tmp[65 ] <= adc_tmp[65 ];
			adc_tmp[66 ] <= adc_tmp[66 ];
			adc_tmp[67 ] <= adc_tmp[67 ];
			adc_tmp[68 ] <= adc_tmp[68 ];
			adc_tmp[69 ] <= adc_tmp[69 ];
			adc_tmp[70 ] <= adc_tmp[70 ];
			adc_tmp[71 ] <= adc_tmp[71 ];
			adc_tmp[72 ] <= adc_tmp[72 ];
			adc_tmp[73 ] <= adc_tmp[73 ];
			adc_tmp[74 ] <= adc_tmp[74 ];
			adc_tmp[75 ] <= adc_tmp[75 ];
			adc_tmp[76 ] <= adc_tmp[76 ];
			adc_tmp[77 ] <= adc_tmp[77 ];
			adc_tmp[78 ] <= adc_tmp[78 ];
			adc_tmp[79 ] <= adc_tmp[79 ];
			adc_tmp[80 ] <= adc_tmp[80 ];
			adc_tmp[81 ] <= adc_tmp[81 ];
			adc_tmp[82 ] <= adc_tmp[82 ];
			adc_tmp[83 ] <= adc_tmp[83 ];
			adc_tmp[84 ] <= adc_tmp[84 ];
			adc_tmp[85 ] <= adc_tmp[85 ];
			adc_tmp[86 ] <= adc_tmp[86 ];
			adc_tmp[87 ] <= adc_tmp[87 ];
			adc_tmp[88 ] <= adc_tmp[88 ];
			adc_tmp[89 ] <= adc_tmp[89 ];
			adc_tmp[90 ] <= adc_tmp[90 ];
			adc_tmp[91 ] <= adc_tmp[91 ];
			adc_tmp[92 ] <= adc_tmp[92 ];
			adc_tmp[93 ] <= adc_tmp[93 ];
			adc_tmp[94 ] <= adc_tmp[94 ];
			adc_tmp[95 ] <= adc_tmp[95 ];
			adc_tmp[96 ] <= adc_tmp[96 ];
			adc_tmp[97 ] <= adc_tmp[97 ];
			adc_tmp[98 ] <= adc_tmp[98 ];
			adc_tmp[99 ] <= adc_tmp[99 ];
			adc_tmp[100] <= adc_tmp[100];
			adc_tmp[101] <= adc_tmp[101];
			adc_tmp[102] <= adc_tmp[102];
			adc_tmp[103] <= adc_tmp[103];
			adc_tmp[104] <= adc_tmp[104];
			adc_tmp[105] <= adc_tmp[105];
			adc_tmp[106] <= adc_tmp[106];
			adc_tmp[107] <= adc_tmp[107];
			adc_tmp[108] <= adc_tmp[108];
			adc_tmp[109] <= adc_tmp[109];
			adc_tmp[110] <= adc_tmp[110];
			adc_tmp[111] <= adc_tmp[111];
			adc_tmp[112] <= adc_tmp[112];
			adc_tmp[113] <= adc_tmp[113];
			adc_tmp[114] <= adc_tmp[114];
			adc_tmp[115] <= adc_tmp[115];
			adc_tmp[116] <= adc_tmp[116];
			adc_tmp[117] <= adc_tmp[117];
			adc_tmp[118] <= adc_tmp[118];
			adc_tmp[119] <= adc_tmp[119];
			adc_tmp[120] <= adc_tmp[120];
			adc_tmp[121] <= adc_tmp[121];
			adc_tmp[122] <= adc_tmp[122];
			adc_tmp[123] <= adc_tmp[123];
			adc_tmp[124] <= adc_tmp[124];
			adc_tmp[125] <= adc_tmp[125];
			adc_tmp[126] <= adc_tmp[126];
			adc_tmp[127] <= adc_tmp[127];
		end
	end

	assign adc_m_axis_tvalid = (state == DONE);

endmodule