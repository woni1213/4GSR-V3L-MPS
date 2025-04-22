`timescale 1 ns / 1 ps

/*

MPS INTerLock Module
개발 4팀 전경원 차장

24.07.04 :	최초 생성
24.07.19 : 	OSC Interlock 추가
24.07.22 :	REGU Interlock 추가

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - 

1. o_intl_state
 - 16 Bit
 - Interlock 상태를 EPICS와 DSP로 보내줌

 0	: 외부 인터락 입력 1
 1	: 외부 인터락 입력 2
 2	: 외부 인터락 입력 3
 3	: 외부 인터락 입력 4

 4	: 제어보드 OC
 5	: 전력보드 OC (POC)
 6	: 전력보드 OV
 7	: 전력보드 OH (Over Heat) 사용 안함

 8	: S/W UV (DC-Link Under Voltage)
 9	: S/W OV
 10	: S/W OC

 11	: OSC 전류 인터락
 12	: OSC 전압 인터락
 13	: REGU 전류 인터락
 14	: REGU 전류 인터락

 15 : System Reset Monitor

2. i_intl_ctrl (삭제 - AXI Module에서 분할함)
 - 16 Bit
 - Interlock 관련 명령 및 데이터
 - From. EPICS

 0	: 외부 인터락 출력 1
 1	: 외부 인터락 출력 2
 2	: 외부 인터락 출력 3
 3	: 외부 인터락 출력 4

 4	: OC Reset
 5	: POC Reset

 8	: 외부 인터락 입력 1 Bypass
 9	: 외부 인터락 입력 2 Bypass
 10	: 외부 인터락 입력 3 Bypass
 11	: 외부 인터락 입력 4 Bypass

3. Oscillation Interlock
 - 출력이 발진될 때 동작
 - 2의 보수로 구성된 ADC Data를 ADC IP에서 16번 더한 값을 기준으로 동작함
 - 따라서 ADC Data를 Offset Binary를 취하여 계산
 - 계산 방법은 MSB를 반전시킴 (27번째 Bit. 16번 더함으로 4개의 Bit가 << 됨. 따라서 27Bit임)

4. Regulation Interlock
 - 출력 값을 입력한 후 동작
 - 출력 값 변경 후 일정시간 지난 뒤에 설정한 출력 값까지 실제 출력 값에 맞지 않는 경우 발생
 - 출력의 모드에 따라서 동작함 (C.C or C.V)

5. 검토 사항
 - OSC, REGU는 Offset Binary 타입이고 나머지는 TCC 타입임
 - REGU 관련 time, diff 값은 비트 수 조절해야함

*/

module INTL
(
	input i_clk,
	input i_rst,
	
	// From MPS_Core_v1_0_Top
	input i_intl_clr,
	input i_mps_polarity,

	// External Interlock Input
	input [15:0] i_intl_ext,

	input [31:0] i_intl_ext_bypass,

	// H/W Interlock
	input i_intl_OC,
	input [3:0] i_pwm_fault,
	// input i_intl_OV,
	// input i_intl_OH,

	// Reset
	input i_sys_rst_flag,

	// ADC
	input [31:0] i_dc_floating_data,
	input [31:0] i_c_floating_data,
	input [31:0] i_v_floating_data,

	// Over Range
	input [31:0] i_intl_OC_p,
	input [31:0] i_intl_OC_n,
	input [31:0] i_intl_OV_p,
	input [31:0] i_intl_OV_n,
	input [31:0] i_intl_UV,

	// Oscillation (OSC)
	input i_intl_OSC_bypass,
	input [31:0] i_c_intl_OSC_adc_threshold,
	input [9:0]	i_c_intl_OSC_count_threshold,
	input [31:0] i_v_intl_OSC_adc_threshold,
	input [9:0]	i_v_intl_OSC_count_threshold,
	input [19:0] i_intl_OSC_period,				// Count Cycle Period. Max 1,048,576 = 5,242,880 ns
	input [9:0] i_intl_OSC_cycle_count,			// Count Cycle Periode * i_intl_OSC_cycle_count = Total Period. Max 1024
	
	// REGulation (REGU)
	input i_intl_REGU_mode,						// Output Mode (0 : C.C or 1 : C.V)
	input i_intl_REGU_bypass,
	
	input [31:0] i_c_intl_REGU_sp,				// Output Set Value
	input [31:0] i_c_intl_REGU_diff,			// Regulation Differential Threashold
	input [31:0] i_c_intl_REGU_delay,			// Regulation Delay Time
	input [31:0] i_v_intl_REGU_sp,
	input [31:0] i_v_intl_REGU_diff,
	input [31:0] i_v_intl_REGU_delay,

	// Interlock State
	output reg [31:0] o_intl_state,
	output reg [15:0] o_ext_intl_state,

	output [2:0] o_osc_fsm_state,
	output [1:0] o_regu_fsm_state
);

	parameter OSC_IDLE	= 0;
	parameter OSC_RUN	= 1;
	parameter OSC_COUNT	= 2;
	parameter OSC_DELAY	= 3;
	parameter OSC_RESET	= 4;

	parameter REGU_IDLE		= 0;
	parameter REGU_DELAY	= 1;
	parameter REGU_RUN		= 2;
	parameter REGU_DONE		= 3;

	// FSM
	reg [2:0] OSC_state;

	reg [1:0] REGU_state;

	// Interlock Flag
	reg intl_UV;
	reg intl_OV;
	reg intl_OC;
	reg c_intl_OSC;
	reg v_intl_OSC;
	reg c_intl_REGU;
	reg v_intl_REGU;

	// Counter
	reg [19:0] intl_OSC_period_cnt;
	reg [9:0] intl_OSC_cycle_cnt;
	reg [31:0] intl_REGU_cnt;

	// Over Range
	wire [7:0] OC_p_result;
	wire [7:0] OC_n_result;
	wire [7:0] OV_p_result;
	wire [7:0] OV_n_result;
	wire [7:0] UV_result;

	wire OC_p_valid;
	wire OC_n_valid;
	wire OV_p_valid;
	wire OV_n_valid;
	wire UV_valid;

	// OSC Current
	reg [31:0] c_intl_OSC_adc_min;
	wire [7:0] c_intl_OSC_comp_min_result;
	wire c_intl_OSC_comp_min_valid;

	reg [31:0] c_intl_OSC_adc_max;
	wire[7:0] c_intl_OSC_comp_max_result;
	wire c_intl_OSC_comp_max_valid;

	wire [31:0] c_intl_OSC_adc_data;
	wire c_intl_OSC_adc_data_valid;

	reg [9:0] c_intl_OSC_cnt;	

	wire [7:0] c_intl_OSC_adc_result;
	wire c_intl_OSC_adc_result_valid;

	// OSC Voltage
	reg [31:0] v_intl_OSC_adc_min;
	wire [7:0] v_intl_OSC_comp_min_result;
	wire v_intl_OSC_comp_min_valid;

	reg [31:0] v_intl_OSC_adc_max;
	wire [7:0] v_intl_OSC_comp_max_result;
	wire v_intl_OSC_comp_max_valid;

	wire [31:0] v_intl_OSC_adc_data;
	wire v_intl_OSC_adc_data_valid;

	reg [9:0] v_intl_OSC_cnt;

	wire [7:0] v_intl_OSC_adc_result;
	
	wire v_intl_OSC_adc_result_valid;

	// REGU
	wire c_intl_REGU_sp_flag;				// Output Set Flag (REGU Start)
	wire v_intl_REGU_sp_flag;

	reg [31:0] c_intl_REGU_sp_buf;
	reg [31:0] v_intl_REGU_sp_buf;

	wire [31:0] c_intl_REGU_data;
	wire c_intl_REGU_data_valid;

	wire [31:0] c_intl_REGU_abs;
	wire c_intl_REGU_abs_valid;

	wire [7:0] c_intl_REGU_comp_result;
	wire c_intl_REGU_comp_valid;

	wire [31:0] v_intl_REGU_data;
	wire v_intl_REGU_data_valid;

	wire [31:0] v_intl_REGU_abs;
	wire v_intl_REGU_abs_valid;

	wire [7:0] v_intl_REGU_comp_result;
	wire v_intl_REGU_comp_valid;

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			OSC_state <= OSC_IDLE;

		else if (c_intl_OSC || v_intl_OSC)
			OSC_state <= OSC_IDLE;

		else
		begin
			if (OSC_state == OSC_IDLE)
				OSC_state <= (~(|o_intl_state) && ~i_intl_OSC_bypass) ? OSC_RUN : OSC_IDLE;

			else if (OSC_state == OSC_RUN)
				OSC_state <= (intl_OSC_period_cnt == i_intl_OSC_period) ? OSC_COUNT : OSC_RUN;

			else if (OSC_state == OSC_COUNT)
				OSC_state <= OSC_DELAY;

			else if (OSC_state == OSC_DELAY)
				OSC_state <= (c_intl_OSC_adc_result_valid) ? OSC_RESET : OSC_DELAY;

			else if (OSC_state == OSC_RESET)
				OSC_state <= (intl_OSC_cycle_cnt == i_intl_OSC_cycle_count + 1) ? OSC_IDLE : OSC_RUN;

			else
				OSC_state <= OSC_IDLE;
		end
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			REGU_state <= REGU_IDLE;

		else
		begin
			if (REGU_state == REGU_IDLE)
				REGU_state <= ((c_intl_REGU_sp_flag || v_intl_REGU_sp_flag) && ~(|o_intl_state)
								&& ~i_intl_REGU_bypass) ? REGU_DELAY : REGU_IDLE;

			else if (REGU_state == REGU_DELAY)
				REGU_state <= ((i_intl_REGU_mode && (intl_REGU_cnt == i_v_intl_REGU_delay)) || (intl_REGU_cnt == i_c_intl_REGU_delay)) ? REGU_RUN : REGU_DELAY;
				
			else if (REGU_state == REGU_RUN)
				REGU_state <= REGU_DONE;

			else if (REGU_state == REGU_DONE)
				REGU_state <= (~c_intl_REGU_sp_flag && ~v_intl_REGU_sp_flag) ? REGU_IDLE : REGU_DONE;

			else
				REGU_state <= REGU_IDLE;
		end
	end

	/***** Counter Control *****/
	
	// OSC Period Counter
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst) 
        	intl_OSC_period_cnt <= 0;

		else if (OSC_state == OSC_RUN)
			intl_OSC_period_cnt <= intl_OSC_period_cnt + 1;

		else
			intl_OSC_period_cnt <= 0;
	end

	// OSC Cycle Counter
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst || (OSC_state == OSC_IDLE)) 
        	intl_OSC_cycle_cnt <= 0;

		else if (OSC_state == OSC_COUNT)
			intl_OSC_cycle_cnt <= intl_OSC_cycle_cnt + 1;

		else
			intl_OSC_cycle_cnt <= intl_OSC_cycle_cnt;
	end

	// REGU Delay Counter
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst) 
        	intl_REGU_cnt <= 0;

		else if (REGU_state == REGU_DELAY)
			intl_REGU_cnt <= intl_REGU_cnt + 1;

		else
			intl_REGU_cnt <= 0;
	end

	/***** Current OSC  *****/

	// OSC ADC Data Min Calc
	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			c_intl_OSC_adc_min <= 0;

		else if ((OSC_state == OSC_IDLE) || (OSC_state == OSC_RESET))
			c_intl_OSC_adc_min <= i_c_floating_data;

		else if (OSC_state == OSC_RUN)
		begin
			if (c_intl_OSC_comp_min_result[0] && c_intl_OSC_comp_min_valid)
				c_intl_OSC_adc_min <= i_c_floating_data;
			
			else
				c_intl_OSC_adc_min <= c_intl_OSC_adc_min;
		end

		else
			c_intl_OSC_adc_min <= c_intl_OSC_adc_min;
	end

	// OSC ADC Data Max Calc
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst)
			c_intl_OSC_adc_max <= 0;

		else if ((OSC_state == OSC_IDLE) || (OSC_state == OSC_RESET))
			c_intl_OSC_adc_max <= i_c_floating_data;

		else if (OSC_state == OSC_RUN)
		begin
			if  (c_intl_OSC_comp_max_result[0] && c_intl_OSC_comp_max_valid)
				c_intl_OSC_adc_max <= i_c_floating_data;
			
			else
				c_intl_OSC_adc_max <= c_intl_OSC_adc_max;
		end

		else
			c_intl_OSC_adc_max <= c_intl_OSC_adc_max;
	end

	// OSC ADC Data ABS, Interlock Count
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst)
			c_intl_OSC_cnt <= 0;

		else if (OSC_state == OSC_IDLE)
			c_intl_OSC_cnt <= 0;

		else if(c_intl_OSC_adc_result_valid)
		begin
			if (c_intl_OSC_adc_result[0])
				c_intl_OSC_cnt <= c_intl_OSC_cnt + 1;
			
			else
			begin
				if (c_intl_OSC_cnt != 0)
					c_intl_OSC_cnt <= c_intl_OSC_cnt - 1;
					
				else
					c_intl_OSC_cnt <= c_intl_OSC_cnt;
			end
		end
	end

	// OSC Current Interlock
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst)
			c_intl_OSC <= 0;

		else if ( i_intl_clr)
			c_intl_OSC <= 0;

		else if (c_intl_OSC_cnt >= i_c_intl_OSC_count_threshold)
			c_intl_OSC <= 1;

		else
			c_intl_OSC <= c_intl_OSC;
	end

	/***** Voltage OSC  *****/

	// OSC ADC Data Min Calc
	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			v_intl_OSC_adc_min <= 0;

		else if ((OSC_state == OSC_IDLE) || (OSC_state == OSC_RESET))
			v_intl_OSC_adc_min <= i_v_floating_data;

		else if (OSC_state == OSC_RUN)
		begin
			if (v_intl_OSC_comp_min_result[0] && v_intl_OSC_comp_min_valid)
				v_intl_OSC_adc_min <= i_v_floating_data;
			
			else
				v_intl_OSC_adc_min <= v_intl_OSC_adc_min;
		end

		else
			v_intl_OSC_adc_min <= v_intl_OSC_adc_min;
	end

	// OSC ADC Data Max Calc
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst)
			v_intl_OSC_adc_max <= 0;

		else if ((OSC_state == OSC_IDLE) || (OSC_state == OSC_RESET))
			v_intl_OSC_adc_max <= i_v_floating_data;

		else if (OSC_state == OSC_RUN)
		begin
			if (v_intl_OSC_comp_max_result[0] && v_intl_OSC_comp_max_valid)
				v_intl_OSC_adc_max <= i_v_floating_data;
			
			else
				v_intl_OSC_adc_max <= v_intl_OSC_adc_max;
		end

		else
			v_intl_OSC_adc_max <= v_intl_OSC_adc_max;
	end

	// OSC ADC Data ABS, Interlock Count
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst)
			v_intl_OSC_cnt <= 0;

		else if (OSC_state == OSC_IDLE)
			v_intl_OSC_cnt <= 0;

		else if (c_intl_OSC_adc_result_valid)
		begin
			if (c_intl_OSC_adc_result[0])
				v_intl_OSC_cnt <= v_intl_OSC_cnt + 1;
			
			else
			begin
				if (v_intl_OSC_cnt != 0)
					v_intl_OSC_cnt <= v_intl_OSC_cnt - 1;

				else
					v_intl_OSC_cnt <= v_intl_OSC_cnt;
			end
		end
	end

	// OSC Current Interlock
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst)
			v_intl_OSC <= 0;
			
	   else if (i_intl_clr)
	       v_intl_OSC <= 0;

		else if (v_intl_OSC_cnt >= i_v_intl_OSC_count_threshold)
			v_intl_OSC <= 1;

		else
			v_intl_OSC <= v_intl_OSC;
	end

	/***** REGU *****/
	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
		begin
			c_intl_REGU_sp_buf <= 0;
			v_intl_REGU_sp_buf <= 0;
		end

		else
		begin
			c_intl_REGU_sp_buf <= i_c_intl_REGU_sp;
			v_intl_REGU_sp_buf <= i_v_intl_REGU_sp;
		end
	end

	// REGU Interlock
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst)
		begin
			v_intl_REGU <= 0;
			c_intl_REGU <= 0;
		end

		else if (i_intl_clr)
		begin
			v_intl_REGU <= 0;
			c_intl_REGU <= 0;
		end

		else
		begin
			v_intl_REGU <= (i_intl_REGU_mode && v_intl_REGU_comp_result[0] && v_intl_REGU_comp_valid) ? 1 : v_intl_REGU;
			c_intl_REGU <= (c_intl_REGU_comp_result[0] && c_intl_REGU_comp_valid) ? 1 : c_intl_REGU;
		end
	end


	/***** Interlock State *****/

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst) 
			o_intl_state <= 0;
			
		else
		begin
			o_intl_state[0]		<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[0] ^ i_intl_ext[0]) : 0;
			o_intl_state[1]		<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[1] ^ i_intl_ext[1]) : 0;
			o_intl_state[2]		<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[2] ^ i_intl_ext[2]) : 0;
			o_intl_state[3]		<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[3] ^ i_intl_ext[3]) : 0;
			o_intl_state[4]		<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[4] ^ i_intl_ext[4]) : 0;
			o_intl_state[5]		<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[5] ^ i_intl_ext[5]) : 0;
			o_intl_state[6]		<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[6] ^ i_intl_ext[6]) : 0;
			o_intl_state[7]		<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[7] ^ i_intl_ext[7]) : 0;
			o_intl_state[8]		<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[8] ^ i_intl_ext[8]) : 0;
			o_intl_state[9]		<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[9] ^ i_intl_ext[9]) : 0;
			o_intl_state[10]	<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[10] ^ i_intl_ext[10]) : 0;
			o_intl_state[11]	<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[11] ^ i_intl_ext[11]) : 0;
			o_intl_state[12]	<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[12] ^ i_intl_ext[12]) : 0;
			o_intl_state[13]	<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[13] ^ i_intl_ext[13]) : 0;
			o_intl_state[14]	<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[14] ^ i_intl_ext[14]) : 0;
			o_intl_state[15]	<= ~(i_intl_clr)	? ~(i_intl_ext_bypass[15] ^ i_intl_ext[15]) : 0;

			o_intl_state[16]		<= ~(i_intl_clr) ? ~i_intl_OC : 0;
			o_intl_state[17]		<= ~(i_intl_clr) ? i_pwm_fault[0] : 0;
			o_intl_state[18]		<= ~(i_intl_clr) ? i_pwm_fault[1] : 0;
			o_intl_state[19]		<= ~(i_intl_clr) ? i_pwm_fault[2] : 0;
			o_intl_state[20]		<= ~(i_intl_clr) ? i_pwm_fault[3] : 0;
			// o_intl_state[21]		<= ~(i_intl_clr) ? ~i_intl_OV : 0;
			// o_intl_state[22]		<= ~(i_intl_clr) ? ~i_intl_OH : 0;
			o_intl_state[21]		<= 0;
			o_intl_state[22]		<= 0;

			o_intl_state[23]		<= intl_UV;
			o_intl_state[24]		<= intl_OV;
			o_intl_state[25]	<= intl_OC;

			o_intl_state[26]	<= c_intl_OSC;
			o_intl_state[27]	<= v_intl_OSC;
			o_intl_state[28]	<= c_intl_REGU;
			o_intl_state[29]	<= v_intl_REGU;

			o_intl_state[30]	<= ~i_sys_rst_flag;
    	end
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst)
			intl_OC <= 0;

		else if (i_intl_clr)
			intl_OC <= 0;
			
		else if ((OC_p_result[0] && OC_p_valid) || (OC_n_result[0] && OC_n_valid))
			intl_OC <= 1;

		else
			intl_OC <= intl_OC;
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			intl_OV <= 0;

		else if (i_intl_clr)
			intl_OV <= 0;
			
		else if ((OV_p_result[0] && OV_p_valid) || (OV_n_result[0] && OV_n_valid))
			intl_OV <= 1;

		else
			intl_OV <= intl_OV;
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst)
			intl_UV <= 0;

		else if (i_intl_clr)
			intl_UV <= 0;
			
		else if (UV_result[0] && UV_valid)
			intl_UV <= 1;

		else
			intl_UV <= intl_UV;
	end

	// Over Range
	floating_point_compare_greater_than
	u_floating_point_compare_OC_p
	(
		.aclk(i_clk),
        .s_axis_a_tdata(i_c_floating_data),
        .s_axis_a_tvalid(1),
        .s_axis_b_tdata(i_intl_OC_p),
        .s_axis_b_tvalid(~i_mps_polarity),
		.m_axis_result_tdata(OC_p_result),
        .m_axis_result_tvalid(OC_p_valid)
	);

	floating_point_compare_greater_than
	u_floating_point_compare_OC_n
	(
		.aclk(i_clk),
        .s_axis_a_tdata(i_intl_OC_n),
        .s_axis_a_tvalid(i_mps_polarity),
        .s_axis_b_tdata(i_c_floating_data),
        .s_axis_b_tvalid(1),
		.m_axis_result_tdata(OC_n_result),
        .m_axis_result_tvalid(OC_n_valid)
	);

	floating_point_compare_greater_than
	u_floating_point_compare_OV_p
	(
		.aclk(i_clk),
        .s_axis_a_tdata(i_v_floating_data),
        .s_axis_a_tvalid(1),
        .s_axis_b_tdata(i_intl_OV_p),
        .s_axis_b_tvalid(~i_mps_polarity),
        .m_axis_result_tdata(OV_p_result),
        .m_axis_result_tvalid(OV_p_valid)
	);

	floating_point_compare_greater_than
	u_floating_point_compare_OV_n
	(
		.aclk(i_clk),
        .s_axis_a_tdata(i_intl_OV_n),
        .s_axis_a_tvalid(i_mps_polarity),
        .s_axis_b_tdata(i_v_floating_data),
        .s_axis_b_tvalid(1),
		.m_axis_result_tdata(OV_n_result),
        .m_axis_result_tvalid(OV_n_valid)
	);

	floating_point_compare_greater_than
	u_floating_point_compare_UV
	(
		.aclk(i_clk),
        .s_axis_a_tdata(i_intl_UV),
        .s_axis_a_tvalid(1),
        .s_axis_b_tdata(i_dc_floating_data),
        .s_axis_b_tvalid(1),
		.m_axis_result_tdata(UV_result),
        .m_axis_result_tvalid(UV_valid)
	);

	// OSC
	floating_point_compare_greater_than
	u_floating_point_compare_greater_than_osc_min_c
	(
		.aclk(i_clk),
        .s_axis_a_tdata(c_intl_OSC_adc_min),
        .s_axis_a_tvalid(OSC_state == OSC_RUN),
        .s_axis_b_tdata(i_c_floating_data),
        .s_axis_b_tvalid(OSC_state == OSC_RUN),
		.m_axis_result_tdata(c_intl_OSC_comp_min_result),
        .m_axis_result_tvalid(c_intl_OSC_comp_min_valid)
	);

	floating_point_compare_greater_than
	u_floating_point_compare_greater_than_osc_max_c
	(
		.aclk(i_clk),
        .s_axis_a_tdata(i_c_floating_data),
        .s_axis_a_tvalid(OSC_state == OSC_RUN),
        .s_axis_b_tdata(c_intl_OSC_adc_max),
        .s_axis_b_tvalid(OSC_state == OSC_RUN),
		.m_axis_result_tdata(c_intl_OSC_comp_max_result),
        .m_axis_result_tvalid(c_intl_OSC_comp_max_valid)
	);

	floating_point_sub
	u_floating_point_sub_osc_c
	(
		.aclk(i_clk),
        .s_axis_a_tdata(c_intl_OSC_adc_max),
        .s_axis_a_tvalid(OSC_state == OSC_COUNT),
        .s_axis_b_tdata(c_intl_OSC_adc_min),
        .s_axis_b_tvalid(OSC_state == OSC_COUNT),
		.m_axis_result_tdata(c_intl_OSC_adc_data),
        .m_axis_result_tvalid(c_intl_OSC_adc_data_valid)
	);

	floating_point_compare_greater_and_equal
	u_floating_point_compare_greater_and_equal_osc_c
	(
		.aclk(i_clk),
        .s_axis_a_tdata(c_intl_OSC_adc_data),
        .s_axis_a_tvalid(c_intl_OSC_adc_data_valid),
        .s_axis_b_tdata(i_c_intl_OSC_adc_threshold),
        .s_axis_b_tvalid(1),
		.m_axis_result_tdata(c_intl_OSC_adc_result),
        .m_axis_result_tvalid(c_intl_OSC_adc_result_valid)
	);

	floating_point_compare_greater_than
	u_floating_point_compare_greater_than_osc_min_v
	(
		.aclk(i_clk),
        .s_axis_a_tdata(v_intl_OSC_adc_min),
        .s_axis_a_tvalid(OSC_state == OSC_RUN),
        .s_axis_b_tdata(i_v_floating_data),
        .s_axis_b_tvalid(OSC_state == OSC_RUN),
		.m_axis_result_tdata(v_intl_OSC_comp_min_result),
        .m_axis_result_tvalid(v_intl_OSC_comp_min_valid)
	);

	floating_point_compare_greater_than
	u_floating_point_compare_greater_than_osc_max_v
	(
		.aclk(i_clk),
        .s_axis_a_tdata(i_v_floating_data),
        .s_axis_a_tvalid(OSC_state == OSC_RUN),
        .s_axis_b_tdata(v_intl_OSC_adc_max),
        .s_axis_b_tvalid(OSC_state == OSC_RUN),
		.m_axis_result_tdata(v_intl_OSC_comp_max_result),
        .m_axis_result_tvalid(v_intl_OSC_comp_max_valid)
	);

	floating_point_sub
	u_floating_point_sub_osc_v
	(
		.aclk(i_clk),
        .s_axis_a_tdata(v_intl_OSC_adc_max),
        .s_axis_a_tvalid(OSC_state == OSC_COUNT),
        .s_axis_b_tdata(v_intl_OSC_adc_min),
        .s_axis_b_tvalid(OSC_state == OSC_COUNT),
		.m_axis_result_tdata(v_intl_OSC_adc_data),
        .m_axis_result_tvalid(v_intl_OSC_adc_data_valid)
	);

	floating_point_compare_greater_and_equal
	u_floating_point_compare_greater_and_equal_osc_v
	(
		.aclk(i_clk),
        .s_axis_a_tdata(v_intl_OSC_adc_data),
        .s_axis_a_tvalid(v_intl_OSC_adc_data_valid),
        .s_axis_b_tdata(i_v_floating_data),
        .s_axis_b_tvalid(1),
		.m_axis_result_tdata(v_intl_OSC_adc_result),
        .m_axis_result_tvalid(v_intl_OSC_adc_result_valid)
	);

	// Regultation
	floating_point_sub
	u_floating_point_sub_regu_c
	(
		.aclk(i_clk),
        .s_axis_a_tdata(i_c_intl_REGU_sp),
        .s_axis_a_tvalid(REGU_state == REGU_RUN),
        .s_axis_b_tdata(i_c_floating_data),
        .s_axis_b_tvalid(REGU_state == REGU_RUN),
		.m_axis_result_tdata(c_intl_REGU_data),
        .m_axis_result_tvalid(c_intl_REGU_data_valid)
	);

	floating_point_abs
	u_floating_point_abs_regu_c
	(
        .s_axis_a_tdata(c_intl_REGU_data),
        .s_axis_a_tvalid(c_intl_REGU_data_valid),
		.m_axis_result_tdata(c_intl_REGU_abs),
        .m_axis_result_tvalid(c_intl_REGU_abs_valid)
	);

	floating_point_compare_greater_than
	u_floating_point_compare_greater_than_regu_c
	(
		.aclk(i_clk),
        .s_axis_a_tdata(c_intl_REGU_abs),
        .s_axis_a_tvalid(c_intl_REGU_abs_valid),
        .s_axis_b_tdata(i_c_intl_REGU_diff),
        .s_axis_b_tvalid(1),
		.m_axis_result_tdata(c_intl_REGU_comp_result),
        .m_axis_result_tvalid(c_intl_REGU_comp_valid)
	);

	floating_point_sub
	u_floating_point_sub_regu_v
	(
	   .aclk(i_clk),
        .s_axis_a_tdata(i_v_intl_REGU_sp),
        .s_axis_a_tvalid(REGU_state == REGU_RUN),
        .s_axis_b_tdata(i_v_floating_data),
        .s_axis_b_tvalid(REGU_state == REGU_RUN),
		.m_axis_result_tdata(v_intl_REGU_data),
        .m_axis_result_tvalid(v_intl_REGU_data_valid)
	);

	floating_point_abs
	u_floating_point_abs_regu_v
	(
        .s_axis_a_tdata(v_intl_REGU_data),
        .s_axis_a_tvalid(v_intl_REGU_data_valid),
		.m_axis_result_tdata(v_intl_REGU_abs),
        .m_axis_result_tvalid(v_intl_REGU_abs_valid)
	);

	floating_point_compare_greater_than
	u_floating_point_compare_greater_than_regu_v
	(
		.aclk(i_clk),
        .s_axis_a_tdata(v_intl_REGU_abs),
        .s_axis_a_tvalid(v_intl_REGU_abs_valid),
        .s_axis_b_tdata(i_v_intl_REGU_diff),
        .s_axis_b_tvalid(1),
		.m_axis_result_tdata(v_intl_REGU_comp_result),
        .m_axis_result_tvalid(v_intl_REGU_comp_valid)
	);
							
	// // Ext Interlock
	// always @(posedge i_clk or negedge i_rst) 
	// begin
    // 	if (~i_rst) 
    //     	o_ext_intl_state <= 0;
			
	// 	else
	// 	begin
	// 		o_ext_intl_state[0]		<= i_intl_ext_bypass1;
	// 		o_ext_intl_state[1]		<= i_intl_ext_bypass2;
	// 		o_ext_intl_state[2]		<= i_intl_ext_bypass3;
	// 		o_ext_intl_state[3]		<= i_intl_ext_bypass4;

	// 		o_ext_intl_state[4]		<= ~((i_intl_ext_bypass1 == 0) && (i_intl_ext1 == 0));
	// 		o_ext_intl_state[5]		<= ~((i_intl_ext_bypass2 == 0) && (i_intl_ext2 == 0));
	// 		o_ext_intl_state[6]		<= ~((i_intl_ext_bypass3 == 0) && (i_intl_ext3 == 0));
	// 		o_ext_intl_state[7]		<= ~((i_intl_ext_bypass4 == 0) && (i_intl_ext4 == 0));

	// 		o_ext_intl_state[8]		<= i_intl_ext1;
	// 		o_ext_intl_state[9]		<= i_intl_ext2;
	// 		o_ext_intl_state[10]	<= i_intl_ext3;
	// 		o_ext_intl_state[11]	<= i_intl_ext4;
    // 	end
	// end

	assign o_osc_fsm_state = OSC_state;
	assign o_regu_fsm_state = REGU_state;

	assign c_intl_REGU_sp_flag = (c_intl_REGU_sp_buf != i_c_intl_REGU_sp);
	assign v_intl_REGU_sp_flag = (v_intl_REGU_sp_buf != i_v_intl_REGU_sp);

endmodule