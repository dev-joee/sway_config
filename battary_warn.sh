#!/bin/bash

BATTERY_PATH="/sys/class/power_supply/BAT0/capacity"

notified20=0
notified10=0

while true; do
    LEVEL=$(cat "$BATTERY_PATH")

    # Reset flags if battery goes above 20 (charging)
    if [ "$LEVEL" -gt 20 ]; then
        notified20=0
        notified10=0
    fi

    if [ "$LEVEL" -le 20 ] && [ "$LEVEL" -gt 10 ] && [ $notified20 -eq 0 ]; then
        notify-send -u normal "🔋 Battery Warning" "Battery at ${LEVEL}%"
        notified20=1
    fi

    if [ "$LEVEL" -le 10 ] && [ $notified10 -eq 0 ]; then
        notify-send -u critical "⚠️ Battery Critical" "Battery at ${LEVEL}%! Plug in now!"
        notified10=1
    fi

    sleep 60
done
