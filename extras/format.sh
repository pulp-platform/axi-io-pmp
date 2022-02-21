#!/bin/bash

# clang formatting
echo "Format c/cpp/h files"
#find . -not -path "./.*" -not -path "*OpenROAD*" -not -path "*verible*" -name "*.cpp" -o -name "*.c" -o -name "*.h" | xargs -I {} clang-format -i {}
find . -type d \( -path ./extras/OpenROAD-flow-scripts -o -path *./extras/verible-v0.0-1897-gbe7e2250 \) -prune -o -name "*.cpp" -o -name "*.c" -o -name "*.h" | xargs -I {} clang-format -i {}

# install verible
if [ ! -f "verible.tar.gz" ]; then
  echo "Install verible.."
  wget https://github.com/chipsalliance/verible/releases/download/v0.0-1897-gbe7e2250/verible-v0.0-1897-gbe7e2250-Ubuntu-20.04-focal-x86_64.tar.gz -O verible.tar.gz
  tar -xzf verible.tar.gz
fi
export PATH=./verible-v0.0-1897-gbe7e2250/bin/:$PATH

# format all verilog files
echo "Format verilog files.."
find . -type d \( -path ./extras/OpenROAD-flow-scripts -o -path ./extras/verible-v0.0-1897-gbe7e2250 -o -path ./src/axi -o -path ./src/register_interface -o -path ./src/common_cells \) -prune -o -name ".svh" -o -name "*.sv" -o -name "*.v" | xargs verible-verilog-format -inplace

echo "All done."
