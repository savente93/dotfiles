killall waybar >/dev/null 2>&1

HOSTNAME=$(hostnamectl | grep hostname | awk '{print$3}')

waybar 2>&1 >/tmp/waybar.log &
disown
