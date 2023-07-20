export DESIGN_NAME = dut
export PLATFORM    = nangate45

export VERILOG_FILES = ../../iopmp.v
export SDC_FILE      = ../../constraint.sdc
export ABC_AREA      = 1

# these values must be multiples of placement site
# x=0.19 y=1.4
export DIE_AREA    =  0     0   703.76 702.8
export CORE_AREA   = 10.07 11.2 633.27 631.4

#export DIE_AREA    = 0 0 100.13 100.8
#export CORE_AREA   = 10.07 11.2 90.25 91

#export CORE_UTILIZATION  = 30
#export CORE_ASPECT_RATIO = 1
#export CORE_MARGIN       = 2
export PLACE_DENSITY     = 0.80

#export VERILOG_TOP_PARAMS
export SYNTH_ARGS =-noshare # disable yosys share (SAT solver runs out of memory even on sysstem with 64GB RAM)
