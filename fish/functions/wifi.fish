
function wifi()
    nmcli d wifi connect -a "$(nmcli -f SSID d wifi list | sort | uniq | grep -v SSID | xargs | fzf --header "Please select a wifi network")"
end
