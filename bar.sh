#!/bin/bash

# ==============================
# CONFIG
# ==============================
iface="wlan0"
battery_path="/sys/class/power_supply/BAT0"

# ==============================
# FUNCTIONS
# ==============================

#get_title() {
#    swaymsg -t get_tree | jq -r '.. | select(.focused? == true).name // empty'
#}

get_cpu() {
    awk -v RS="" '{printf "%.0f", ($2+$4)*100/($2+$4+$5)}' /proc/stat
}

get_ram() {
    free -m | awk '/Mem:/ {printf "%.1f %.1f", $3/1024, $2/1024}'
}

get_battery() {
    if [ -d "$battery_path" ]; then
        bat=$(cat "$battery_path/capacity")
        status=$(cat "$battery_path/status")  # Charging / Discharging / Full

        # Default icon and color
        icon="󰁹"  # battery icon
        color="#ffffff"

        # Change icon & color when charging
        if [ "$status" = "Charging" ]; then
            color="#4caf50"  # green
        else
            # Not charging
            [ "$bat" -lt 20 ] && color="#f44336"  # red if low
            [ "$bat" -ge 20 ] && color="#ffffff"  # white otherwise
        fi

        echo "$icon $bat%|$color"
    else
        echo "󰂄 N/A|#ffffff"
    fi
}

get_volume() {
    if command -v wpctl >/dev/null; then
        vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%d", $2*100}')
        wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && muted=1 || muted=0
    else
        vol=$(pamixer --get-volume)
        pamixer --get-mute && muted=1 || muted=0
    fi

    [ "$muted" = "1" ] && icon="󰖁" || icon="󰕾"

    echo "$icon $vol%"
}

get_wifi() {
    ssid=$(iw dev "$iface" link 2>/dev/null | awk -F': ' '/SSID/ {print $2}')
    if [ -n "$ssid" ]; then
        echo "󰖩 $ssid|#4caf50"
    else
        echo "󰖪 Disconnected|#f44336"
    fi
}

get_layout() {
    swaymsg -t get_inputs | jq -r \
    '.[] | select(.type=="keyboard") | .xkb_active_layout_name' | head -n1
}

get_brightness() {
    if command -v brightnessctl >/dev/null; then
        brightnessctl -m | awk -F',' '{print $4}'
    else
        # fallback (manual calculation)
        path=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n1)
        if [ -n "$path" ]; then
            current=$(cat "$path/brightness")
            max=$(cat "$path/max_brightness")
            awk -v c="$current" -v m="$max" 'BEGIN {printf "%d%%", (c/m)*100}'
        else
            echo "N/A"
        fi
    fi
}

get_running_apps() {
    swaymsg -t get_tree | jq -r '
        .. | select(.app_id? != null or .window_properties.class? != null) |
        (.app_id // .window_properties.class)
    ' | sort | uniq -c | while read count app; do
        case "$app" in
            firefox|zen|librewolf|waterfox) for i in $(seq $count); do echo -n "  "; done ;;
            discord) for i in $(seq $count); do echo -n "  "; done ;;
            code|Code) for i in $(seq $count); do echo -n "  "; done ;;
            Alacritty|kitty|foot|gnome-terminal) for i in $(seq $count); do echo -n "  "; done ;;
            google-chrome|chrome) for i in $(seq $count); do echo -n "  "; done ;;
            thunar|nautilus) for i in $(seq $count); do echo -n "  "; done ;;
            *) for i in $(seq $count); do echo -n " "; done ;;
        esac
    done
}

# ==============================
# MAIN LOOP
# ==============================

while :; do

    # title=$(get_title)
    cpu=$(get_cpu)
    read used total <<< $(get_ram)

    # Battery
    IFS="|" read bat_text bat_color <<< $(get_battery)

    # Volume
    vol_text=$(get_volume)

    # Wi-Fi
    IFS="|" read wifi_text wifi_color <<< $(get_wifi)

    # Layout
    layout=$(get_layout)

    # Brightness
    brightness=$(get_brightness)

    # Date
    date=$(date "+%a - %d %b %Y - %-I:%M %p")

    #Runnig Apps
    apps=$(get_running_apps)
    # ==============================
    # OUTPUT
    # ==============================

#    echo "<span foreground='#af7aaa'>${title}</span> | \
echo "<span foreground='#cdb444'>${date}</span> | \
<span foreground='#ff9800'>CPU ${cpu}%</span> - \
<span foreground='#2196f3'>RAM ${used}G/${total}G</span> - \
<span foreground='${bat_color}'>${bat_text}</span> - \
<span foreground='#abfacf'>󰃞 ${brightness}</span> | \
<span foreground='#ffd500'>${vol_text}</span> | \
<span foreground='${wifi_color}'>${wifi_text}</span> | \
<span foreground='#00ffff'>⌨ ${layout}</span> |  \
<span foreground='#81a2be'>${apps}</span> \
<span foreground='#ff0000' font_desc='JetBrains Mono ExtraBold 12'><b> </b></span>"

    sleep 0.5
done
