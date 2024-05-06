set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR NO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]

########################################################
# Main board
########################################################
# Clock
create_clock -add -name sysclk_pin -period 10.000 -waveform {0.000 5.000} [get_ports sysclk]
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports sysclk]

# Reset
set_property -dict { PACKAGE_PIN P6  IOSTANDARD LVCMOS33 } [get_ports sysrst_n]

# Analog inputs
set_property -dict { PACKAGE_PIN H8  IOSTANDARD LVCMOS33 } [get_ports vp]
set_property -dict { PACKAGE_PIN J7  IOSTANDARD LVCMOS33 } [get_ports vn]

# Local LEDs
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN K12 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN L14 IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN L13 IOSTANDARD LVCMOS33 } [get_ports {led[3]}]
set_property -dict { PACKAGE_PIN M16 IOSTANDARD LVCMOS33 } [get_ports {led[4]}]
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports {led[5]}]
set_property -dict { PACKAGE_PIN M12 IOSTANDARD LVCMOS33 } [get_ports {led[6]}]
set_property -dict { PACKAGE_PIN N16 IOSTANDARD LVCMOS33 } [get_ports {led[7]}]

# UART
# serial names are flipped in the schematic (named for the FTDI chip)
set_property -dict { PACKAGE_PIN P16 IOSTANDARD LVCMOS33 } [get_ports {uart_tx}]
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports {uart_rx}]

########################################################
# I/O board (7-seg display, LEDs Push buttons & switches
########################################################
# External LEDs on I/O board
#         Bank 3       Bank 2     Bank 1
# led # L24.....L17  L16.....L9  L8.....L1
# bit #  23......16   15.....8    7.....0

set_property -dict { PACKAGE_PIN B6 IOSTANDARD LVCMOS33 } [get_ports {xled[0]}]
set_property -dict { PACKAGE_PIN B5 IOSTANDARD LVCMOS33 } [get_ports {xled[1]}]
set_property -dict { PACKAGE_PIN A5 IOSTANDARD LVCMOS33 } [get_ports {xled[2]}]
set_property -dict { PACKAGE_PIN A4 IOSTANDARD LVCMOS33 } [get_ports {xled[3]}]
set_property -dict { PACKAGE_PIN B4 IOSTANDARD LVCMOS33 } [get_ports {xled[4]}]
set_property -dict { PACKAGE_PIN A3 IOSTANDARD LVCMOS33 } [get_ports {xled[5]}]
set_property -dict { PACKAGE_PIN F4 IOSTANDARD LVCMOS33 } [get_ports {xled[6]}]
set_property -dict { PACKAGE_PIN F3 IOSTANDARD LVCMOS33 } [get_ports {xled[7]}]
#
set_property -dict { PACKAGE_PIN F2 IOSTANDARD LVCMOS33 } [get_ports {xled[8]}]
set_property -dict { PACKAGE_PIN E1 IOSTANDARD LVCMOS33 } [get_ports {xled[9]}]
set_property -dict { PACKAGE_PIN B2 IOSTANDARD LVCMOS33 } [get_ports {xled[10]}]
set_property -dict { PACKAGE_PIN A2 IOSTANDARD LVCMOS33 } [get_ports {xled[11]}]
set_property -dict { PACKAGE_PIN E2 IOSTANDARD LVCMOS33 } [get_ports {xled[12]}]
set_property -dict { PACKAGE_PIN D1 IOSTANDARD LVCMOS33 } [get_ports {xled[13]}]
set_property -dict { PACKAGE_PIN E6 IOSTANDARD LVCMOS33 } [get_ports {xled[14]}]
set_property -dict { PACKAGE_PIN K5 IOSTANDARD LVCMOS33 } [get_ports {xled[15]}]
#
set_property -dict { PACKAGE_PIN G2 IOSTANDARD LVCMOS33 } [get_ports {xled[16]}]
set_property -dict { PACKAGE_PIN G1 IOSTANDARD LVCMOS33 } [get_ports {xled[17]}]
set_property -dict { PACKAGE_PIN H2 IOSTANDARD LVCMOS33 } [get_ports {xled[18]}]
set_property -dict { PACKAGE_PIN H1 IOSTANDARD LVCMOS33 } [get_ports {xled[19]}]
set_property -dict { PACKAGE_PIN K1 IOSTANDARD LVCMOS33 } [get_ports {xled[20]}]
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports {xled[21]}]
set_property -dict { PACKAGE_PIN L3 IOSTANDARD LVCMOS33 } [get_ports {xled[22]}]
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 } [get_ports {xled[23]}]

# dip switches
# External dip swithces on I/O board
#         Bank 3        Bank 2      Bank 1
# sw  # SW24....SW17  SW16....SW9  SW8.....SW1
# bit #  23......16    15......8    7.......0
#
set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports {sw[7]}] 
set_property -dict { PACKAGE_PIN D4 IOSTANDARD LVCMOS33 } [get_ports {sw[6]}]
set_property -dict { PACKAGE_PIN G4 IOSTANDARD LVCMOS33 } [get_ports {sw[5]}]
set_property -dict { PACKAGE_PIN G5 IOSTANDARD LVCMOS33 } [get_ports {sw[4]}]
set_property -dict { PACKAGE_PIN E5 IOSTANDARD LVCMOS33 } [get_ports {sw[3]}]
set_property -dict { PACKAGE_PIN F5 IOSTANDARD LVCMOS33 } [get_ports {sw[2]}]
set_property -dict { PACKAGE_PIN D5 IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]
set_property -dict { PACKAGE_PIN D6 IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
#
set_property -dict { PACKAGE_PIN N6 IOSTANDARD LVCMOS33 } [get_ports {sw[15]}]
set_property -dict { PACKAGE_PIN M6 IOSTANDARD LVCMOS33 } [get_ports {sw[14]}]
set_property -dict { PACKAGE_PIN B1 IOSTANDARD LVCMOS33 } [get_ports {sw[13]}]
set_property -dict { PACKAGE_PIN C1 IOSTANDARD LVCMOS33 } [get_ports {sw[12]}]
set_property -dict { PACKAGE_PIN C2 IOSTANDARD LVCMOS33 } [get_ports {sw[11]}]
set_property -dict { PACKAGE_PIN C3 IOSTANDARD LVCMOS33 } [get_ports {sw[10]}]
set_property -dict { PACKAGE_PIN D3 IOSTANDARD LVCMOS33 } [get_ports {sw[9]}]
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports {sw[8]}]
#
set_property -dict { PACKAGE_PIN K2 IOSTANDARD LVCMOS33 } [get_ports {sw[23]}]
set_property -dict { PACKAGE_PIN K3 IOSTANDARD LVCMOS33 } [get_ports {sw[22]}]
set_property -dict { PACKAGE_PIN J4 IOSTANDARD LVCMOS33 } [get_ports {sw[21]}]
set_property -dict { PACKAGE_PIN J5 IOSTANDARD LVCMOS33 } [get_ports {sw[20]}]
set_property -dict { PACKAGE_PIN H3 IOSTANDARD LVCMOS33 } [get_ports {sw[19]}]
set_property -dict { PACKAGE_PIN J3 IOSTANDARD LVCMOS33 } [get_ports {sw[18]}]
set_property -dict { PACKAGE_PIN H4 IOSTANDARD LVCMOS33 } [get_ports {sw[17]}]
set_property -dict { PACKAGE_PIN H5 IOSTANDARD LVCMOS33 } [get_ports {sw[16]}]

# 7-seg display
set_property -dict { PACKAGE_PIN T5 IOSTANDARD LVCMOS33 } [get_ports {seg[0]}]
set_property -dict { PACKAGE_PIN R5 IOSTANDARD LVCMOS33 } [get_ports {seg[1]}]
set_property -dict { PACKAGE_PIN T9 IOSTANDARD LVCMOS33 } [get_ports {seg[2]}]
set_property -dict { PACKAGE_PIN R6 IOSTANDARD LVCMOS33 } [get_ports {seg[3]}]
set_property -dict { PACKAGE_PIN R7 IOSTANDARD LVCMOS33 } [get_ports {seg[4]}]
set_property -dict { PACKAGE_PIN T7 IOSTANDARD LVCMOS33 } [get_ports {seg[5]}]
set_property -dict { PACKAGE_PIN T8 IOSTANDARD LVCMOS33 } [get_ports {seg[6]}]

# Anode
set_property -dict { PACKAGE_PIN P9 IOSTANDARD LVCMOS33 } [get_ports {an[3]}]
set_property -dict { PACKAGE_PIN N9 IOSTANDARD LVCMOS33 } [get_ports {an[2]}]
set_property -dict { PACKAGE_PIN R8 IOSTANDARD LVCMOS33 } [get_ports {an[1]}]
set_property -dict { PACKAGE_PIN P8 IOSTANDARD LVCMOS33 } [get_ports {an[0]}]

# Decimal point
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports {dp}]

# push buttons
#
#        btnU
# btnL   btnC   btnR
#        btnD
#
set_property -dict { PACKAGE_PIN C6  IOSTANDARD LVCMOS33 } [get_ports {btnU}]
set_property -dict { PACKAGE_PIN A7  IOSTANDARD LVCMOS33 } [get_ports {btnD}]
set_property -dict { PACKAGE_PIN C7  IOSTANDARD LVCMOS33 } [get_ports {btnC}]
set_property -dict { PACKAGE_PIN B7  IOSTANDARD LVCMOS33 } [get_ports {btnL}]
set_property -dict { PACKAGE_PIN P11 IOSTANDARD LVCMOS33 } [get_ports {btnR}]
