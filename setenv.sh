source CGRAFlowPy3Env/bin/activate
export LLVM_CONFIG=`pwd`/llvm/bin/llvm-config
export CLANG=`pwd`/llvm/bin/clang
export PYTHONPATH=$PYTHONPATH:`pwd`/smt-switch
export COREIR=`pwd`/coreir
export LD_LIBRARY_PATH=$COREIR/lib:$LD_LIBRARY_PATH

export PYTHONPATH=$PYTHONPATH:`pwd`/smt_solvers/cvc4
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`pwd`/smt_solvers/cvc4

export PATH=$PATH:`pwd`/smt_solvers/monosat
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`pwd`/smt_solvers/monosat

export PATH=$PATH:`pwd`/smt_solvers/z3/bin/
export PYTHONPATH=$PYTHONPATH:`pwd`/smt_solvers/z3/bin/python/
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`pwd`/smt_solvers/z3/bin

export PYTHONPATH=$PYTHONPATH:`pwd`/smt_solvers/boolector
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`pwd`/smt_solvers/boolector

export CC=gcc-4.9 
export CXX=g++-4.9 
#export CGRA_SIZE=8x8
