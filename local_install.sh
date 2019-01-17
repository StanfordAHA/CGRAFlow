#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.

#halide
export LLVM_VERSION=3.7.1
export BUILD_SYSTEM=MAKE
export CXX_=g++-4.9
export CC_=gcc-4.9

export PATH="$HOME/miniconda/bin:$PATH"
if ! [ -d "$HOME/miniconda/bin" ]; then
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh;
    bash miniconda.sh -u -b -p $HOME/miniconda
    hash -r
    conda config --set always_yes yes --set changeps1 no
    conda update -q conda
fi
conda info -a
which pip
which python
which python3

export COREIRCONFIG="g++-4.9";

# get the root folder
ROOT=`dirname "$0"`
export COREIR=`realpath ${ROOT}`/coreir
export LD_LIBRARY_PATH=$COREIR/lib:$LD_LIBRARY_PATH

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
    --mapper                      master                                        \
    --mapper-remote               github.com/StanfordAHA/CGRAMapper.git         \
                                                                                \
    --cgra-generator              master                                        \
    --cgra-generator-remote       github.com/StanfordAHA/CGRAGenerator.git      \
                                                                                \
    --test-bench-generator        master                                        \
    --test-bench-generator-remote github.com/StanfordAHA/TestBenchGenerator.git \
                                                                                \
    --cgra-pnr                    master                                        \
    --cgra-pnr-remote             github.com/Kuree/cgra_pnr.git                 \


#[SR 12/2017] somebody might want to clean this up later
git clone https://github.com/StanfordVLSI/Genesis2.git /tmp/Genesis2

# setup halide env vars
source Halide_CoreIR/test/scripts/before_install_travis.sh

pip install -e pycoreir

date

#pwd

# Halide installation (llvm, etc.)
Halide_CoreIR/test/scripts/install_travis.sh
