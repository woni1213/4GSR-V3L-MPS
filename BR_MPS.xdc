# Kria_K26_SOM_Rev1.xdc 파일 내에서 Package Pin을 찾아야함.
# 회로도 내 CN1001이 som240_1, CN1002가 som240_2
# 그리고 포트의 라우팅 이름이 해당 보드의 핀 이름임
# 예시) 회로도 내 CN1001의 라우팅 이름이 A3라면  Kria_K26_SOM_Rev1.xdc 파일의 get_ports는 "som240_1_a3"이다.

## Clock Constraints
create_clock -period 6.400 -name GT_DIFF_REFCLK_0_clk_p -waveform {0.000 3.200} [get_ports {GT_DIFF_REFCLK_0_clk_p}]
set_property -dict { PACKAGE_PIN C3		IOSTANDARD LVCMOS18 } [get_ports sys_clk];			# HPARCK

### LAN Constraints (See Notion - Zynq - Error and Critical Warning Page)
set_property IODELAY_GROUP tri_mode_ethernet_mac_iodelay_grp1 [get_cells -hier -filter {NAME =~ design_1_i/Ethernet/axi_ethernet_1/* && IODELAY_GROUP != "" }] 
set_property IODELAY_GROUP tri_mode_ethernet_mac_iodelay_grp2 [get_cells -hier -filter {NAME =~ design_1_i/Ethernet/axi_ethernet_2/* && IODELAY_GROUP != "" }]

## SFP 1
set_property PACKAGE_PIN R4 [get_ports GT_SERIAL_TX_0_txp];										# SFTDPA
set_property PACKAGE_PIN R3 [get_ports GT_SERIAL_TX_0_txn];										# SFTDNA
set_property PACKAGE_PIN T2 [get_ports GT_SERIAL_RX_0_rxp];										# SFRDPA
set_property PACKAGE_PIN T1 [get_ports GT_SERIAL_RX_0_rxn];										# SFRDNA

set_property PACKAGE_PIN Y5 [get_ports GT_DIFF_REFCLK_0_clk_n];									# GTHRCK0N
set_property PACKAGE_PIN Y6 [get_ports GT_DIFF_REFCLK_0_clk_p];									# GTHRCK0P

set_property -dict {PACKAGE_PIN Y10 IOSTANDARD LVCMOS33} [get_ports o_sfp_0_tx_en];				# SFTDISA

# Reset
# Interlock Reset
set_property -dict { PACKAGE_PIN F8		IOSTANDARD LVCMOS18 } [get_ports i_sys_rst_flag];	# MONXRST~

# Main ADC (AD4630-24BBCZ)
set_property -dict { PACKAGE_PIN AG8   IOSTANDARD LVCMOS18 } [get_ports o_m_adc_ext_rst];	# MRMADC~
set_property -dict { PACKAGE_PIN AE9   IOSTANDARD LVCMOS18 } [get_ports o_m_adc_cnv];		# STMADC
set_property -dict { PACKAGE_PIN AF7   IOSTANDARD LVCMOS18 } [get_ports i_m_adc_busy];		# BYMADC
set_property -dict { PACKAGE_PIN AE8   IOSTANDARD LVCMOS18 } [get_ports o_m_adc_cs];		# CSMADC~
set_property -dict { PACKAGE_PIN AB8   IOSTANDARD LVCMOS18 } [get_ports o_m_adc_spi_clk];	# SKMADC
set_property -dict { PACKAGE_PIN AC8   IOSTANDARD LVCMOS18 } [get_ports o_m_adc_mosi];		# SCMADC
set_property -dict { PACKAGE_PIN AH8   IOSTANDARD LVCMOS18 } [get_ports i_m_adc_miso_0];	# SDADA0
set_property -dict { PACKAGE_PIN AH7   IOSTANDARD LVCMOS18 } [get_ports i_m_adc_miso_1];	# SDADA1
set_property -dict { PACKAGE_PIN AG6   IOSTANDARD LVCMOS18 } [get_ports i_m_adc_miso_2];	# SDADA2
set_property -dict { PACKAGE_PIN AG5   IOSTANDARD LVCMOS18 } [get_ports i_m_adc_miso_3];	# SDADA3
set_property -dict { PACKAGE_PIN AC4   IOSTANDARD LVCMOS18 } [get_ports i_m_adc_miso_4];	# SDADB0
set_property -dict { PACKAGE_PIN AC3   IOSTANDARD LVCMOS18 } [get_ports i_m_adc_miso_5];	# SDADB1
set_property -dict { PACKAGE_PIN AB4   IOSTANDARD LVCMOS18 } [get_ports i_m_adc_miso_6];	# SDADB2
set_property -dict { PACKAGE_PIN AB3   IOSTANDARD LVCMOS18 } [get_ports i_m_adc_miso_7];	# SDADB3

# Sub ADC
set_property -dict { PACKAGE_PIN AC7   IOSTANDARD LVCMOS18 } [get_ports o_s_adc_mosi];		# SCSADC
set_property -dict { PACKAGE_PIN AF6   IOSTANDARD LVCMOS18 } [get_ports i_s_adc_busy];		# BYSADC
set_property -dict { PACKAGE_PIN AE7   IOSTANDARD LVCMOS18 } [get_ports o_s_adc_cs];		# CSSADC~
set_property -dict { PACKAGE_PIN AB7   IOSTANDARD LVCMOS18 } [get_ports o_s_adc_spi_clk];	# SKSADC
set_property -dict { PACKAGE_PIN AF8   IOSTANDARD LVCMOS18 } [get_ports o_s_adc_rst];		# MRSADC
set_property -dict { PACKAGE_PIN AD7   IOSTANDARD LVCMOS18 } [get_ports o_s_adc_cnv];		# STSADC
set_property -dict { PACKAGE_PIN AB2   IOSTANDARD LVCMOS18 } [get_ports i_s_adc_miso_0];	# SDSAD1
set_property -dict { PACKAGE_PIN AC2   IOSTANDARD LVCMOS18 } [get_ports i_s_adc_miso_1];	# SDSAD2
set_property -dict { PACKAGE_PIN AG4   IOSTANDARD LVCMOS18 } [get_ports i_s_adc_miso_2];	# SDSAD3
set_property -dict { PACKAGE_PIN AH4   IOSTANDARD LVCMOS18 } [get_ports i_s_adc_miso_3];	# SDSAD4
set_property -dict { PACKAGE_PIN AG3   IOSTANDARD LVCMOS18 } [get_ports i_s_adc_miso_4];	# SDSAD5
set_property -dict { PACKAGE_PIN AH3   IOSTANDARD LVCMOS18 } [get_ports i_s_adc_miso_5];	# SDSAD6
set_property -dict { PACKAGE_PIN AE3   IOSTANDARD LVCMOS18 } [get_ports i_s_adc_miso_6];	# SDSAD7
set_property -dict { PACKAGE_PIN AF3   IOSTANDARD LVCMOS18 } [get_ports i_s_adc_miso_7];	# SDSAD8

# DSP Control
set_property -dict { PACKAGE_PIN Y9		IOSTANDARD LVCMOS33 } [get_ports i_dsp_ce];			# CESOM~
set_property -dict { PACKAGE_PIN AB10	IOSTANDARD LVCMOS33 } [get_ports i_dsp_we];			# XWE0~
#set_property -dict { PACKAGE_PIN AA8	IOSTANDARD LVCMOS33 } [get_ports i_dsp_rd];			# XRD~

# DSP Address
set_property -dict { PACKAGE_PIN AB15	IOSTANDARD LVCMOS33 } [get_ports i_dsp_addr[0]];	# XA [0]
set_property -dict { PACKAGE_PIN AB14	IOSTANDARD LVCMOS33 } [get_ports i_dsp_addr[1]];	# XA [1]
set_property -dict { PACKAGE_PIN Y14	IOSTANDARD LVCMOS33 } [get_ports i_dsp_addr[2]];	# XA [2]
set_property -dict { PACKAGE_PIN Y13	IOSTANDARD LVCMOS33 } [get_ports i_dsp_addr[3]];	# XA [3]
set_property -dict { PACKAGE_PIN W12	IOSTANDARD LVCMOS33 } [get_ports i_dsp_addr[4]];	# XA [4]
set_property -dict { PACKAGE_PIN W11	IOSTANDARD LVCMOS33 } [get_ports i_dsp_addr[5]];	# XA [5]
set_property -dict { PACKAGE_PIN Y12	IOSTANDARD LVCMOS33 } [get_ports i_dsp_addr[6]];	# XA [6]
set_property -dict { PACKAGE_PIN AA12	IOSTANDARD LVCMOS33 } [get_ports i_dsp_addr[7]];	# XA [7]
set_property -dict { PACKAGE_PIN AA11	IOSTANDARD LVCMOS33 } [get_ports i_dsp_addr[8]];	# XA [8]

# DSP Data
set_property -dict { PACKAGE_PIN AD15	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[0]];	# XD[0]
set_property -dict { PACKAGE_PIN AD14	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[1]];	# XD[1]
set_property -dict { PACKAGE_PIN AE15	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[2]];	# XD[2]
set_property -dict { PACKAGE_PIN AE14	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[3]];	# XD[3]
set_property -dict { PACKAGE_PIN AG14	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[4]];	# XD[4]
set_property -dict { PACKAGE_PIN AH14	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[5]];	# XD[5]
set_property -dict { PACKAGE_PIN AG13	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[6]];	# XD[6]
set_property -dict { PACKAGE_PIN AH13	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[7]];	# XD[7]
set_property -dict { PACKAGE_PIN AC14	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[8]];	# XD[8]
set_property -dict { PACKAGE_PIN AC13	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[9]];	# XD[9]
set_property -dict { PACKAGE_PIN AE13	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[10]];	# XD[10]
set_property -dict { PACKAGE_PIN AF13	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[11]];	# XD[11]
set_property -dict { PACKAGE_PIN AA13	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[12]];	# XD[12]
set_property -dict { PACKAGE_PIN AB13	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[13]];	# XD[13]
set_property -dict { PACKAGE_PIN W14	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[14]];	# XD[14]
set_property -dict { PACKAGE_PIN W13	IOSTANDARD LVCMOS33 } [get_ports io_dsp_data[15]];	# XD[15]

# DSP Handler
# set_property -dict { PACKAGE_PIN AE2	IOSTANDARD LVCMOS18 } [get_ports i_wf_en];			# MXTMP1  DSP : GPIO34
# set_property -dict { PACKAGE_PIN AF2	IOSTANDARD LVCMOS18 } [get_ports i_dsp_sfp_en];		# MXTMP2  DSP : GPIO35  Not Used
set_property -dict { PACKAGE_PIN AH2	IOSTANDARD LVCMOS18 } [get_ports i_r_valid];		# MXTMP3  DSP : GPIO26
set_property -dict { PACKAGE_PIN AH1	IOSTANDARD LVCMOS18 } [get_ports i_w_ready];		# MXTMP4  DSP : GPIO27

 set_property -dict { PACKAGE_PIN AC9	IOSTANDARD LVCMOS18 } [get_ports o_pwm_on];         # MMTXP1  DSP : GPIO22
# set_property -dict { PACKAGE_PIN AD9	IOSTANDARD LVCMOS18 } [get_ports o_r_ready];		# MMTXP2  DSP : GPIO23  Not Used
set_property -dict { PACKAGE_PIN AD5	IOSTANDARD LVCMOS18 } [get_ports o_w_valid];		# MMTXP3  DSP : GPIO30
# set_property -dict { PACKAGE_PIN AD4	IOSTANDARD LVCMOS18 } [get_ports ];					# MMTXP3  DSP : GPIO30

set_property -dict { PACKAGE_PIN AD10	IOSTANDARD LVCMOS33 } [get_ports o_nMENPWM];		# MENPWM

# Extenal Interlock
set_property -dict { PACKAGE_PIN M6		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[0]];	# ILDI0xM
set_property -dict { PACKAGE_PIN L5		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[1]];	
set_property -dict { PACKAGE_PIN N7		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[2]];	
set_property -dict { PACKAGE_PIN N6		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[3]];	
set_property -dict { PACKAGE_PIN P7		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[4]];	
set_property -dict { PACKAGE_PIN P6		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[5]];	
set_property -dict { PACKAGE_PIN N9		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[6]];	
set_property -dict { PACKAGE_PIN N8		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[7]];	
set_property -dict { PACKAGE_PIN J5		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[8]];	
set_property -dict { PACKAGE_PIN J4		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[9]];	
set_property -dict { PACKAGE_PIN J7		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[10]];	
set_property -dict { PACKAGE_PIN H7		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[11]];	
set_property -dict { PACKAGE_PIN K8		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[12]];	
set_property -dict { PACKAGE_PIN K7		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[13]];	
set_property -dict { PACKAGE_PIN K9		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[14]];	
set_property -dict { PACKAGE_PIN J9		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext[15]];

set_property -dict { PACKAGE_PIN E5		IOSTANDARD LVCMOS18 } [get_ports i_intl_OC];		# MOCDETF~
set_property -dict { PACKAGE_PIN J11	IOSTANDARD LVCMOS33 } [get_ports i_pwm_fault[0]];	# FLTT1P
set_property -dict { PACKAGE_PIN J10	IOSTANDARD LVCMOS33 } [get_ports i_pwm_fault[1]];	# FLTB1P
set_property -dict { PACKAGE_PIN K13	IOSTANDARD LVCMOS33 } [get_ports i_pwm_fault[2]];	# FLTT2P
set_property -dict { PACKAGE_PIN K12	IOSTANDARD LVCMOS33 } [get_ports i_pwm_fault[3]];	# FLTB2P

set_property -dict { PACKAGE_PIN F7		IOSTANDARD LVCMOS18 } [get_ports o_intl_OC_rst];	# MCLOCF~

# System Control
# set_property -dict { PACKAGE_PIN AF10	IOSTANDARD LVCMOS33 } [get_ports ];		# MEXTRG~
set_property -dict { PACKAGE_PIN D11	IOSTANDARD LVCMOS33 } [get_ports o_en_dsp_boot];	# ENSOMBT~
set_property -dict { PACKAGE_PIN B10	IOSTANDARD LVCMOS33 } [get_ports o_sys_rst];		# ENSOMMR
set_property -dict { PACKAGE_PIN G8		IOSTANDARD LVCMOS18 } [get_ports o_eeprom_rst];		# WEMEEP~
set_property -dict { PACKAGE_PIN E12	IOSTANDARD LVCMOS33 } [get_ports o_ext_do_buf_en];	# MENILO~

set_property -dict { PACKAGE_PIN R7		IOSTANDARD LVCMOS18 } [get_ports o_ext_do[0]];		# ILDO0xM
set_property -dict { PACKAGE_PIN T7		IOSTANDARD LVCMOS18 } [get_ports o_ext_do[1]];
set_property -dict { PACKAGE_PIN L7		IOSTANDARD LVCMOS18 } [get_ports o_ext_do[2]];
set_property -dict { PACKAGE_PIN L6		IOSTANDARD LVCMOS18 } [get_ports o_ext_do[3]];
set_property -dict { PACKAGE_PIN H9		IOSTANDARD LVCMOS18 } [get_ports o_ext_do[4]];
set_property -dict { PACKAGE_PIN H8		IOSTANDARD LVCMOS18 } [get_ports o_ext_do[5]];
set_property -dict { PACKAGE_PIN AD2	IOSTANDARD LVCMOS18 } [get_ports o_ext_do[6]];
set_property -dict { PACKAGE_PIN AD1	IOSTANDARD LVCMOS18 } [get_ports o_ext_do[7]];

### LAN 1	
set_property -dict { PACKAGE_PIN G3		IOSTANDARD LVCMOS18 } [get_ports lan_1_mdio_mdc];		# EMDCA
set_property -dict { PACKAGE_PIN F3		IOSTANDARD LVCMOS18 } [get_ports lan_1_mdio_mdio_io];	# EMDIOA
set_property -dict { PACKAGE_PIN B1		IOSTANDARD LVCMOS18 } [get_ports lan_1_phy_reset];		# ENMREA~
set_property -dict { PACKAGE_PIN D4		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_rxc];		# ERXCKA
set_property -dict { PACKAGE_PIN A4		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_rx_ctl];	# ERXCTLA
set_property -dict { PACKAGE_PIN A1		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_rd[0]];	# ERXD0A
set_property -dict { PACKAGE_PIN B3		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_rd[1]];	# ERXD1A
set_property -dict { PACKAGE_PIN A3		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_rd[2]];	# ERXD2A
set_property -dict { PACKAGE_PIN B4		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_rd[3]];	# ERXD3A
set_property -dict { PACKAGE_PIN A2		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_txc];		# EGTCKA
set_property -dict { PACKAGE_PIN F1		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_tx_ctl];	# ETXCTLA
set_property -dict { PACKAGE_PIN E1		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_td[0]];	# ETXD0A
set_property -dict { PACKAGE_PIN D1		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_td[1]];	# ETXD1A
set_property -dict { PACKAGE_PIN F2		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_td[2]];	# ETXD2A
set_property -dict { PACKAGE_PIN E2		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_td[3]];	# ETXD3A

### LAN 2
set_property -dict { PACKAGE_PIN R8		IOSTANDARD LVCMOS18 } [get_ports lan_2_mdio_mdc];		# EMDCB
set_property -dict { PACKAGE_PIN T8		IOSTANDARD LVCMOS18 } [get_ports lan_2_mdio_mdio_io];	# EMDIOB
set_property -dict { PACKAGE_PIN K1		IOSTANDARD LVCMOS18 } [get_ports lan_2_phy_reset];		# ENMREB~
set_property -dict { PACKAGE_PIN K4		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_rxc];		# ERXCKB
set_property -dict { PACKAGE_PIN H3		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_rx_ctl];	# ERXCTLB
set_property -dict { PACKAGE_PIN H1		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_rd[0]];	# ERXD0B
set_property -dict { PACKAGE_PIN K2		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_rd[1]];	# ERXD1B
set_property -dict { PACKAGE_PIN J2		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_rd[2]];	# ERXD2B
set_property -dict { PACKAGE_PIN H4		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_rd[3]];	# ERXD3B
set_property -dict { PACKAGE_PIN J1		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_txc];		# EGTCKB
set_property -dict { PACKAGE_PIN Y8		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_tx_ctl];	# ETXCTLB
set_property -dict { PACKAGE_PIN U9		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_td[0]];	# ETXD0B
set_property -dict { PACKAGE_PIN V9		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_td[1]];	# ETXD1B
set_property -dict { PACKAGE_PIN U8		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_td[2]];	# ETXD2B
set_property -dict { PACKAGE_PIN V8		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_td[3]];	# ETXD3B

# FRONT
set_property -dict { PACKAGE_PIN AE12   IOSTANDARD LVCMOS33 } [get_ports front_sw_spi_clk];		# SKSPI
set_property -dict { PACKAGE_PIN AF12   IOSTANDARD LVCMOS33 } [get_ports o_lcd_cs];				# nCSODM  
set_property -dict { PACKAGE_PIN AG10   IOSTANDARD LVCMOS33 } [get_ports o_sw_cs];				# nCSIOE
set_property -dict { PACKAGE_PIN AH10   IOSTANDARD LVCMOS33 } [get_ports front_sw_spi_mosi];	# SCSPI
set_property -dict { PACKAGE_PIN AF11   IOSTANDARD LVCMOS33 } [get_ports front_sw_spi_miso];	# SDSPI
set_property -dict { PACKAGE_PIN AG11   IOSTANDARD LVCMOS33 } [get_ports i_sw_intr];			# nINTKY
set_property -dict { PACKAGE_PIN AH12   IOSTANDARD LVCMOS33 } [get_ports i_ro_enc_state_a];		# ENCKYA
set_property -dict { PACKAGE_PIN AH11   IOSTANDARD LVCMOS33 } [get_ports i_ro_enc_state_b];		# ENCKYB

# Uart
set_property -dict { PACKAGE_PIN A12	IOSTANDARD LVCMOS33 } [get_ports uart_rxd];		# 
set_property -dict { PACKAGE_PIN B11	IOSTANDARD LVCMOS33 } [get_ports uart_txd];		# 