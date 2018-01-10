#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.

python scripts/install_third_party_dependencies.py

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
export pnr_branch="master"
export smt_branch="master"

#halide
export LLVM_VERSION=3.7.1
export BUILD_SYSTEM=MAKE
export CXX_=g++-4.9
export CC_=gcc-4.9

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
