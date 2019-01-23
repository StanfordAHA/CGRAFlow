# CGRAFlow [![Build Status](https://travis-ci.org/StanfordAHA/CGRAFlow.svg?branch=master)](https://travis-ci.org/StanfordAHA/CGRAFlow)
Integration test for entire CGRA flow

# Local Setup
## Ubuntu
**NOTE**: All these commands assume you are in the root directory of the
CGRAFlow repo. Ideally this wouldn't be the case, please feel free to submit a
patch to resolve these issues.

Install dependencies
```
./install.sh
```

Setup your environment (you'll need to do this any time you start a new shell),
note that this script expects an environment variable `CGRAFLOW_PATH` that
points to the directory where `install.sh` was run (typically something like
`export CGRAFLOW_PATH=$HOME/CGRAFlow`).
```bash
source setenv.sh
```

Note you'll need to explicitly set the CC and CXX variables for make to the right version of GCC
```
make CC=gcc-4.9 CXX=g++-4.9 CGRA_SIZE=8x8 build/pointwise.correct.txt
```

## Kiwi
```
git clone https://github.com/StanfordAHA/CGRAFlow.git
git checkout local_install
export CGRAFLOW_PATH="<path_to_git_directory>/CGRAFlow"
source setenv.sh
```
Remove line 57 from local_install.sh and then run it to pull in the other repos.
```
./local_install.sh
```
After this, remove the last line of Halide_CoreIR/test/scripts/install_travis.sh
Additionally, add the libraries from CGRAMapper to your LD_LIBRARY_PATH.
```
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/$CGRAFLOW_PATH/CGRAMapper/lib/"
```
Now you should be able to run the tests
```
make cgra_pnr_tests
```


