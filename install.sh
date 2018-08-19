#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.

sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt-get update -y
sudo apt-get install g++-4.9 -y
sudo apt-get install gcc-4.9 -y

sudo apt-get install verilator luajit build-essential clang libedit-dev libpng-dev csh libgmp3-dev git cmake zlib1g zlib1g-dev graphviz-dev python3 swig2.0 libcln-dev imagemagick python-virtualenv libxml2-dev libxslt-dev python3-dev python3-pip realpath -y

if [[ -z "${TRAVIS_BUILD_DIR}" ]]; then
    # Halide_CoreIR/test/scripts/install_travis.sh is known to use this
    export TRAVIS_BUILD_DIR=`pwd`
fi

#halide
export LLVM_VERSION=3.7.1
export BUILD_SYSTEM=MAKE
export CXX_=g++-4.9
export CC_=gcc-4.9

wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh;
bash miniconda.sh -u -b -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
hash -r
conda config --set always_yes yes --set changeps1 no
conda update -q conda
conda info -a

which pip
which python
which python3

export COREIRCONFIG="g++-4.9";
# Had to add this (until someone comes up with something better):
# sudo update-alternatives --remove-all gcc # Travis error: "no alternatives for gcc"
# sudo update-alternatives --remove-all g++ # Travis error: "no alternatives for gcc"
# Installs with priority 20, dunno why.  Web page says:
#   Each alternative has a priority associated with it. When a link
#   group is in automatic mode, the alternatives pointed to by members
#   of the group will be those which have the highest priority.
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 20
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 20

pip install delegator.py
python scripts/repo_manager.py                                                  \
    --halide                      master                                        \
    --halide-remote               github.com/jeffsetter/Halide_CoreIR.git       \
                                                                                \
    --coreir                      master                                        \
    --coreir-remote               github.com/rdaly525/coreir.git                \
                                                                                \
    --pycoreir                    master                                        \
    --pycoreir-remote             github.com/leonardt/pycoreir.git              \
                                                                                \
    --pnr-doctor                  master                                        \
    --pnr-doctor-remote           github.com/cdonovick/smt-pnr.git              \
                                                                                \
    --smt-switch                  master                                        \
    --smt-switch-remote           github.com/makaimann/smt-switch.git           \
                                                                                \
    --mapper                      master                                        \
    --mapper-remote               github.com/StanfordAHA/CGRAMapper.git         \
                                                                                \
    --cgra-generator              master                                        \
    --cgra-generator-remote       github.com/StanfordAHA/CGRAGenerator.git      \
                                                                                \
    --test-bench-generator        master                                         \
    --test-bench-generator-remote github.com/StanfordAHA/TestBenchGenerator.git

#[SR 12/2017] somebody might want to clean this up later
git clone https://github.com/StanfordVLSI/Genesis2.git /tmp/Genesis2

# setup halide env vars
source Halide_CoreIR/test/scripts/before_install_travis.sh

pip install -e pycoreir

date

#pwd

# Halide installation (llvm, etc.)
Halide_CoreIR/test/scripts/install_travis.sh

# need this for the new dot-compare test(s)
# pip install pygtk
sudo apt-get install python-gtk2 -y
