#!/bin/csh -f

# Usage:
#   compare.csh <filename> <diff-command>
#
# Examples:
#   compare.csh build/pointwise_design_top.json cmp
#   compare.csh build/pointwise_design_top.json diff
#   compare.csh build/pointwise_design_top.json topo

echo "GOLD-COMPARE '$newfile' to '$goldfile'"

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

set newfile = $1
# E.g. newfile = 'build/pointwise_design_top.json'

set goldfile = test/gold/$1:t
# E.g. goldfile = 'test/gold/pointwise_design_top.json'

# Check for existence of gold standard
if (! -e $goldfile) then
  echo "Cannot find gold standard '$goldfile'"
  echo ""
  exit

set compare = $3
echo ""
set echo
$compare $goldfile $newfile\
  && echo "GOLD-COMPARE '$newfile' to '$goldfile' PASSED"\\
  || echo "GOLD-COMPARE '$newfile' to '$goldfile' FAILED"
unset echo
echo ""

