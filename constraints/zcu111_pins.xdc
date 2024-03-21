# vp/vn need analog setting
set_property IOSTANDARD ANALOG [get_ports VP]
set_property IOSTANDARD ANALOG [get_ports VN]
# don't think clocks need iostandards? maybe?
set_property PACKAGE_PIN AF5 [get_ports ADC0_CLK_P]
set_property PACKAGE_PIN AF4 [get_ports ADC0_CLK_N]

set_property PACKAGE_PIN AD5 [get_ports ADC2_CLK_P]
set_property PACKAGE_PIN AD4 [get_ports ADC2_CLK_N]

set_property PACKAGE_PIN AB5 [get_ports ADC4_CLK_P]
set_property PACKAGE_PIN AB4 [get_ports ADC4_CLK_N]

set_property PACKAGE_PIN Y5 [get_ports ADC6_CLK_P]
set_property PACKAGE_PIN Y4 [get_ports ADC6_CLK_N]

set_property PACKAGE_PIN N5 [get_ports DAC4_CLK_P]
set_property PACKAGE_PIN N4 [get_ports DAC4_CLK_N]


# maybe these don't even need anything?
# It looks like you don't need these, because they come hardcoded
# with the RFSoC Data Converter hard IP. They are defined here for "fun"
set_property -dict { PACKAGE_PIN AP2 } [get_ports ADC0_VIN_P]
set_property -dict { PACKAGE_PIN AP1 } [get_ports ADC0_VIN_N]
set_property -dict { PACKAGE_PIN AM2 } [get_ports ADC1_VIN_P]
set_property -dict { PACKAGE_PIN AM1 } [get_ports ADC1_VIN_N]

set_property -dict { PACKAGE_PIN AK2 } [get_ports ADC2_VIN_P]
set_property -dict { PACKAGE_PIN AK1 } [get_ports ADC2_VIN_N]
set_property -dict { PACKAGE_PIN AH2 } [get_ports ADC3_VIN_P]
set_property -dict { PACKAGE_PIN AH1 } [get_ports ADC3_VIN_N]

set_property -dict { PACKAGE_PIN AF2 } [get_ports ADC4_VIN_P]
set_property -dict { PACKAGE_PIN AF1 } [get_ports ADC4_VIN_N]
set_property -dict { PACKAGE_PIN AD2 } [get_ports ADC5_VIN_P]
set_property -dict { PACKAGE_PIN AD1 } [get_ports ADC5_VIN_N]

set_property -dict { PACKAGE_PIN AB2 } [get_ports ADC6_VIN_P]
set_property -dict { PACKAGE_PIN AB1 } [get_ports ADC6_VIN_N]
set_property -dict { PACKAGE_PIN  Y2 } [get_ports ADC7_VIN_P]
set_property -dict { PACKAGE_PIN  Y1 } [get_ports ADC7_VIN_N]

#Other net   PACKAGE_PIN U1       - RFMC_DAC_00_N             Bank 228 - DAC_VOUT0_N_228
#Other net   PACKAGE_PIN U2       - RFMC_DAC_00_P             Bank 228 - DAC_VOUT0_P_228
#Other net   PACKAGE_PIN R1       - RFMC_DAC_01_N             Bank 228 - DAC_VOUT1_N_228
#Other net   PACKAGE_PIN R2       - RFMC_DAC_01_P             Bank 228 - DAC_VOUT1_P_228
#Other net   PACKAGE_PIN N1       - RFMC_DAC_02_N             Bank 228 - DAC_VOUT2_N_228
#Other net   PACKAGE_PIN N2       - RFMC_DAC_02_P             Bank 228 - DAC_VOUT2_P_228
#Other net   PACKAGE_PIN L1       - RFMC_DAC_03_N             Bank 228 - DAC_VOUT3_N_228
#Other net   PACKAGE_PIN L2       - RFMC_DAC_03_P             Bank 228 - DAC_VOUT3_P_228
#Other net   PACKAGE_PIN N4       - RF3_CLKO_A_C_N            Bank 229 - DAC_CLK_N_229
#Other net   PACKAGE_PIN N5       - RF3_CLKO_A_C_P            Bank 229 - DAC_CLK_P_229
#Other net   PACKAGE_PIN J1       - RFMC_DAC_04_N             Bank 229 - DAC_VOUT0_N_229
#Other net   PACKAGE_PIN J2       - RFMC_DAC_04_P             Bank 229 - DAC_VOUT0_P_229
#Other net   PACKAGE_PIN G1       - RFMC_DAC_05_N             Bank 229 - DAC_VOUT1_N_229
#Other net   PACKAGE_PIN G2       - RFMC_DAC_05_P             Bank 229 - DAC_VOUT1_P_229

set_property -dict { PACKAGE_PIN J2 } [get_ports DAC4_VOUT_P]
set_property -dict { PACKAGE_PIN J1 } [get_ports DAC4_VOUT_N]
set_property -dict { PACKAGE_PIN G2 } [get_ports DAC5_VOUT_P]
set_property -dict { PACKAGE_PIN G1 } [get_ports DAC5_VOUT_N]
set_property -dict { PACKAGE_PIN E2 } [get_ports DAC6_VOUT_P]
set_property -dict { PACKAGE_PIN E1 } [get_ports DAC6_VOUT_N]
set_property -dict { PACKAGE_PIN C2 } [get_ports DAC7_VOUT_P]
set_property -dict { PACKAGE_PIN C1 } [get_ports DAC7_VOUT_N]

# ZCU111 constraints
set_property -dict { IOSTANDARD LVDS DIFF_TERM TRUE PACKAGE_PIN AK17 } [get_ports SYSREF_FPGA_P]
set_property -dict { IOSTANDARD LVDS DIFF_TERM TRUE PACKAGE_PIN AK16 } [get_ports SYSREF_FPGA_N]

set_property -dict { IOSTANDARD LVDS DIFF_TERM TRUE PACKAGE_PIN AL16 } [get_ports FPGA_REFCLK_IN_P]
set_property -dict { IOSTANDARD LVDS DIFF_TERM TRUE PACKAGE_PIN AL15 } [get_ports FPGA_REFCLK_IN_N]

set_property -dict { IOSTANDARD LVCMOS18 PACKAGE_PIN AR13 } [get_ports {PL_USER_LED[0]}]
set_property -dict { IOSTANDARD LVCMOS18 PACKAGE_PIN AP13 } [get_ports {PL_USER_LED[1]}]