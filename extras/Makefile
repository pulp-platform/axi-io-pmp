
SHELL := /bin/bash

includes := axi/include \
			register_interface/include \
			common_cells/include
list_includes := $(foreach dir, ${includes}, --incdir=../src/$(dir))

packages := common_cells/src/cf_math_pkg.sv \
			axi/src/axi_pkg.sv \
			register/io_pmp_reg_pkg.sv \
			pmp/include/riscv.sv
list_packages := $(foreach dir, ${packages}, ../src/$(dir))

sources :=  common_cells/src/lzc.sv \
			common_cells/src/spill_register_flushable.sv \
			common_cells/src/spill_register.sv \
			common_cells/src/deprecated/fifo_v2.sv \
			common_cells/src/fifo_v3.sv \
			common_cells/src/stream_register.sv \
			common_cells/src/stream_arbiter_flushable.sv \
			common_cells/src/stream_arbiter.sv \
			common_cells/src/delta_counter.sv \
			common_cells/src/counter.sv \
			common_cells/src/id_queue.sv \
			common_cells/src/rr_arb_tree.sv \
			common_cells/src/onehot_to_bin.sv \
			axi/src/axi_intf.sv \
			axi/src/axi_err_slv.sv \
			axi/src/axi_demux.sv \
			axi/src/axi_atop_filter.sv \
			axi/src/axi_burst_splitter.sv \
			axi/src/axi_to_axi_lite.sv \
			axi/src/axi_cut.sv \
			register/io_pmp_reg_top.sv \
			register_interface/src/axi_to_reg.sv \
			register_interface/src/axi_lite_to_reg.sv \
			register_interface/vendor/lowrisc_opentitan/src/prim_subreg.sv \
			register_interface/vendor/lowrisc_opentitan/src/prim_subreg_arb.sv \
			register_interface/vendor/lowrisc_opentitan/src/prim_subreg_ext.sv \
			register_interface/vendor/lowrisc_opentitan/src/prim_subreg_shadow.sv \
			connector/axi_master_connector.sv \
			connector/axi_slave_connector.sv \
			pmp/pmp_entry.sv \
			pmp/pmp.sv \
			axi_io_pmp.sv \
			dut.sv
list_sources := $(foreach dir, ${sources}, ../src/$(dir))
   

format:
	./format.sh


install_sv2v:
ifeq (,$(wildcard sv2v-Linux.zip))
	wget https://github.com/zachjs/sv2v/releases/download/v0.0.9/sv2v-Linux.zip
	unzip sv2v-Linux.zip
endif

sv2v:
	./sv2v-Linux/sv2v --define=VERILATOR $(list_includes) $(list_packages) $(list_sources) --write iopmp.v

install_synth:
ifeq (,$(wildcard OpenROAD-flow-scripts))
	git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts 
	./OpenROAD-flow-scripts/build_openroad.sh --local
endif

synth:
	./synth.sh

synth_gui:
	cd OpenROAD-flow-scripts/flow/ && make gui_final

flow:
	install_sv2v install_synth sv2v synth

clean:
	rm -rf verible*
	rm iopmp.v
