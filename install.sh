#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.

sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt-get update -y
sudo apt-get install g++-4.9 -y
sudo apt-get install gcc-4.9 -y

sudo apt-get install verilator luajit build-essential clang libedit-dev libpng-dev csh libgmp3-dev git cmake zlib1g zlib1g-dev graphviz-dev python3 swig2.0 libcln-dev imagemagick python-virtualenv libxml2-dev libxslt-dev python3-dev -y

if [[ -z "${TRAVIS_BUILD_DIR}" ]]; then
    # Halide_CoreIR/test/scripts/install_travis.sh is known to use this
    export TRAVIS_BUILD_DIR=`pwd`
fi

export halide_git="https://github.com/jeffsetter/Halide_CoreIR.git"
export coreir_git="https://github.com/rdaly525/coreir.git"
export mapper_git="https://github.com/StanfordAHA/CGRAMapper.git"
export cgra_git="https://github.com/StanfordAHA/CGRAGenerator.git"
export pnr_git="https://github.com/cdonovick/smt-pnr"
export smt_git="https://github.com/makaimann/smt-switch"

export halide_branch="master"
export coreir_branch="master"
export mapper_branch="master"
export cgra_branch="master"
export pnr_branch="io_tiles"
export smt_branch="master"

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


#pull all repos
git clone -b ${halide_branch} -- ${halide_git} || git -C Halide_CoreIR pull
git clone -b ${coreir_branch} -- ${coreir_git} || git -C coreir pull
git clone -b ${mapper_branch} -- ${mapper_git} || git -C CGRAMapper pull
git clone -b ${cgra_branch} -- ${cgra_git} || git -C CGRAGenerator pull
git clone -b ${pnr_branch} -- ${pnr_git} || git -C smt-pnr pull
git clone -b ${smt_branch} -- ${smt_git} || git -C smt-switch pull

#[SR 12/2017] somebody might want to clean this up later
git clone https://github.com/StanfordVLSI/Genesis2.git /tmp/Genesis2

# setup halide env vars
source Halide_CoreIR/test/scripts/before_install_travis.sh

# build coreir
cd coreir;
export COREIRCONFIG="g++-4.9";
#-----
# SR 171027 derp support
# COREIRCONFIG var (above) did not do the trick for derp.
# Had to add this (until someone comes up with something better):
# sudo update-alternatives --remove-all gcc # Travis error: "no alternatives for gcc"
# sudo update-alternatives --remove-all g++ # Travis error: "no alternatives for gcc"
# Installs with priority 20, dunno why.  Web page says:
#   Each alternative has a priority associated with it. When a link
#   group is in automatic mode, the alternatives pointed to by members
#   of the group will be those which have the highest priority.
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 20
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 20
#-----
make -j2 build
sudo make -j2 install
cd ..;

pip install coreir

pwd
cd CGRAMapper
make -j2
cd ../;

date

# API for SMT solving with different solvers
export PYTHONPATH=$PYTHONPATH:$PWD/smt-switch

pwd

# Halide installation (llvm, etc.)
Halide_CoreIR/test/scripts/install_travis.sh

# pnr
# run script that installs solvers and adds necessary environment variables
# if all the solvers are already cached it doesn't need to download
# if there are any missing solvers, downloads from Makai's AFS
. ./smt-pnr/util/get_smt_solvers.sh
pip install -e smt-pnr/package

# need this for the new dot-compare test(s)
# pip install pygtk
sudo apt-get install python-gtk2 -y
