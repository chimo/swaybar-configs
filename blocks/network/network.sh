#!/bin/sh

# TODO: Some more testing is required to handle multiple scenarios
#       (disconnected, wired vs. wifi, multiple interfaces, etc.)

# https://stackoverflow.com/a/15798024
get_wlan_quality() (
    interface_name="${1}"
    signal=$(
        iw dev "${interface_name}" station dump \
            | grep 'signal:' \
            | cut -d "" -f3 \
            | cut -d " " -f1
    )

    if [ "${signal}" -le -100 ]; then
        quality="0"
    elif [ "${signal}" -ge -50 ]; then
        quality="100"
    else
        quality=$(echo "2 * (${signal} + 100)" | bc)
    fi

    echo "${quality}%"
)


get_interface_name() (
    # Get the default device
    ip r | grep default | awk '/default/ {print $5}'
)


is_interface_wireless() (
    interface_name="${1}"
    is_wireless=0

    if [ -d "/sys/class/net/${interface_name}/wireless" ]; then
        is_wireless=1
    fi

    echo "${is_wireless}"
)


main() (
    interface_name=$(get_interface_name)
    is_wireless=$(is_interface_wireless "${interface_name}")

    if [ "${is_wireless}" -eq 1 ]; then
        wlan_ssid=$(
            iw dev "${interface_name}" link \
                | grep SSID \
                | cut -d " " -f2
        )

        wlan_quality=$(get_wlan_quality "${interface_name}")
    fi

    lan_ip=$(
        ip -br -4 addr list dev "${interface_name}" \
            | awk '{print $3}' \
            | cut -d/ -f1
    )

    wan_ip=$(wget -O- -q "${IP_ENDPOINT}")

    if [ "${is_wireless}" -eq 1 ]; then
        output="${wlan_quality} (${wlan_ssid})"
    fi

    output="${output} ${lan_ip} / ${wan_ip}"

    printf "\xEF\x87\xAB %s" "${output}"
)


main

