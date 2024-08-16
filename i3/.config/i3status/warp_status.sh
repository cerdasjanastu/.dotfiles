#!/usr/bin/env bash

# STATUS=$(warp-cli status | grep -o "Connected")
#
# if [[ "$STATUS" == "Connected" ]]; then
#     echo "warp"
# else
#     echo "not warp"
# fi

warp_status=""

check_warp() {
    STATUS=$(warp-cli status | grep -o "Connected")

    if [[ "$STATUS" == "Connected" ]]; then
        warp_status="warp"
    else
        warp_status=""
    fi
}

i3status | (read line && echo "$line" && read line && echo "$line" && read line && echo "$line" && check_warp && while :
do
    read line
    check_warp
    echo "${line} ${warp_status}" || exit 1
done)
