#!/usr/bin/bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x

# CMDs
uptime="$(uptime -p | sed -e 's/up //g')"
host=$(hostnamectl | grep Static | awk '{print $3}')

# Options
shutdown=$(echo -e "\tShutdown")
reboot=$(echo -e "\tReboot")
lock=$(echo -e "\tLock")
suspend=$(echo -e "\tSuspend")
logout=$(echo -e "\tLogout")
yes=$(echo -e "\tYes")
no=$(echo -e "\tNo")

# Rofi CMD
function rofi_cmd() {
	rofi -dmenu \
		-p "$host" \
		-mesg "Uptime: $uptime" \
		-theme ~/.config/rofi/powermenu.rasi

}

# Confirmation CMD
confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 250px;}' \
		-theme-str 'mainbox {children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5;}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme ~/.config/rofi/powermenu.rasi
}

# Ask for confirmation
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	if [[ $selected == "$yes" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			systemctl poweroff
		elif [[ $1 == '--reboot' ]]; then
			reboot
		elif [[ $1 == '--suspend' ]]; then
			mpc -q pause
			amixer set Master mute
			systemctl suspend
		elif [[ $1 == '--logout' ]]; then
			i3-msg exit
		fi
	else
		exit 0
	fi
}

# Actions
chosen="$(run_rofi)"
case "${chosen}" in
"$shutdown")
	run_cmd --shutdown
	;;
"$reboot")
	run_cmd --reboot
	;;
"$lock")
	i3lock
	;;
"$suspend")
	run_cmd --suspend
	;;
"$logout")
	run_cmd --logout
	;;
*)
	echo "Error: Invalid choice."
	;;
esac
