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
set scriptdir = $scriptpath:h
if ("$scriptdir" == "$0") then
  # E.g. $0 = "script.csh' => scriptdir = "script.csh"
  set scriptdir = `pwd`
else
  # E.g. $0 = /a/b/script.csh or "../script.csh" or "./script.csh"
  # and scriptdir = "a/b" or ".." or "."
  set scriptdir = `cd $scriptdir; pwd`
endif

# Everything is relative to CGRAFlow root, which should be one level up from here
cd $scriptdir/..

# pwd
# ls test/gold

# Check for existence of gold standard
if (! -e $goldfile) then
  echo "GOLD-COMPARE $newfile:t Cannot find gold standard '$goldfile'"

else
  set cgra_info = ""
  # echo "GOLD-COMPARE $diff $goldfile $newfile"
  if ("$diff" == "bscompare") then
    set diff = "CGRAGenerator/testdir/graphcompare/bscompare.csh"
    set cgra_info = "$3"
  endif
  $diff $goldfile $newfile $cgra_info\
    && echo "GOLD-COMPARE $newfile:t ($diff) PASSED"\
    || echo "GOLD-COMPARE $newfile:t ($diff) FAILED"

endif
