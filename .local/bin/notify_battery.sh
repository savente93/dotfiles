#!/bin/bash

WARNING_LEVEL=15
CRITICAL_LEVEL=10
SHUTDOWN_LEVEL=5
LOW_FILE=/tmp/batterylow
CRITICAL_FILE=/tmp/batterycritical

export XDG_RUNTIME_DIR="/run/user/1000"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

# thank you arch wiki https://wiki.archlinux.org/title/Laptop
BATTERY_DISCHARGING=$(acpi -b | awk -F'[,:%]' '{print $2}' | grep -c "Discharging")
BATTERY_LEVEL=$(acpi -b | awk -F'[,:%]' '{print $3}')

# If charging, reset notification state
if [[ $BATTERY_DISCHARGING -eq 0 ]]; then
	rm -f "$LOW_FILE" "$CRITICAL_FILE"
	exit 0
fi

if ((BATTERY_LEVEL <= SHUTDOWN_LEVEL)); then
	logger "Battery monitor: Critical threshold reached. Hibernating."
	systemctl hibernate
	exit 0
fi

if ((BATTERY_LEVEL <= CRITICAL_LEVEL)) && [[ ! -f $CRITICAL_FILE ]]; then
	touch "$CRITICAL_FILE"
	notify-send "Battery Critical" \
		"The computer will hibernate soon." \
		-u critical -i "battery-alert" -r 9991 -c battery
	exit 0
fi

if ((BATTERY_LEVEL <= WARNING_LEVEL)) && [[ ! -f $LOW_FILE ]]; then
	notify-send "Low Battery" \
		"${BATTERY_LEVEL}% remaining." \
		-u critical -i "battery-alert" -r 9991 -c battery
	touch "$LOW_FILE"
fi
