
function wifi
    nmcli d wifi connect -a "$(nmcli -f SSID d wifi list | sort | uniq | grep -v -F -e 'SSID' -e '--' | string trim | fzf --header "Please select a wifi network")"
end
