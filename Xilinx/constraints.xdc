# DAPHNE constraints
# jamieson@fnal.gov
# 24 Feb 2022

# #############################################################################
# Timing constraints...
# Note: Xilinx IP core constraints will be applied automatically
# when the *.xcix file is added to the project

# Net sysclk is 100MHz clock, comes in on differential I/O
# Net oeiclk is 125MHz and is generated from the GTX transceiver, which it gets from the reference clock

create_clock -name sysclk -period 10.000  [get_ports sysclk_p]
create_clock -name oeiclk -period 8.000   [get_ports gtrefclk_p]

# clocks from the AFE: DCLK is 437.5MHz (7x62.5MHz) and FCLK is 62.5MHz

create_clock -name afe0_dclk -period 2.28 [get_ports {afe_dclk_p[0]}]
create_clock -name afe1_dclk -period 2.28 [get_ports {afe_dclk_p[1]}]
create_clock -name afe2_dclk -period 2.28 [get_ports {afe_dclk_p[2]}]
create_clock -name afe3_dclk -period 2.28 [get_ports {afe_dclk_p[3]}]
create_clock -name afe4_dclk -period 2.28 [get_ports {afe_dclk_p[4]}]

create_clock -name afe0_fclk -period 16.000 [get_ports {afe_fclk_p[0]}]
create_clock -name afe1_fclk -period 16.000 [get_ports {afe_fclk_p[1]}]
create_clock -name afe2_fclk -period 16.000 [get_ports {afe_fclk_p[2]}]
create_clock -name afe3_fclk -period 16.000 [get_ports {afe_fclk_p[3]}]
create_clock -name afe4_fclk -period 16.000 [get_ports {afe_fclk_p[4]}]

set_clock_groups -name async_groups -asynchronous \
-group [get_clocks -include_generated_clocks sysclk] \
-group [get_clocks -include_generated_clocks oeiclk] \
-group [get_clocks -include_generated_clocks afe0_dclk] \
-group [get_clocks -include_generated_clocks afe1_dclk] \
-group [get_clocks -include_generated_clocks afe2_dclk] \
-group [get_clocks -include_generated_clocks afe3_dclk] \
-group [get_clocks -include_generated_clocks afe4_dclk] \
-group [get_clocks -include_generated_clocks afe0_fclk] \
-group [get_clocks -include_generated_clocks afe1_fclk] \
-group [get_clocks -include_generated_clocks afe2_fclk] \
-group [get_clocks -include_generated_clocks afe3_fclk] \
-group [get_clocks -include_generated_clocks afe4_fclk]

# tell vivado about places where signals cross clock domains so timing can be ignored here...
# comment out and worry about this later...

# set_false_path -from {bc_count_reg_reg[*]/C} -to {eth_int_inst/data_manager_blk/TX_CTRL_FIFO/FIFO_SYNC_MACRO_inst/bl.fifo_36_inst_bl_1.fifo_36_bl_1/DI[*]}
# set_false_path -from {eth_int_inst/*/*/tx_en_reg*/C} -to {eth_act_led_reg_reg[0]/D}
# set_false_path -from {*/*/*/gig_ethernet_pcs_pma_0_core/gpcs_pma_inst/RECEIVER/RX_DV_reg/C} -to {eth_act_led_reg_reg[0]/D}

# #############################################################################
# Pin LOCation and IOSTANDARD Constraints...

# Ethernet MGT is "TX1" is QUAD216-1 -> X0Y5 in XC7A200T FBG676
# refclk is 125MHz on MGTREFCLK0_216 pins F11/E11.  No inversion on DAPHNE board.

set_property LOC GTPE2_CHANNEL_X0Y5 [get_cells */*/*/transceiver_inst/gtwizard_inst/*/gtwizard_i/gt0_GTWIZARD_i/gtpe2_i]
set_property LOC F11 [get_ports gtrefclk_p]

# SFP module LOSS OF SIGNAL indicator IO bank VCCO=3.3V

set_property PACKAGE_PIN L8 [get_ports sfp_los]
set_property IOSTANDARD LVTTL [get_ports {sfp_los}]

# SFP module TX DISABLE control, IO bank 35, VCCO=3.3V

set_property PACKAGE_PIN K8 [get_ports sfp_tx_dis]
set_property IOSTANDARD LVTTL [get_ports {sfp_tx_dis}]

# reset pin is from uC, I/O bank 35, VCCO=3.3V note ACTIVE LOW on DAPHNE

set_property PACKAGE_PIN J8 [get_ports reset_n]
set_property IOSTANDARD LVTTL [get_ports {reset_n}]

# external trigger is from rear panel SMB connector (on schematic net is GPI)
# I/O bank 35, VCCO=3.3V 

set_property PACKAGE_PIN D5 [get_ports trig_ext]
set_property IOSTANDARD LVTTL [get_ports {trig_ext}]

# SYSCLK is LVDS 100MHz comes in on bank 33, VCCO=2.5V.
# Use internal LVDS 100 ohm termination. On schematic this is FPGA_MCLK1.

set_property PACKAGE_PIN  AA4 [get_ports sysclk_p]
set_property PACKAGE_PIN  AB4 [get_ports sysclk_n]
set_property IOSTANDARD LVDS_25 [get_ports sysclk_p]
set_property IOSTANDARD LVDS_25 [get_ports sysclk_n]
set_property DIFF_TERM TRUE [get_ports sysclk_p]
set_property DIFF_TERM TRUE [get_ports sysclk_n]

# All 6 user LEDS are in bank 35, VCCO=3.3V, all LEDs Active High

# Assign LED7 to debug header pin 1
# set_property PACKAGE_PIN C3 [get_ports {led[7]}]

# Assign LED6 to debug header pin 2
# set_property PACKAGE_PIN F3 [get_ports {led[6]}]

# LED[5..0] map to user StatLED[5..0] on DAPHNE
set_property PACKAGE_PIN D3 [get_ports {led[5]}]
set_property PACKAGE_PIN A4 [get_ports {led[4]}]
set_property PACKAGE_PIN B4 [get_ports {led[3]}]
set_property PACKAGE_PIN A5 [get_ports {led[2]}]
set_property PACKAGE_PIN B5 [get_ports {led[1]}]
set_property PACKAGE_PIN C4 [get_ports {led[0]}]

# set_property IOSTANDARD LVTTL [get_ports {led[7]}]
# set_property IOSTANDARD LVTTL [get_ports {led[6]}]
set_property IOSTANDARD LVTTL [get_ports {led[5]}]
set_property IOSTANDARD LVTTL [get_ports {led[4]}]
set_property IOSTANDARD LVTTL [get_ports {led[3]}]
set_property IOSTANDARD LVTTL [get_ports {led[2]}]
set_property IOSTANDARD LVTTL [get_ports {led[1]}]
set_property IOSTANDARD LVTTL [get_ports {led[0]}]

# LVDS output clock to AFEs (on schematic 62.5MHz_FPGA_)

set_property PACKAGE_PIN  AF5   [get_ports afe_clk_p]
set_property PACKAGE_PIN  AF4   [get_ports afe_clk_n]
set_property IOSTANDARD LVDS_25 [get_ports afe_clk_p]
set_property IOSTANDARD LVDS_25 [get_ports afe_clk_n]

# LVDS inputs from AFE 0 (Bank 12)

set_property PACKAGE_PIN  Y15  [get_ports {afe_data_p[0][0]}]
set_property PACKAGE_PIN  AA15 [get_ports {afe_data_n[0][0]}]
set_property PACKAGE_PIN  AB16 [get_ports {afe_data_p[0][1]}]
set_property PACKAGE_PIN  AC16 [get_ports {afe_data_n[0][1]}]
set_property PACKAGE_PIN  AA17 [get_ports {afe_data_p[0][2]}]
set_property PACKAGE_PIN  AB17 [get_ports {afe_data_n[0][2]}]
set_property PACKAGE_PIN  AE18 [get_ports {afe_data_p[0][3]}]
set_property PACKAGE_PIN  AF18 [get_ports {afe_data_n[0][3]}]
set_property PACKAGE_PIN  AC18 [get_ports {afe_data_p[0][4]}]
set_property PACKAGE_PIN  AD18 [get_ports {afe_data_n[0][4]}]
set_property PACKAGE_PIN  AF19 [get_ports {afe_data_p[0][5]}]
set_property PACKAGE_PIN  AF20 [get_ports {afe_data_n[0][5]}]
set_property PACKAGE_PIN  AD20 [get_ports {afe_data_p[0][6]}]
set_property PACKAGE_PIN  AE20 [get_ports {afe_data_n[0][6]}]
set_property PACKAGE_PIN  AD21 [get_ports {afe_data_p[0][7]}]
set_property PACKAGE_PIN  AE21 [get_ports {afe_data_n[0][7]}]
set_property PACKAGE_PIN  AA20 [get_ports {afe_fclk_p[0]}]
set_property PACKAGE_PIN  AB20 [get_ports {afe_fclk_n[0]}]  
set_property PACKAGE_PIN  AA19 [get_ports {afe_dclk_p[0]}]
set_property PACKAGE_PIN  AB19 [get_ports {afe_dclk_n[0]}]  

# LVDS inputs from AFE 1 (Bank 16)

set_property PACKAGE_PIN  B25 [get_ports {afe_data_p[1][0]}]
set_property PACKAGE_PIN  A25 [get_ports {afe_data_n[1][0]}]
set_property PACKAGE_PIN  A23 [get_ports {afe_data_p[1][1]}] 
set_property PACKAGE_PIN  A24 [get_ports {afe_data_n[1][1]}]
set_property PACKAGE_PIN  E21 [get_ports {afe_data_p[1][2]}]
set_property PACKAGE_PIN  D21 [get_ports {afe_data_n[1][2]}]
set_property PACKAGE_PIN  C21 [get_ports {afe_data_p[1][3]}]
set_property PACKAGE_PIN  B21 [get_ports {afe_data_n[1][3]}]
set_property PACKAGE_PIN  B19 [get_ports {afe_data_p[1][4]}]
set_property PACKAGE_PIN  A19 [get_ports {afe_data_n[1][4]}]
set_property PACKAGE_PIN  A17 [get_ports {afe_data_p[1][5]}]
set_property PACKAGE_PIN  A18 [get_ports {afe_data_n[1][5]}]
set_property PACKAGE_PIN  C17 [get_ports {afe_data_p[1][6]}]
set_property PACKAGE_PIN  B17 [get_ports {afe_data_n[1][6]}]
set_property PACKAGE_PIN  E16 [get_ports {afe_data_p[1][7]}]
set_property PACKAGE_PIN  D16 [get_ports {afe_data_n[1][7]}]
set_property PACKAGE_PIN  D19 [get_ports {afe_fclk_p[1]}]
set_property PACKAGE_PIN  C19 [get_ports {afe_fclk_n[1]}] 
set_property PACKAGE_PIN  D18 [get_ports {afe_dclk_p[1]}]
set_property PACKAGE_PIN  C18 [get_ports {afe_dclk_n[1]}]  

# LVDS inputs from AFE 2 (Bank 15)

set_property PACKAGE_PIN  K22 [get_ports {afe_data_p[2][0]}]
set_property PACKAGE_PIN  K23 [get_ports {afe_data_n[2][0]}]
set_property PACKAGE_PIN  J24 [get_ports {afe_data_p[2][1]}]
set_property PACKAGE_PIN  H24 [get_ports {afe_data_n[2][1]}]
set_property PACKAGE_PIN  J25 [get_ports {afe_data_p[2][2]}]
set_property PACKAGE_PIN  J26 [get_ports {afe_data_n[2][2]}]
set_property PACKAGE_PIN  H26 [get_ports {afe_data_p[2][3]}]
set_property PACKAGE_PIN  G26 [get_ports {afe_data_n[2][3]}]
set_property PACKAGE_PIN  E25 [get_ports {afe_data_p[2][4]}]
set_property PACKAGE_PIN  D25 [get_ports {afe_data_n[2][4]}]
set_property PACKAGE_PIN  E26 [get_ports {afe_data_p[2][5]}]
set_property PACKAGE_PIN  D26 [get_ports {afe_data_n[2][5]}]
set_property PACKAGE_PIN  F23 [get_ports {afe_data_p[2][6]}]
set_property PACKAGE_PIN  E23 [get_ports {afe_data_n[2][6]}]
set_property PACKAGE_PIN  G22 [get_ports {afe_data_p[2][7]}]
set_property PACKAGE_PIN  F22 [get_ports {afe_data_n[2][7]}]
set_property PACKAGE_PIN  H21 [get_ports {afe_fclk_p[2]}]
set_property PACKAGE_PIN  H22 [get_ports {afe_fclk_n[2]}]
set_property PACKAGE_PIN  K21 [get_ports {afe_dclk_p[2]}]
set_property PACKAGE_PIN  J21 [get_ports {afe_dclk_n[2]}]  

# LVDS inputs from AFE 3 (Bank 14)

set_property PACKAGE_PIN  T24 [get_ports {afe_data_p[3][0]}]
set_property PACKAGE_PIN  T25 [get_ports {afe_data_n[3][0]}]
set_property PACKAGE_PIN  T23 [get_ports {afe_data_p[3][1]}]
set_property PACKAGE_PIN  R23 [get_ports {afe_data_n[3][1]}]
set_property PACKAGE_PIN  R25 [get_ports {afe_data_p[3][2]}]
set_property PACKAGE_PIN  P25 [get_ports {afe_data_n[3][2]}]
set_property PACKAGE_PIN  R26 [get_ports {afe_data_p[3][3]}]
set_property PACKAGE_PIN  P26 [get_ports {afe_data_n[3][3]}]
set_property PACKAGE_PIN  N26 [get_ports {afe_data_p[3][4]}]
set_property PACKAGE_PIN  M26 [get_ports {afe_data_n[3][4]}]
set_property PACKAGE_PIN  M24 [get_ports {afe_data_p[3][5]}]
set_property PACKAGE_PIN  M25 [get_ports {afe_data_n[3][5]}]
set_property PACKAGE_PIN  L24 [get_ports {afe_data_p[3][6]}]
set_property PACKAGE_PIN  L25 [get_ports {afe_data_n[3][6]}]
set_property PACKAGE_PIN  K25 [get_ports {afe_data_p[3][7]}]
set_property PACKAGE_PIN  K26 [get_ports {afe_data_n[3][7]}]
set_property PACKAGE_PIN  M21 [get_ports {afe_fclk_p[3]}]
set_property PACKAGE_PIN  M22 [get_ports {afe_fclk_n[3]}]
set_property PACKAGE_PIN  N21 [get_ports {afe_dclk_p[3]}]
set_property PACKAGE_PIN  N22 [get_ports {afe_dclk_n[3]}]  

# LVDS inputs from AFE 4 (Bank 13)

set_property PACKAGE_PIN  W20  [get_ports {afe_data_p[4][0]}]
set_property PACKAGE_PIN  Y20  [get_ports {afe_data_n[4][0]}]
set_property PACKAGE_PIN  Y22  [get_ports {afe_data_p[4][1]}]
set_property PACKAGE_PIN  Y23  [get_ports {afe_data_n[4][1]}]
set_property PACKAGE_PIN  AA22 [get_ports {afe_data_p[4][2]}]
set_property PACKAGE_PIN  AA23 [get_ports {afe_data_n[4][2]}]
set_property PACKAGE_PIN  AB24 [get_ports {afe_data_p[4][3]}]
set_property PACKAGE_PIN  AC24 [get_ports {afe_data_n[4][3]}]
set_property PACKAGE_PIN  AB26 [get_ports {afe_data_p[4][4]}]
set_property PACKAGE_PIN  AC26 [get_ports {afe_data_n[4][4]}]
set_property PACKAGE_PIN  Y25  [get_ports {afe_data_p[4][5]}]
set_property PACKAGE_PIN  AA25 [get_ports {afe_data_n[4][5]}]
set_property PACKAGE_PIN  W25  [get_ports {afe_data_p[4][6]}]
set_property PACKAGE_PIN  Y26  [get_ports {afe_data_n[4][6]}]
set_property PACKAGE_PIN  V26  [get_ports {afe_data_p[4][7]}]
set_property PACKAGE_PIN  W26  [get_ports {afe_data_n[4][7]}]
set_property PACKAGE_PIN  U21  [get_ports {afe_fclk_p[4]}]
set_property PACKAGE_PIN  V21  [get_ports {afe_fclk_n[4]}]
set_property PACKAGE_PIN  U22  [get_ports {afe_dclk_p[4]}]
set_property PACKAGE_PIN  V22  [get_ports {afe_dclk_n[4]}]  

set_property IOSTANDARD LVDS_25 [get_ports {afe_data_p[?][?]}]
set_property IOSTANDARD LVDS_25 [get_ports {afe_data_n[?][?]}]
set_property IOSTANDARD LVDS_25 [get_ports {afe_?clk_p[?]}]
set_property IOSTANDARD LVDS_25 [get_ports {afe_?clk_n[?]}]

set_property DIFF_TERM TRUE [get_ports {afe_data_p[?][?]}]
set_property DIFF_TERM TRUE [get_ports {afe_data_n[?][?]}]
set_property DIFF_TERM TRUE [get_ports {afe_?clk_p[?]}]
set_property DIFF_TERM TRUE [get_ports {afe_?clk_n[?]}]

# #############################################################################
# General bitstream constraints...

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

