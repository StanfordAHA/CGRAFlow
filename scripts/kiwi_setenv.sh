#!/bin/bash

SCRIPT_PATH=`realpath "$0"`
export CGRAFLOW_PATH=$(dirname "${SCRIPT_PATH}")

export PATH="$HOME/miniconda/bin:$PATH"
export PYTHONPATH=$PYTHONPATH:$CGRAFLOW_PATH/smt-switch
export COREIR=$CGRAFLOW_PATH/coreir
export LD_LIBRARY_PATH=$COREIR/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/$CGRAFLOW_PATH/CGRAMapper/lib/"

export LLVM_CONFIG=/usr/bin/llvm-config-5.0
export LLVM_DIR=/usr/lib/llvm-5.0/cmake
export CLANG=/usr/bin/clang-5.0


export CC=gcc-4.9
export CXX=g++-4.9

