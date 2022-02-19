# remove previous library
sh rm -rf WORK/*
remove_design -design

# set multithreading
set disable_multicore_resource_checks true
set NumberThreads [exec cat /proc/cpuinfo | grep -c processor]
set_host_options -max_cores $NumberThreads

source analyze.tcl

elaborate dut

# Constraints
set_max_delay -to [all_outputs] 400
set_max_area 0
set_load 0.1 [all_outputs]
set_max_fanout 1 [all_inputs]
set_fanout_load 8 [all_outputs]

#compile_ultra
compile_ultra -gate_clock -no_autoungroup -incremental

report_timing
