#!/usr/bin/env bash
# Toggle hyprsunset (blue light filter) on/off

if pidof hyprsunset > /dev/null; then
    pkill hyprsunset
else
    hyprsunset -t 4500 &
fi
