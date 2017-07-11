#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# This script assumes that the current working directory
# is the root of the repository
if [ ! -f ./.travis.yml ]; then
  echo "This script must be run from the root of the repository"
  exit 1
fi

if [[ $# -ne 2 ]]; then
    echo "invalid number of parameters"
    echo "Usage: ./testflow.sh <input_image> <app_name>"
    exit 1
fi

INPUT_IMAGE=$1
APP_NAME=$2
TESTIMAGE_PATH="tools/gen_testimage"
HALIDEAPP_PATH="Halide_CoreIR/apps/coreir_examples"

# Create image and copy to app folder
make -C $TESTIMAGE_PATH $INPUT_IMAGE
cp ${TESTIMAGE_PATH}/input.png ${HALIDEAPP_PATH}/${APP_NAME}/input.png

# Run app
make build/${APP_NAME}.correct.txt
