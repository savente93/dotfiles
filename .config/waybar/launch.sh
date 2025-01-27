#!/bin/bash
killall waybar >/dev/null 2>&1

if upower -e | grep -q 'BAT'; then
	DEVICE_TYPE="laptop"
else
	DEVICE_TYPE="desktop"
fi

waybar -l debug -c ~/.config/waybar/"$DEVICE_TYPE".jsonc >/tmp/waybar.log 2>&1 &
disown
