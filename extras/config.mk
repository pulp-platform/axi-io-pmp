export DESIGN_NAME = dut
export PLATFORM    = nangate45

export VERILOG_FILES = ../../iopmp.v
export SDC_FILE      = ../../constraint.sdc
export ABC_AREA      = 1

# These values must be multiples of placement site
# x=0.19 y=1.4
export DIE_AREA    = 0 0 1099.91 1099.0
export CORE_AREA   = 10.07 11.2 1094.97 1094.8

#export DIE_AREA    = 0 0 100.13 100.8
#export CORE_AREA   = 10.07 11.2 90.25 91

#export PLACE_DENSITY = 1.0
