#!/usr/bin/env bash

# add eda tools packcage repo
echo 'deb http://download.opensuse.org/repositories/home:/phiwag:/edatools/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/home:phiwag:edatools.list
curl -fsSL https://download.opensuse.org/repositories/home:phiwag:edatools/xUbuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_phiwag_edatools.gpg > /dev/null
sudo apt update

# install required packages
xargs sudo apt-get install < ubuntu_requirements.txt

# install python virtual environment
git submodule update --init --recursive
virtualenv -p python3 venv
source venv/bin/activate
python3 -m pip install -r requirements.txt
