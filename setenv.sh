export PATH="$HOME/miniconda/bin:$PATH"
export LLVM_CONFIG=$CGRAFLOW_PATH/llvm/bin/llvm-config
export CLANG=$CGRAFLOW_PATH/llvm/bin/clang
export PYTHONPATH=$PYTHONPATH:$CGRAFLOW_PATH/smt-switch
export COREIR=$CGRAFLOW_PATH/coreir
export LD_LIBRARY_PATH=$COREIR/lib:$LD_LIBRARY_PATH

export SMT_SOLVER_PATH=$CGRAFLOW_PATH/smt-pnr/smt_solvers  # used by set_env_for_solvers.sh
source $CGRAFLOW_PATH/smt-pnr/util/set_env_for_solvers.sh

export CC=gcc-4.9
export CXX=g++-4.9
#export CGRA_SIZE=8x8
