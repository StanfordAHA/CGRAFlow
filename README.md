# CGRAFlow [![Build Status](https://travis-ci.org/StanfordAHA/CGRAFlow.svg?branch=master)](https://travis-ci.org/StanfordAHA/CGRAFlow)
Integration test for entire CGRA flow

# Local Setup
## Ubuntu
**NOTE**: All these commands assume you are in the root directory of the
CGRAFlow repo. Ideally this wouldn't be the case, please feel free to submit a
patch to resolve these issues.

Install dependencies
```
source scripts/setenv.sh
./scripts/install_machine_deps.sh
./scripts/install_locally.sh
```

Setup your environment (you'll need to do this any time you start a new shell),
note that this script expects an environment variable `CGRAFLOW_PATH` that
points to the directory where `install.sh` was run (typically something like
`export CGRAFLOW_PATH=$HOME/CGRAFlow`).
```bash
source scripts/setenv.sh
```

Note you'll need to explicitly set the CC and CXX variables for make to the right version of GCC
```
make CC=gcc-4.9 CXX=g++-4.9 CGRA_SIZE=8x8 build/pointwise.correct.txt
```

## Kiwi
Running the following commands will set all needed environment variables and 
```
git clone https://github.com/StanfordAHA/CGRAFlow.git
bash
source scripts/kiwi_setenv.sh
source scripts/install_locally.sh
```

Now you should be able to run the tests
```
source scripts/kiwi_setenv.sh
make cgra_pnr_tests
```


