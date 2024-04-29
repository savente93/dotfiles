#!/bin/bash
killall waybar >/dev/null 2>&1

HOSTNAME=$(hostnamectl | grep hostname | awk '{print$3}')

waybar -c ~/.config/waybar/$HOSTNAME.jsonc 2>&1 >/tmp/waybar.log &
disown
