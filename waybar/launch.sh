#!/bin/bash
killall waybar >/dev/null 2>&1

HOSTNAME=$(hostnamectl | grep hostname | awk '{print$3}')

waybar -c ~/.config/waybar/$HOSTNAME.jsonc >/tmp/waybar.log 2>&1 &
disown
