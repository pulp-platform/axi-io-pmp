# remove previous library
sh rm -rf WORK/*
remove_design -design

# set multithreading
set disable_multicore_resource_checks true
set NumberThreads [exec cat /proc/cpuinfo | grep -c processor]
set_host_options -max_cores $NumberThreads

source analyze.tcl

elaborate dut
#elaborate axi_io_pmp

# Constraints

set_units -time ps -resistance Kohm -capacitance fF -voltage V -current mA

#set_max_delay -to [all_outputs] 500

# 240ps -> 4.167GHz clock
create_clock clk -name CLK -period 240 -waveform {0.0 120.0}
#create_clock clk_i -name CLK -period 450 -waveform {0.0 225.0}

#set_clock_uncertainty -setup 0.5 [get_clocks clk1]
#set_clock_uncertainty -hold 0.2 [get_clocks clk1]

#set_clock_uncertainty -max_rise 0.12 [get_clocks clk1]
#set_clock_uncertainty -max_fall 0.12 [get_clocks clk1]
#set_clock_uncertainty -min_rise 0.12 [get_clocks clk1]
#set_clock_uncertainty -min_fall 0.12 [get_clocks clk1]

#set_max_area 0
#set_load 0.1 [all_outputs]
#set_max_fanout 1 [all_inputs]
#set_fanout_load 8 [all_outputs]

compile_ultra
#compile_ultra -gate_clock -no_autoungroup -incremental

# report_timing -transition_time -nets -attributes -nosplit
# report_area -nosplit -hierarchy
# report_power -nosplit -hier
# report_reference -nosplit -hierarchy
report_timing
#report_area
