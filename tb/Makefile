
TOPLEVEL_LANG ?= verilog
SIM ?= questa  # verilator
WAVES ?= 1
COVERAGE ?= 1
GUI ?= 0

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

DUT      = axi_io_pmp
TOPLEVEL = $(DUT)
MODULE   = test_$(DUT)


VERILOG_SOURCES += ../src/$(DUT).v

VERILOG_SOURCES += ../src/axi_register/axi_register_wr.v
VERILOG_SOURCES += ../src/axi_register/axi_register_rd.v

VERILOG_SOURCES += ../src/common_cells/src/lzc.sv

VERILOG_SOURCES += ../src/pmp/pmp_entry.sv
VERILOG_SOURCES += ../src/pmp/pmp.sv


# VERILOG_SOURCES += ../src/common_cells/src/spill_register.sv
# VERILOG_SOURCES += ../src/axi/include/axi/assign.svh
# VERILOG_SOURCES += ../src/axi/include/axi/typedef.svh
# VERILOG_SOURCES += ../src/axi/src/axi_pkg.sv
# VERILOG_SOURCES += ../src/axi/src/axi_cut.sv
# VERILOG_SOURCES += ../src/axi_conf.sv
# VERILOG_SOURCES += ../src/axi_register.v

REG_TYPE ?= 1 # { Bypass = 0, Registered = 1, Skid Buffer = 2}

# module parameters
export PARAM_DATA_WIDTH ?= 32
export PARAM_ADDR_WIDTH ?= 32
export PARAM_STRB_WIDTH ?= $(shell expr $(PARAM_DATA_WIDTH) / 8 )
export PARAM_ID_WIDTH ?= 8
export PARAM_AWUSER_ENABLE ?= 0
export PARAM_AWUSER_WIDTH ?= 1
export PARAM_WUSER_ENABLE ?= 0
export PARAM_WUSER_WIDTH ?= 1
export PARAM_BUSER_ENABLE ?= 0
export PARAM_BUSER_WIDTH ?= 1
export PARAM_ARUSER_ENABLE ?= 0
export PARAM_ARUSER_WIDTH ?= 1
export PARAM_RUSER_ENABLE ?= 0
export PARAM_RUSER_WIDTH ?= 1
export PARAM_AW_REG_TYPE ?= $(REG_TYPE)
export PARAM_W_REG_TYPE ?= $(REG_TYPE)
export PARAM_B_REG_TYPE ?= $(REG_TYPE)
export PARAM_AR_REG_TYPE ?= $(REG_TYPE)
export PARAM_R_REG_TYPE ?= $(REG_TYPE)


ifeq ($(SIM), questa)

	# verilog include dirs
	EXTRA_ARGS += +incdir+../src/pmp/include
	EXTRA_ARGS += +incdir+../src/common_cells/src

	# parameters
	VSIM_ARGS += -GDATA_WIDTH=$(PARAM_DATA_WIDTH)
	VSIM_ARGS += -GADDR_WIDTH=$(PARAM_ADDR_WIDTH)
	VSIM_ARGS += -GSTRB_WIDTH=$(PARAM_STRB_WIDTH)
	VSIM_ARGS += -GID_WIDTH=$(PARAM_ID_WIDTH)
	VSIM_ARGS += -GAWUSER_ENABLE=$(PARAM_AWUSER_ENABLE)
	VSIM_ARGS += -GAWUSER_WIDTH=$(PARAM_AWUSER_WIDTH)
	VSIM_ARGS += -GWUSER_ENABLE=$(PARAM_WUSER_ENABLE)
	VSIM_ARGS += -GWUSER_WIDTH=$(PARAM_WUSER_WIDTH)
	VSIM_ARGS += -GBUSER_ENABLE=$(PARAM_BUSER_ENABLE)
	VSIM_ARGS += -GBUSER_WIDTH=$(PARAM_BUSER_WIDTH)
	VSIM_ARGS += -GARUSER_ENABLE=$(PARAM_ARUSER_ENABLE)
	VSIM_ARGS += -GARUSER_WIDTH=$(PARAM_ARUSER_WIDTH)
	VSIM_ARGS += -GRUSER_ENABLE=$(PARAM_RUSER_ENABLE)
	VSIM_ARGS += -GRUSER_WIDTH=$(PARAM_RUSER_WIDTH)
	VSIM_ARGS += -GAW_REG_TYPE=$(PARAM_AW_REG_TYPE)
	VSIM_ARGS += -GW_REG_TYPE=$(PARAM_W_REG_TYPE)
	VSIM_ARGS += -GB_REG_TYPE=$(PARAM_B_REG_TYPE)
	VSIM_ARGS += -GAR_REG_TYPE=$(PARAM_AR_REG_TYPE)
	VSIM_ARGS += -GR_REG_TYPE=$(PARAM_R_REG_TYPE)
	VSIM_ARGS += -GWAVES=$(WAVES)

	#ifeq($(COVERAGE), 1)
		VSIM_ARGS += -coverage -coveranalysis -cvgperinstance
		VSIM_ARGS += -do \"coverage save -codeAll -cvg -onexit $(DUT).ucdb;\"
		VLOG_ARGS += -cover bcs
		# output html report: vcover report -details -html axi_io_pmp.ucdb
	#endif

else ifeq ($(SIM), verilator)

	# omit certain warnings
	COMPILE_ARGS += -Wno-SELRANGE -Wno-WIDTH -Wno-CASEINCOMPLETE -Wno-TIMESCALEMOD

	# parameters
	COMPILE_ARGS += -GDATA_WIDTH=$(PARAM_DATA_WIDTH)
	COMPILE_ARGS += -GADDR_WIDTH=$(PARAM_ADDR_WIDTH)
	COMPILE_ARGS += -GSTRB_WIDTH=$(PARAM_STRB_WIDTH)
	COMPILE_ARGS += -GID_WIDTH=$(PARAM_ID_WIDTH)
	COMPILE_ARGS += -GAWUSER_ENABLE=$(PARAM_AWUSER_ENABLE)
	COMPILE_ARGS += -GAWUSER_WIDTH=$(PARAM_AWUSER_WIDTH)
	COMPILE_ARGS += -GWUSER_ENABLE=$(PARAM_WUSER_ENABLE)
	COMPILE_ARGS += -GWUSER_WIDTH=$(PARAM_WUSER_WIDTH)
	COMPILE_ARGS += -GBUSER_ENABLE=$(PARAM_BUSER_ENABLE)
	COMPILE_ARGS += -GBUSER_WIDTH=$(PARAM_BUSER_WIDTH)
	COMPILE_ARGS += -GARUSER_ENABLE=$(PARAM_ARUSER_ENABLE)
	COMPILE_ARGS += -GARUSER_WIDTH=$(PARAM_ARUSER_WIDTH)
	COMPILE_ARGS += -GRUSER_ENABLE=$(PARAM_RUSER_ENABLE)
	COMPILE_ARGS += -GRUSER_WIDTH=$(PARAM_RUSER_WIDTH)
	COMPILE_ARGS += -GAW_REG_TYPE=$(PARAM_AW_REG_TYPE)
	COMPILE_ARGS += -GW_REG_TYPE=$(PARAM_W_REG_TYPE)
	COMPILE_ARGS += -GB_REG_TYPE=$(PARAM_B_REG_TYPE)
	COMPILE_ARGS += -GAR_REG_TYPE=$(PARAM_AR_REG_TYPE)
	COMPILE_ARGS += -GR_REG_TYPE=$(PARAM_R_REG_TYPE)
	COMPILE_ARGS += -GWAVES=$(WAVES)

endif

include $(shell cocotb-config --makefiles)/Makefile.sim

# Profiling
DOT_BINARY ?= dot

test_profile.pstat: sim

callgraph.svg: test_profile.pstat
	$(shell cocotb-config --python-bin) -m gprof2dot -f pstats ./$< | $(DOT_BINARY) -Tsvg -o $@

profile:
	COCOTB_ENABLE_PROFILING=1 $(MAKE) callgraph.svg

clean::
	@rm -rf $(TOPLEVEL).vcd
	@rm -rf results.xml __pycache__
	@rm -rf callgraph.svg test_profile.pstat
	@rm -rf modelsim.ini transcript vsim.wlf
	@rm -rf $(DUT).vcd $(DUT).ucdb
