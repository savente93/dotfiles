#!/bin/bash

polybar-msg cmd quit

HOSTNAME=$(hostnamectl | grep hostname | awk '{print$3}')

POLYBAR_MODULES='time sep date sep bluetooth sep audio '

if [ $(upower -e | grep BAT) ]; then
	POLYBAR_MODULES+=' sep battery'
fi

if [ $(nmcli device | grep ethernet | wc -l) -gt 0 ]; then
	POLYBAR_MODULES+=' sep eth'
elif [ $(nmcli device | grep wifi | wc -l) -gt 0 ]; then
	POLYBAR_MODULES+=' sep wifi'

fi

export POLYBAR_MODULES

if [ $(xinput | grep Touchpad | wc -l) -gt 0 ]; then
	HAS_TOUCHPAD=1
else
	HAS_TOUCHPAD=0
fi

export HAS_TOUCHPAD
if type "xrandr"; then
	for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
		MONITOR=$m polybar main 2>&1 | tee -a /tmp/polybar.log &
		disown

	done
else
	polybar main 2>&1 | tee -a /tmp/polybar.log &
	disown
fi
