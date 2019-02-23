#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.

# this uses that this script is in the scripts folder to set CGRAFlow path
SCRIPT_PATH=`realpath "$0"`
export CGRAFLOW_PATH=$(dirname "$(dirname "${SCRIPT_PATH}")" )
echo ${CGRAFLOW_PATH}

source setenv.sh

### Note that below are sections from install.sh ###

#halide
export LLVM_VERSION=3.7.1
export BUILD_SYSTEM=MAKE
export CXX_=g++-4.9
export CC_=gcc-4.9
export COREIRCONFIG="g++-4.9";

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

# get the root folder
export COREIR=${CGRAFLOW_PATH}/coreir
export LD_LIBRARY_PATH=$COREIR/lib:$LD_LIBRARY_PATH

pip install delegator.py
python scripts/repo_manager.py                                                  \
    --halide                      cleanup_codegen                               \
    --halide-remote               github.com/StanfordAHA/Halide-to-Hardware.git \
                                                                                \
    --coreir                      jeff_fp                                       \
    --coreir-remote               github.com/rdaly525/coreir.git                \
                                                                                \
    --pycoreir                    master                                        \
    --pycoreir-remote             github.com/leonardt/pycoreir.git              \
                                                                                \
    --mapper                      new_coreir_lib                                \
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


# setup halide env vars
source Halide-to-Hardware/test/scripts/before_install_travis.sh

pip install -e pycoreir

# add mapper to ld path
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CGRAFLOW_PATH/CGRAMapper/lib/"

# get the halide release
cd Halide-to-Hardware
curl -s https://api.github.com/repos/StanfordAHA/Halide-to-Hardware/releases/latest?access_token=$GITHUB_TOKEN | grep browser_download_url | cut -d '"' -f 4 | wget -qi -
tar zxvf halide_distrib.tgz
ls distrib
cd ../

date
export LLVM_CONFIG=/usr/bin/llvm-config-5.0
export LLVM_DIR=/usr/lib/llvm-5.0/cmake
export CLANG=/usr/bin/clang-5.0
