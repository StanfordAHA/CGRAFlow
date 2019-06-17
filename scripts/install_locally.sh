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
    wget -q https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh;
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
    --halide                      2058a2e1a1c5e2b01c3cd8c77c760b24d38feaaf      \
    --halide-remote               github.com/StanfordAHA/Halide-to-Hardware.git \
                                                                                \
    --coreir                      ffab82dbe85afeb55842d4ad3a21a5a06669d39b      \
    --coreir-remote               github.com/rdaly525/coreir.git                \
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


# 4 not good no more, move to eight
# # get the halide release
# cd Halide-to-Hardware
# wget https://github.com/StanfordAHA/Halide-to-Hardware/releases/download/v0.0.4/halide_distrib.tgz
# tar zxvf halide_distrib.tgz

# I give up. someone else can try it.
# export RELEASE_ADDR=https://api.github.com/repos/StanfordAHA/Halide-to-Hardware/releases/latest
# curl -X GET -u $GITHUB_TOKEN:x-oauth-basic ${RELEASE_ADDR} | grep browser_download_url | cut -d '"' -f 5 | wget -qi -
cd Halide-to-Hardware
wget -q https://github.com/StanfordAHA/Halide-to-Hardware/releases/download/v0.0.4/halide_distrib.tgz
tar zxf halide_distrib.tgz

ls distrib
cd ../



date
