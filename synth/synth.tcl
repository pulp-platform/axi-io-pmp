# remove previous library
sh rm -rf WORK/*
remove_design -design

# enable multithreading
set disable_multicore_resource_checks true
set NumberThreads [exec cat /proc/cpuinfo | grep -c processor]
set_host_options -max_cores $NumberThreads

# import & analyze source files
source analyze.tcl

# elaborate design from top level
elaborate dut

# set constraints
set_max_delay -to [all_outputs] 500
set_max_area 0
set_load 0.1 [all_outputs]
set_max_fanout 1 [all_inputs]
set_fanout_load 8 [all_outputs]

# do the actual synthesis
compile_ultra -incremental

# generate reports
report_timing
report_area
