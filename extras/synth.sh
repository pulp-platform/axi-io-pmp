#!/bin/bash

cd OpenROAD-flow-scripts/
source ./setup_env.sh
cd flow/
make DESIGN_CONFIG=../../config.mk
