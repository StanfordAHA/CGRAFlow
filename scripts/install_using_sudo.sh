#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.

sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt-get update -y
sudo apt-get install g++-4.9 -y
sudo apt-get install gcc-4.9 -y
# keyi: modern C++
sudo apt-get install gcc-7 -y
sudo apt-get install g++-7 -y

sudo apt-get install verilator luajit build-essential clang libedit-dev libpng-dev csh libgmp3-dev git cmake zlib1g zlib1g-dev graphviz-dev python3 swig2.0 libcln-dev imagemagick python-virtualenv libxml2-dev libxslt-dev python3-dev python3-pip realpath libigraph0-dev -y

if [[ -z "${TRAVIS_BUILD_DIR}" ]]; then
    # Halide-to-Hardware/test/scripts/install_travis.sh is known to use this
    export TRAVIS_BUILD_DIR=`pwd`
fi

# Installs with priority 20, dunno why.  Web page says:
#   Each alternative has a priority associated with it. When a link
#   group is in automatic mode, the alternatives pointed to by members
#   of the group will be those which have the highest priority.
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 20
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 20

#[SR 12/2017] somebody might want to clean this up later
git clone https://github.com/StanfordVLSI/Genesis2.git /tmp/Genesis2

# setup halide env vars
source Halide-to-Hardware/test/scripts/before_install_travis.sh

# Halide installation (llvm, clang)
Halide-to-Hardware/test/scripts/install_travis.sh

# need this for the new dot-compare test(s)
# pip install pygtk
sudo apt-get install python-gtk2 -y

date
