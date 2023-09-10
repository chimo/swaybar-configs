#!/bin/sh

get_from_pipewire() (
    if ! output=$(wpctl get-volume @DEFAULT_AUDIO_SINK@); then
        return 1
    fi

    # Volume
    vol=$(echo "${output}" | cut -d " " -f2)
    vol_percent=$(echo "${vol} * 100" | bc | cut -d "." -f1)

    # Mute state
    muted=$(echo "${output}" | cut -d " " -f3)

    if [ "${muted}" = "[MUTED]" ]; then
        state="\xEF\x9A\xA9" # muted
    else
        state="\xEF\x80\xA8" # unmuted
    fi

    echo "${state} ${vol_percent}%"
)


main() (
    vol=$(get_from_pipewire)

    printf "%b" "${vol}"
)


main

