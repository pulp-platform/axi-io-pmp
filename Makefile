# Copyright 2022 ETH Zurich and University of Bologna.
# Copyright and related rights are licensed under the Solderpad Hardware
# License, Version 0.51 (the "License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
# or agreed to in writing, software, hardware and materials distributed under
# this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#
# Author:      Andreas Kuster, <kustera@ethz.ch>
# Description: General targets from setup to simulation and cleanup

SHELL := /bin/bash

.PHONY: clean

all: bender_intall bender_gen_src sim wave

setup_env:
	source ./setup_env.sh

sim:
	pytest tb/

wave:
	gtkwave sim_build/axi_io_pmp.vcd

bender_install:
	curl --proto '=https' --tlsv1.2 https://pulp-platform.github.io/bender/init -sSf | sh

bender_gen_src:
	./bender script flist --relative-path --exclude axi --exclude common_cells --exclude register_interface > src.list

clean:
	rm -rf bender
	rm -rf sim_build .pytest_cache transcript
