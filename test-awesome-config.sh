!/bin/bash

Xephyr -ac -br -noreset -scren 1040x768 :1 &
sleep 1
DISPLAY=:1.0 awesome -c > ~/.cache/awesome/test-stdout 2> ~/.cache/awesome/test-stderr
