#!/bin/bash

polybar-msg cmd quit

xinput | grep Touchpad
export HAS_TOUCHPAD=$?

if type "xrandr"; then
	for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
		MONITOR=$m polybar main 2>&1 | tee -a /tmp/polybar.log &
		disown

	done
else
	polybar main 2>&1 | tee -a /tmp/polybar.log &
	disown
fi
