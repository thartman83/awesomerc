#!/bin/bash

Xephyr -ac -br -noreset -screen 1040x768 :1 &
sleep 1
DISPLAY=:1.0 awesome -c rc.lua > ~/.cache/awesome/test-stdout 2> ~/.cache/awesome/test-stderr
