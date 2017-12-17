export PATH="$HOME/miniconda/bin:$PATH"
export LLVM_CONFIG=$CGRAFLOW_PATH/llvm/bin/llvm-config
export CLANG=$CGRAFLOW/llvm/bin/clang
export PYTHONPATH=$PYTHONPATH:$CGRAFLOW_PATH/smt-switch
export COREIR=$CGRAFLOW_PATH/coreir
export LD_LIBRARY_PATH=$COREIR/lib:$LD_LIBRARY_PATH

export PYTHONPATH=$PYTHONPATH:$CGRAFLOW_PATH/smt_solvers/cvc4
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CGRAFLOW_PATH/smt_solvers/cvc4

export PATH=$PATH:$CGRAFLOW_PATH/smt_solvers/monosat
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CGRAFLOW_PATH/smt_solvers/monosat

export PATH=$PATH:$CGRAFLOW_PATH/smt_solvers/z3/bin/
export PYTHONPATH=$PYTHONPATH:$CGRAFLOW_PATH/smt_solvers/z3/bin/python/
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CGRAFLOW_PATH/smt_solvers/z3/bin

export PYTHONPATH=$PYTHONPATH:$CGRAFLOW_PATH/smt_solvers/boolector
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CGRAFLOW_PATH/smt_solvers/boolector

export CC=gcc-4.9 
export CXX=g++-4.9 
#export CGRA_SIZE=8x8
