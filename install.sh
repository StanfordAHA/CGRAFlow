#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.

sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt-get install g++-4.9
sudo apt-get install gcc-4.9

sudo apt-get install verilator luajit build-essential clang libedit-dev libpng-dev csh libgmp3-dev git cmake zlib1g zlib1g-dev graphviz-dev python3 swig2.0 libcln-dev imagemagick python-virtualenv libxml2-dev libxslt-dev python3-dev

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

export halide_branch="coreir"
export coreir_branch="dev"
export mapper_branch="dev"
export cgra_branch="master"
export pnr_branch="master"
export smt_branch="master"

#halide
export LLVM_VERSION=3.7.1
export BUILD_SYSTEM=MAKE
export CXX_=g++-4.9
export CC_=gcc-4.9

sudo pip install -U pip setuptools  # Install latest pip and setuptools
sudo pip install virtualenv
virtualenv -p /usr/bin/python3 CGRAFlowPy3Env
source CGRAFlowPy3Env/bin/activate

#pull all repos
git clone -b ${halide_branch} -- ${halide_git} || git -C Halide_CoreIR pull
git clone -b ${coreir_branch} -- ${coreir_git} || git -C coreir pull
git clone -b ${mapper_branch} -- ${mapper_git} || git -C CGRAMapper pull
git clone -b ${cgra_branch} -- ${cgra_git} || git -C CGRAGenerator pull
git clone -b ${pnr_branch} -- ${pnr_git} || git -C smt-pnr pull
git clone -b ${smt_branch} -- ${smt_git} || git -C smt-switch pull

# setup halide env vars
source Halide_CoreIR/test/scripts/before_install_travis.sh

# build coreir
cd coreir;
export COREIRCONFIG="g++-4.9";
export COREIR=$PWD
export LD_LIBRARY_PATH=$PWD/lib:$LD_LIBRARY_PATH
make -j2 install
make -j2 py
cd ..;

# I think the script might be lost...here's a quick reset.
#cd ${TRAVIS_BUILD_DIR};

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
