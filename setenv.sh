#!/bin/bash

SCRIPT_PATH=`realpath "$0"`
export CGRAFLOW_PATH=$(dirname "${SCRIPT_PATH}")

export PATH="$HOME/miniconda/bin:$PATH"
export LLVM_CONFIG=$CGRAFLOW_PATH/llvm/bin/llvm-config
export CLANG=$CGRAFLOW_PATH/llvm/bin/clang
export PYTHONPATH=$PYTHONPATH:$CGRAFLOW_PATH/smt-switch
export COREIR=$CGRAFLOW_PATH/coreir
export LD_LIBRARY_PATH=$COREIR/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/$CGRAFLOW_PATH/CGRAMapper/lib/"

export CC=gcc-4.9
export CXX=g++-4.9

