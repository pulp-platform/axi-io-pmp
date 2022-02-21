#!/bin/bash

cd OpenROAD-flow-scripts/
source ./setup_env.sh
cd flow/
make DESIGN_CONFIG=../../config.mk

# python3 getKGE.py OpenROAD-flow-scripts/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib OpenROAD-flow-scripts/flow/reports/
