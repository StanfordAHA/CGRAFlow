#!/bin/csh -f

# Usage: compare.csh build/pointwise_design_top.json

# Find script home directory (https://stackoverflow.com/questions/2563300/
#   how-can-i-find-the-location-of-the-tcsh-shell-script-im-executing)
scriptdir=`/bin/dirname $0`       # may be relative path
scriptdir=`cd $scriptdir && pwd`  # ensure absolute path

# Go to cgraflow root dir (one level above test dir)
cd $scriptdir/..

set newfile = $1
# E.g. newfile = 'build/pointwise_design_top.json'

set goldfile = test/gold/$1:t
# E.g. goldfile = 'test/gold/pointwise_design_top.json'


echo "COMPARE '$newfile' to '$goldfile'"
echo "  It's not plugged in yet."
echo ""
