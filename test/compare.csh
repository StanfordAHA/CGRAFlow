#!/bin/csh -f

# Usage:
#   compare.csh <filename> <diff-command>
#
# Examples:
#   compare.csh build/pointwise_design_top.json cmp
#   compare.csh build/pointwise_design_top.json diff
#   compare.csh build/pointwise_design_top.json topo

set newfile = $1
# E.g. newfile = 'build/pointwise_design_top.json'

set goldfile = test/gold/$1:t
# E.g. goldfile = 'test/gold/pointwise_design_top.json'

set diff = $2

# echo "GOLD-COMPARE $diff '$newfile' '$goldfile'"

# Find script home directory
set scriptpath = "$0"
set scriptpath = $scriptpath:h
if ("$scriptpath" == "$0") then
  set scriptpath = `pwd`
  set scriptdir = `cd $scriptpath:h; pwd`
else
  set scriptdir = `cd $scriptpath/..; pwd`
endif

# Everything is relative to CGRAFlow root, which should be one level up from here
cd $scriptdir/..

# Check for existence of gold standard
if (! -e $goldfile) then
  echo "GOLD-COMPARE $newfile:t Cannot find gold standard '$goldfile'"

else
  echo $diff $goldfile $newfile
  $diff $goldfile $newfile\
    && echo "GOLD-COMPARE $newfile:t ($diff) PASSED"\\
    || echo "GOLD-COMPARE $newfile:t ($diff) FAILED"

endif
