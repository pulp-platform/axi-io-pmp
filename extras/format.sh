#!/usr/bin/env bash

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
# Description: Formatting / linting of all source files, including Verilog/SystemVerilog.

# clang formatting
echo "Format c/cpp/h files"
find . -type d \( -name *venv* -o -name *common_cells* -o -name *axi* -o -name *register_interface* -o -name *OpenROAD-flow-scripts* -o -name *verible-v0.0-1897-gbe7e2250* \) -prune -false -o -name ".c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | xargs -I {} clang-format -i {}

# install verible
if [ ! -f "verible.tar.gz" ]; then
  echo "Install verible.."
  wget https://github.com/chipsalliance/verible/releases/download/v0.0-1897-gbe7e2250/verible-v0.0-1897-gbe7e2250-Ubuntu-20.04-focal-x86_64.tar.gz -O verible.tar.gz
  tar -xzf verible.tar.gz
  fi
export PATH=./verible-v0.0-1897-gbe7e2250/bin/:$PATH

# format all verilog files
echo "Format verilog files.."
find . -type d \( -name *venv* -o -name *common_cells* -o -name *axi* -o -name *register_interface* -o -name *OpenROAD-flow-scripts* -o -name *verible-v0.0-1897-gbe7e2250* \) -prune -false -o -name ".svh" -o -name "*.sv" -o -name "*.v" | xargs verible-verilog-format -inplace

echo "All done."
