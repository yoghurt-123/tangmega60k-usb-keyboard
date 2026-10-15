create_clock -name audio_clk -period 19.047619 [get_pins {u_osc/osc_inst/OSCOUT}]
create_clock -name sys_clk -period 20 [get_ports {sys_clk}]
create_generated_clock -name usb_clk -source [get_ports {sys_clk}] -multiply_by 6 -divide_by 25 [get_pins {u_usb_pll/u_pll/PLLA_inst/CLKOUT0}]
set_clock_groups -asynchronous -group [get_clocks {audio_clk}] -group [get_clocks {sys_clk}]
set_clock_groups -asynchronous -group [get_clocks {audio_clk}] -group [get_clocks {usb_clk}]
set_false_path -from [get_ports {rst_n}]

