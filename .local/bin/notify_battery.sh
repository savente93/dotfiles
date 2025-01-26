#!/bin/sh

# thanks to @ericmurphyxyz
# Send a notification if the laptop battery is either low or is fully charged.

# Battery percentage at which to notify
WARNING_LEVEL=20
CRITICAL_LEVEL=10
BATTERY_DISCHARGING=$(acpi -b | grep "Battery 0" | grep -c "Discharging")
BATTERY_LEVEL=$(acpi -b | grep "Battery 0" | grep -P -o '[0-9]+(?=%)')

# Use files to store whether we've shown a notification or not (to prevent multiple notifications)
EMPTY_FILE=/tmp/batteryempty
CRITICAL_FILE=/tmp/batterycritical

# Reset notifications if the computer is charging/discharging
if [ "$BATTERY_DISCHARGING" -eq 0 ]; then
	if [ -f $EMPTY_FILE ]; then
		rm $EMPTY_FILE
	fi
	if [ -f $CRITICAL_FILE ]; then
		rm $CRITICAL_FILE
	fi
fi

# If the battery is low and is not charging (and has not shown notification yet)
if [ "$BATTERY_LEVEL" -le $WARNING_LEVEL ] && [ "$BATTERY_DISCHARGING" -eq 1 ] && [ ! -f $EMPTY_FILE ]; then
	notify-send "Low Battery" "${BATTERY_LEVEL}% of battery remaining." -u critical -i "battery-alert" -r 9991 -c battery
	touch $EMPTY_FILE
	# If the battery is critical and is not charging (and has not shown notification yet)
elif [ "$BATTERY_LEVEL" -le $CRITICAL_LEVEL ] && [ "$BATTERY_DISCHARGING" -eq 1 ] && [ ! -f $CRITICAL_FILE ]; then
	notify-send "Battery Critical" "The computer will shutdown soon." -u critical -i "battery-alert" -r 9991 -c battery
	touch $CRITICAL_FILE
fi
