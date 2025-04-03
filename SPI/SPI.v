`timescale 1ns / 1ps
/*

SPI Master Module
개발 4팀 전경원 차장

23.05.02 :	최초 생성

24.05.02 :	Release v1_0
			- i_spi_start가 clear되어야 idle로 넘어감
			- i_cpol, i_cpha input으로 변경
			- o_valid 추가. ready는 i_spi_start와 중복되서 사용하지 않음
			- spi_data_load_flag 삭제

24.05.03 :	- i_cpol, i_cpha parameter로 변경

24.08.06 :  o_miso_data를 reg로 변경 (합성 시 Latch로 됨)

SPI Clock
 - SPI Clock은 반주기로써 아래의 수식을 참조
 - SPI Clock = i_clk * T_CYCLE * 2

DELAY
 - SPI 동작 전 후 Delay

idle -> delay_1 -> run -> delay_2 -> done -> idle
 - 평상시에는 idle 상태
 - parameter 상수 값 변경해서 사용 (Data, T_CYCLE, Delay 등)
 - i_mosi_data에 값을 쓴 후 i_spi_start를 H로 On.
 - o_miso_data는 o_spi_state가 idle일때 Data Read해야함.

i_cpol, CPHA만 1'b0로 쓰는 이유
 - parameter integer는 기본적으로 32비트 정수형태임
 - 1'b0 형태로 사용하면 합성 시 1비트만 사용함

*/

module SPI #
(
    parameter integer DATA_WIDTH = 16,             // SPI Data 크기
    parameter integer T_CYCLE = 3,                 // 주기 = i_clk * T_CYCLE * 2
    parameter integer DELAY = 2                   // delay_1, delay_2
)
(
    input i_rst,
    input i_clk,
    input i_spi_start,                              // spi 동작 신호. active H
    input [DATA_WIDTH - 1:0] i_mosi_data,           // MOSI Data
    input i_miso,                                     // 실제 i_miso 신호

    output reg [DATA_WIDTH - 1:0] o_miso_data,          // MISO Data
    output o_mosi,                                    // 실제 o_mosi 신호
    output o_cs,                                    // idle, done 빼고는 무조건 L임. active L
    output o_spi_clk,                                 // 실제 spi clock

	input i_cpol,
	input i_cpha,

	output o_valid,									// o_miso_data valid.
    output [2:0] o_spi_state						// Debug 용도
);

    parameter idle = 0;
    parameter delay_1 = 1;
    parameter run = 2;
    parameter delay_2 = 3;
    parameter done = 4;

    reg [2:0] state;
    reg [2:0] n_state;
    reg [$clog2(T_CYCLE) : 0] spi_clk_width_cnt;        // spi clock 시간 설정용 카운터. 해당 변수로 clock 주파수를 설정.

    reg [$clog2(DELAY) : 0] delay_1_cnt;
    reg [$clog2(DELAY) : 0] delay_2_cnt;
    reg [$clog2(DATA_WIDTH * 2) : 0] spi_data_cnt;      // spi data 카운터. spi_data_cnt = Bit * 2 (8 Bit면 총 16임)

    reg [DATA_WIDTH - 1 : 0] miso_reg;
    reg [DATA_WIDTH - 1 : 0] mosi_reg;

    // flag
    wire delay_1_flag;              
    wire delay_2_flag;
    reg spi_clk_flag;                   // spi clock의 H/L 용 flag
    wire spi_data_comp_flag;            // 모든 데이터 전송 완료

    wire spi_data_p_flag;               // spi clock edge flag
    wire spi_data_n_flag;

    // FSM init.
    always @(posedge i_clk or negedge i_rst) 
    begin
        if (~i_rst)
            state <= idle;

        else 
            state <= n_state;
    end

    // FSM
    always @(*)
    begin
        case (state)
            idle :
            begin
                if (i_spi_start)
                    n_state <= delay_1;

                else
                    n_state <= idle;
            end

            delay_1 :
            begin
                if (delay_1_flag)
                    n_state <= run;

                else
                    n_state <= delay_1;
            end

            run :
            begin
                if (spi_data_comp_flag)
                    n_state <= delay_2;

                else
                    n_state <= run;
            end

            delay_2 :
            begin
                if (delay_2_flag)
                    n_state <= done;

                else
                    n_state <= delay_2;
            end

            done :
			begin
				if (~i_spi_start)
                	n_state <= idle;
				
				else
					n_state <= done;
			end


            default :
                    n_state <= idle;
        endcase
    end

    // delay_1 카운터
    always @(posedge i_clk or negedge i_rst) 
    begin
        if (~i_rst)
            delay_1_cnt <= 0;

        else if ((state == delay_1) && (delay_1_cnt <= DELAY))
            delay_1_cnt <= delay_1_cnt + 1;

        else
            delay_1_cnt <= 0;
    end

    // delay_2 카운터
    always @(posedge i_clk or negedge i_rst) 
    begin
        if (~i_rst)
            delay_2_cnt <= 0;

        else if ((state == delay_2) && (delay_2_cnt <= DELAY))
            delay_2_cnt <= delay_2_cnt + 1;

        else
            delay_2_cnt <= 0;
    end

    // SPI Clock 주파수 카운터
    // T_CYCLE까지 증가하면 0으로 초기화하고 다시 동작함
    // run state와 spi_data_cnt가 설정한 DATA_WIDTH보다 낮을 경우 실행함
    always @(posedge i_clk or negedge i_rst) 
    begin
        if (~i_rst)
            spi_clk_width_cnt <= 4;

        else if ((state == run) && (spi_data_cnt <= (DATA_WIDTH * 2)))
        begin
            if (spi_clk_width_cnt >= T_CYCLE)
                spi_clk_width_cnt <= 0;

            else
                spi_clk_width_cnt <= spi_clk_width_cnt + 1;  
        end

        else
            spi_clk_width_cnt <= T_CYCLE + 1;
    end

    // SPI Data 카운터
    always @(posedge i_clk or negedge i_rst) 
    begin
        if (~i_rst)
            spi_data_cnt <= 0;

		else if (state == delay_1)
			spi_data_cnt <= 0;

        else if ((state == run) && (spi_data_cnt <= (DATA_WIDTH * 2)) && (spi_clk_width_cnt == T_CYCLE))
            spi_data_cnt <= spi_data_cnt + 1;

        else
            spi_data_cnt <= spi_data_cnt;
    end

    // spi clock H/L 변경
    // 초기값은 CPOL에 따름
    always @(posedge i_clk or negedge i_rst) 
    begin
        if (~i_rst)
            spi_clk_flag <= 1;

        else if ((state == run) && (spi_data_cnt <= (DATA_WIDTH * 2)))
        begin
            if (spi_clk_width_cnt == T_CYCLE)
            begin
                if (spi_data_cnt == (DATA_WIDTH * 2))
                    spi_clk_flag <= spi_clk_flag;
                
                else
                    spi_clk_flag <= ~spi_clk_flag;
            end

            else
                spi_clk_flag <= spi_clk_flag;
        end

        else
            spi_clk_flag <= i_cpol;
    end

    // i_miso
    always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            miso_reg <= 0;

        else
        begin
            if (spi_data_p_flag)
            begin
                if (i_cpol^i_cpha)
                    miso_reg <= miso_reg;

                else
                    miso_reg <= {miso_reg[DATA_WIDTH - 2:0], i_miso};
            end
            
            else if (spi_data_n_flag)
            begin
                if (i_cpol^i_cpha)
                    miso_reg <= {miso_reg[DATA_WIDTH - 2:0], i_miso};

                else
                    miso_reg <= miso_reg;
            end

            else
                miso_reg <= miso_reg;
        end
    end

    // o_mosi
    always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            mosi_reg <= 0;

        else
        begin
            if (spi_data_p_flag)
            begin
                if (i_cpol^i_cpha)
                begin
                    if (i_cpha)
                    begin
                        if (spi_data_cnt == 1)			// CPHA에 따라서 타이밍이 달라짐.
                            mosi_reg <= mosi_reg;

                        else
                            mosi_reg <= {mosi_reg[DATA_WIDTH - 2:0], 1'b0};
                    end

                    else
                    begin
                        if (spi_data_cnt == 0)
                            mosi_reg <= mosi_reg;

                        else
                            mosi_reg <= {mosi_reg[DATA_WIDTH - 2:0], 1'b0};
                    end
                end

                else
                    mosi_reg <= mosi_reg;
            end
            
            else if (spi_data_n_flag)
            begin
                if (i_cpol^i_cpha)
                    mosi_reg <= mosi_reg;

                else
                begin
                    if (i_cpha)
                    begin
                        if (spi_data_cnt == 1)
                            mosi_reg <= mosi_reg;

                        else
                            mosi_reg <= {mosi_reg[DATA_WIDTH - 2:0], 1'b0};
                    end

                    else
                    begin
                        if (spi_data_cnt == 0)
                            mosi_reg <= mosi_reg;

                        else
                            mosi_reg <= {mosi_reg[DATA_WIDTH - 2:0], 1'b0};
                    end
                end  
            end

            else if (state == idle)
                mosi_reg <= i_mosi_data;

            else
                mosi_reg <= mosi_reg;
        end
    end

    // o_mosi Data 
    always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            o_miso_data <= 0;

        else if (spi_data_comp_flag)
            o_miso_data <= miso_reg;

        else
            o_miso_data <= o_miso_data;
    end

    assign o_spi_clk = spi_clk_flag;
    assign spi_data_p_flag = ((spi_clk_width_cnt == 0) && (spi_clk_flag) && (spi_data_cnt <= (DATA_WIDTH * 2))) ? 1 : 0;	// 마지막 조건은 data 마지막에 한번 더 동작해서 조건을 걸었음
    assign spi_data_n_flag = ((spi_clk_width_cnt == 0) && (~spi_clk_flag) && (spi_data_cnt <= (DATA_WIDTH * 2))) ? 1 : 0;
    assign delay_1_flag = (delay_1_cnt == DELAY) ? 1 : 0;
    assign delay_2_flag = (delay_2_cnt == DELAY) ? 1 : 0;
    assign spi_data_comp_flag = (spi_data_cnt == ((DATA_WIDTH * 2) + 1)) ? 1 : 0;	// 맨 마지막 데이터를 처리한 후 동작함
    assign o_cs = ((state == idle) || (state == done)) ? 1 : 0;
    // assign o_miso_data = (spi_data_comp_flag) ? miso_reg : o_miso_data;			// i_miso data는 전송이 완료된 후 write
    assign o_mosi = ( ~o_cs ) ? mosi_reg[DATA_WIDTH - 1] : 1'bz;
	assign o_valid = (state == done);
    assign o_spi_state = state;

endmodule
        
