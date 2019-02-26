#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.

echo ${CGRAFLOW_PATH}

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
    --cgra-generator              remove_crop                                   \
    --cgra-generator-remote       github.com/StanfordAHA/CGRAGenerator.git      \
                                                                                \
    --test-bench-generator        master                                        \
    --test-bench-generator-remote github.com/StanfordAHA/TestBenchGenerator.git \
                                                                                \
    --cgra-pnr                    master                                        \
    --cgra-pnr-remote             github.com/Kuree/cgra_pnr.git                 \


pip install -e pycoreir

# get the halide release
cd Halide-to-Hardware
curl -s https://api.github.com/repos/StanfordAHA/Halide-to-Hardware/releases/latest?access_token=$GITHUB_TOKEN | grep browser_download_url | cut -d '"' -f 4 | wget -qi -
tar zxvf halide_distrib.tgz
ls distrib
cd ../

date
