`timescale 1 ns / 1 ps

/*

MPS ADC Module
���� 4�� ����� ����

24.05.08 :	���� ����

1. ����
 �� 16���� ADC Data�� �ջ�
 ADC �ֱ⸶�� Shift�Ͽ� ������

2. �����
 n-15 + n-14 + ... + n = Output Data
 n�� ���� ADC ��
 �ش� ���� Floating Point�� ��ȯ �� ���Ŀ� ���ؼ� 1���� �����ͷ� �����
 
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

	genvar add_1_len;
	genvar add_2_len;
	genvar add_3_len;
	genvar add_4_len;
	genvar add_5_len;
	genvar adc_tmp_len;

	generate
		for (add_1_len = 0; add_1_len < 64; add_1_len = add_1_len + 1)
		begin
			always @(posedge i_clk or negedge i_rst)
			begin
				if (~i_rst)
					add_1_buf[add_1_len] <= 0;

				else
					add_1_buf[add_1_len] <= (state == ADD_1) ? adc_tmp[add_1_len * 2] + adc_tmp[(add_1_len * 2) + 1] : add_1_buf[add_1_len];
			end
		end
	endgenerate

	generate
		for (add_2_len = 0; add_2_len < 32; add_2_len = add_2_len + 1)
		begin
			always @(posedge i_clk or negedge i_rst)
			begin
				if (~i_rst)
					add_2_buf[add_2_len] <= 0;
				
				else
					add_2_buf[add_2_len] <= (state == ADD_1) ? add_1_buf[add_2_len * 2] + add_1_buf[(add_2_len * 2) + 1] : add_2_buf[add_2_len];
			end
		end
	endgenerate

	generate
		for (add_3_len = 0; add_3_len < 16; add_3_len = add_3_len + 1)
		begin
			always @(posedge i_clk or negedge i_rst)
			begin
				if (~i_rst)
					add_3_buf[add_3_len] <= 0;
				
				else
					add_3_buf[add_3_len] <= (state == ADD_1) ? add_2_buf[add_3_len * 2] + add_2_buf[(add_3_len * 2) + 1] : add_3_buf[add_3_len];
			end
		end
	endgenerate

	generate
		for (add_4_len = 0; add_4_len < 8; add_4_len = add_4_len + 1)
		begin
			always @(posedge i_clk or negedge i_rst)
			begin
				if (~i_rst)
					add_4_buf[add_4_len] <= 0;
				
				else
					add_4_buf[add_4_len] <= (state == ADD_1) ? add_3_buf[add_4_len * 2] + add_3_buf[(add_4_len * 2) + 1] : add_4_buf[add_4_len];
			end
		end
	endgenerate

	generate
		for (add_5_len = 0; add_5_len < 4; add_5_len = add_5_len + 1)
		begin
			always @(posedge i_clk or negedge i_rst)
			begin
				if (~i_rst)
					add_5_buf[add_5_len] <= 0;
				
				else
					add_5_buf[add_5_len] <= (state == ADD_1) ? add_4_buf[add_5_len * 2] + add_4_buf[(add_5_len * 2) + 1] : add_5_buf[add_5_len];
			end
		end
	endgenerate

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

	generate
		for (adc_tmp_len = 0; adc_tmp_len < 128; adc_tmp_len = adc_tmp_len + 1)
		begin
			always @(posedge i_clk or negedge i_rst)
			begin
				if (~i_rst)
					adc_tmp[adc_tmp_len] <= 0;

				else
					adc_tmp[adc_tmp_len] <= (i_adc_valid) ? ((adc_tmp_len == 0) ? {~i_adc_data[23], i_adc_data[22:0]} : adc_tmp[adc_tmp_len - 1]) : adc_tmp[adc_tmp_len];
			end
		end
	endgenerate

	assign adc_m_axis_tvalid = (state == DONE);

endmodule