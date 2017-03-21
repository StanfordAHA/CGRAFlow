#!/bin/csh -f

# How to use it:
# On clone side:
#    .travistimer.csh -set
#    git add .travistimer_begin; git commit; git push
#    OR:
#    git commit -am 'commit-message'; git push
#
# In travis script .travis.yml:
#  if [[ `.travistimer.csh` == "valid" ]]; then echo VALID; fi

# 5m = 300s is NOT ENOUGH try fifteen minutes instead maybe
set nsecs = 300
set nsecs = 900

# date format for e.g. "Tue 03/21 08:11am"
set fmt = "%a %m/%d %R%P"

# date format for e.g. "08:11am"
set fmt = "%R%P"

if ("$1" == "-reset") then
  echo 0 > .travistimer_begin
  set timer_begin = `cat .travistimer_begin`
  echo "Timer reset to $timer_begin ("`date --date="@$timer_begin"`")"
  exit 0
endif

if ("$1" == "-set") then
  date +%s > .travistimer_begin
  set timer_begin = `cat .travistimer_begin`
  echo "Timer begin $timer_begin =" `date +"$fmt" --date="@$timer_begin"`
  exit 0
endif

if (! -e .travistimer_begin) then
  echo "Cannot find begin-timer file '.travistimer_begin'"
  exit 0
endif


set timer_begin = `cat .travistimer_begin`
set timer_end   = `expr $timer_begin + $nsecs`
set time_now    = `date +%s`

if ("$1" == "-v") then
  echo "timer begin: $timer_begin =" `date +"$fmt" --date="@$timer_begin"` > /dev/stderr
  echo "timer end:   $timer_end ="   `date +"$fmt" --date="@$timer_end"`   > /dev/stderr
  echo "time now:    $time_now ="    `date +"$fmt" --date="@$time_now"`    > /dev/stderr
endif

if ($time_now < $timer_end) then
  echo valid
else
  echo expired
endif
