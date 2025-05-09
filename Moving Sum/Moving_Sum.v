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

	integer i;
	genvar j;

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

    generate
	for (j = 0; j < 64; j = j + 1) begin : add_1_buf_set
		always @(posedge i_clk or negedge i_rst)
		begin
			if (~i_rst)
				add_1_buf[j] <= 0;

			else if (state == ADD_1)
        		add_1_buf[j] <= adc_tmp[j << 1] + adc_tmp[(j << 1) + 1];

			else
				add_1_buf[j] <= add_1_buf[j];
		end
	end
	endgenerate

    generate
	for (j = 0; j < 32; j = j + 1) begin : add_2_buf_set
		always @(posedge i_clk or negedge i_rst)
		begin
			if (~i_rst)
				add_2_buf[j] <= 0;

			else if (state == ADD_2)
        		add_2_buf[j] <= add_1_buf[j << 1] + add_1_buf[(j << 1) + 1];

			else
				add_2_buf[j] <= add_2_buf[j];
		end
	end
	endgenerate

	generate
	for (j = 0; j < 16; j = j + 1) begin : add_3_buf_set
		always @(posedge i_clk or negedge i_rst)
		begin
			if (~i_rst)
				add_3_buf[j] <= 0;

			else if (state == ADD_3)
        		add_3_buf[j] <= add_2_buf[j << 1] + add_2_buf[(j << 1) + 1];

			else
				add_3_buf[j] <= add_3_buf[j];
		end
	end
	endgenerate

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
		if (!i_rst)
		begin
			for (i = 0; i < 128; i = i + 1)
				adc_tmp[i] <= 0;
		end

		else if (i_adc_valid)
		begin
			adc_tmp[0] <= {~i_adc_data[23], i_adc_data[22:0]};
			for (i = 0; i < 127; i = i + 1)
				adc_tmp[i+1] <= adc_tmp[i];
		end

		else
		begin
			for (i = 0; i < 128; i = i + 1)
				adc_tmp[i] <= adc_tmp[i];
		end
	end

	assign adc_m_axis_tvalid = (state == DONE);

endmodule