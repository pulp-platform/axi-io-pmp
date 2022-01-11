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
# Description: Setup linux and python (virtual) environment, including relevant
#              environment variables and missing dependencies.


# add eda tools packcage repo
echo 'deb http://download.opensuse.org/repositories/home:/phiwag:/edatools/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/home:phiwag:edatools.list
curl -fsSL https://download.opensuse.org/repositories/home:phiwag:edatools/xUbuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_phiwag_edatools.gpg > /dev/null
sudo apt update

# install required packages
xargs sudo apt-get -y install < ubuntu_requirements.txt

# install python virtual environment
git submodule update --init --recursive
python3 -m venv venv/
source venv/bin/activate
python3 -m pip install wheel
python3 -m pip install -r requirements.txt

# setup questasim
QUESTA_ENV=/opt/questasim/setup.sh
if [ -f "$QUESTA_ENV" ]; then
  source $QUESTA_ENV
fi
