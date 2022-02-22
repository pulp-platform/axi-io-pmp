#!/bin/bash

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
