#system clk H16 - 125MHz
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk_in1_0]

#Inputs en and reset from slider switches
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports reset_0]


