#!/usr/bin/env bash

STATUS=$(warp-cli status | grep "Connected" | awk '{print $3}')

if [ "$STATUS" == "Connected" ]; then
    warp-cli disconnect
else
    warp-cli connect
fi
