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
	localparam SHIFT	= 6;
	localparam DONE		= 7;

	// FSM
	reg [2:0] state;
	reg [2:0] n_state;

	reg [23:0] adc_tmp [15:0];

	reg [31:0] add_1_buf[7:0];
	reg [31:0] add_2_buf[4:0];
	reg [31:0] add_3_buf[1:0];
	reg [31:0] add_4_buf;

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
            ADD_4 	: n_state = SHIFT;
            SHIFT 	: n_state = DONE;
            DONE 	: n_state = IDLE;
			default	: n_state = IDLE;
		endcase
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
		begin
			add_1_buf[0] <= 0;
			add_1_buf[1] <= 0;
			add_1_buf[2] <= 0;
			add_1_buf[3] <= 0;
			add_1_buf[4] <= 0;
			add_1_buf[5] <= 0;
			add_1_buf[6] <= 0;
			add_1_buf[7] <= 0;
		end

		else if (state == ADD_1)
		begin
			add_1_buf[0] <= adc_tmp[0] + adc_tmp[1];
			add_1_buf[1] <= adc_tmp[2] + adc_tmp[3];
			add_1_buf[2] <= adc_tmp[4] + adc_tmp[5];
			add_1_buf[3] <= adc_tmp[6] + adc_tmp[7];
			add_1_buf[4] <= adc_tmp[8] + adc_tmp[9];
			add_1_buf[5] <= adc_tmp[10] + adc_tmp[11];
			add_1_buf[6] <= adc_tmp[12] + adc_tmp[13];
			add_1_buf[7] <= adc_tmp[14] + adc_tmp[15];
		end

		else
		begin
			add_1_buf[0] <= add_1_buf[0];
			add_1_buf[1] <= add_1_buf[1];
			add_1_buf[2] <= add_1_buf[2];
			add_1_buf[3] <= add_1_buf[3];
			add_1_buf[4] <= add_1_buf[4];
			add_1_buf[5] <= add_1_buf[5];
			add_1_buf[6] <= add_1_buf[6];
			add_1_buf[7] <= add_1_buf[7];
		end
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
		begin
			add_2_buf[0] <= 0;
			add_2_buf[1] <= 0;
			add_2_buf[2] <= 0;
			add_2_buf[3] <= 0;
		end

		else if (state == ADD_2)
		begin
			add_2_buf[0] <= add_1_buf[0] + add_1_buf[1];
			add_2_buf[1] <= add_1_buf[2] + add_1_buf[3];
			add_2_buf[2] <= add_1_buf[4] + add_1_buf[5];
			add_2_buf[3] <= add_1_buf[6] + add_1_buf[7];
		end

		else
		begin
			add_2_buf[0] <= add_2_buf[0];
			add_2_buf[1] <= add_2_buf[1];
			add_2_buf[2] <= add_2_buf[2];
			add_2_buf[3] <= add_2_buf[3];
		end
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
		begin
			add_3_buf[0] <= 0;
			add_3_buf[1] <= 0;
		end

		else if (state == ADD_3)
		begin
			add_3_buf[0] <= add_2_buf[0] + add_2_buf[1];
			add_3_buf[1] <= add_2_buf[2] + add_2_buf[3];
		end

		else
		begin
			add_3_buf[0] <= add_3_buf[0];
			add_3_buf[1] <= add_3_buf[1];
		end
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			add_4_buf <= 0;

		else
			add_4_buf <= (state == ADD_4) ? (add_3_buf[0] + add_3_buf[1]) : add_4_buf;
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			adc_m_axis_tdata <= 0;

		else
			adc_m_axis_tdata <= (state == SHIFT) ? (add_4_buf >> 4) : adc_m_axis_tdata;
	end

	always @(posedge i_clk or negedge i_rst) 
    begin
		if (~i_rst)
		begin
			adc_tmp[0] <= 0;
			adc_tmp[1] <= 0;
			adc_tmp[2] <= 0;
			adc_tmp[3] <= 0;
			adc_tmp[4] <= 0;
			adc_tmp[5] <= 0;
			adc_tmp[6] <= 0;
			adc_tmp[7] <= 0;
			adc_tmp[8] <= 0;
			adc_tmp[9] <= 0;
			adc_tmp[10] <= 0;
			adc_tmp[11] <= 0;
			adc_tmp[12] <= 0;
			adc_tmp[13] <= 0;
			adc_tmp[14] <= 0;
			adc_tmp[15] <= 0;
		end

		else if (i_adc_valid)
		begin
			adc_tmp[0] <= {~i_adc_data[23], i_adc_data[22:0]};
			adc_tmp[1] <= adc_tmp[0];
			adc_tmp[2] <= adc_tmp[1];
			adc_tmp[3] <= adc_tmp[2];
			adc_tmp[4] <= adc_tmp[3];
			adc_tmp[5] <= adc_tmp[4];
			adc_tmp[6] <= adc_tmp[5];
			adc_tmp[7] <= adc_tmp[6];
			adc_tmp[8] <= adc_tmp[7];
			adc_tmp[9] <= adc_tmp[8];
			adc_tmp[10] <= adc_tmp[9];
			adc_tmp[11] <= adc_tmp[10];
			adc_tmp[12] <= adc_tmp[11];
			adc_tmp[13] <= adc_tmp[12];
			adc_tmp[14] <= adc_tmp[13];
			adc_tmp[15] <= adc_tmp[14];
		end

		else
		begin
			adc_tmp[0] <= adc_tmp[0];
			adc_tmp[1] <= adc_tmp[1];
			adc_tmp[2] <= adc_tmp[2];
			adc_tmp[3] <= adc_tmp[3];
			adc_tmp[4] <= adc_tmp[4];
			adc_tmp[5] <= adc_tmp[5];
			adc_tmp[6] <= adc_tmp[6];
			adc_tmp[7] <= adc_tmp[7];
			adc_tmp[8] <= adc_tmp[8];
			adc_tmp[9] <= adc_tmp[9];
			adc_tmp[10] <= adc_tmp[10];
			adc_tmp[11] <= adc_tmp[11];
			adc_tmp[12] <= adc_tmp[12];
			adc_tmp[13] <= adc_tmp[13];
			adc_tmp[14] <= adc_tmp[14];
			adc_tmp[15] <= adc_tmp[15];
		end
	end

	assign adc_m_axis_tvalid = (state == DONE);

endmodule