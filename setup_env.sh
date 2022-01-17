#!/usr/bin/env bash

# install required packages
xargs sudo apt-get install < ubuntu_requirements.txt

# install python virtual environment
git submodule update --init --recursive
virtualenv -p python3 venv
source venv/bin/activate
python3 -m pip install -r requirements.txt
