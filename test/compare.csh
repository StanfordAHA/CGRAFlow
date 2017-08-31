#!/bin/csh -f

# Usage:
#   compare.csh <filename> <diff-command>
#
# Examples:
#   compare.csh build/pointwise_design_top.json cmp
#   compare.csh build/pointwise_design_top.json diff
#   compare.csh build/pointwise_design_top.json topo


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

echo "GOLD-COMPARE '$newfile' to '$goldfile'"

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

