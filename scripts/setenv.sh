#!/bin/bash

export PATH="$HOME/miniconda/bin:$PATH"
export PYTHONPATH=$PYTHONPATH:$CGRAFLOW_PATH/smt-switch

export COREIR=$CGRAFLOW_PATH/coreir
export COREIRCONFIG="g++-4.9";

export LD_LIBRARY_PATH=$COREIR/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CGRAFLOW_PATH/CGRAMapper/lib/"

export LLVM_CONFIG=$CGRAFLOW_PATH/llvm/bin/llvm-config
export CLANG=$CGRAFLOW_PATH/llvm/bin/clang

export CC=gcc-4.9
export CXX=g++-4.9

