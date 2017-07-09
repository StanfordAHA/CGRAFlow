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

Setup your environment (you'll need to do this any time you start a new shell)
```bash
source setenv.sh
```
**NOTE**: To exit the Python virtualenv, use the command `deactivate`. To
reactivate it, use `source CGRAFlowPy3Env/bin/activate`

Note you'll need to explicitly set the CC and CXX variables for make to the right version of GCC
```
make CC=gcc-4.9 CXX=g++-4.9 CGRA_SIZE=8x8 build/pointwise.correct.txt
```
