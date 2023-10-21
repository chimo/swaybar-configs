#!/bin/sh -e

get_battery_info() (
    battery_uevent="${1}"
    bat_info=$(cat "${battery_uevent}")
    bat_state=$(echo "$bat_info" | grep STATUS | cut -d= -f2)
    bat_full=$(echo "$bat_info" | grep POWER_SUPPLY_CHARGE_FULL= | cut -d= -f2)
    bat_now=$(echo "$bat_info" | grep POWER_SUPPLY_CHARGE_NOW | cut -d= -f2)
    bat_percent=$(echo "scale=2; $bat_now/$bat_full*100" | bc | cut -d. -f1)

    if [ "${bat_state}" = "Discharging" ]; then
        icon="\xEF\x89\x81" # Battery
    else
        icon="\xEF\x83\xA7" # Bolt
    fi

    printf "%b %s%%" "${icon}" "${bat_percent}"
)

main() (
    battery_uevent="${BATTERY_UEVENT}"
    get_battery_info "${battery_uevent}"
)

main "${@}"

