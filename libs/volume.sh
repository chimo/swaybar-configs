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
        muted="muted"
    else
        muted="unmuted"
    fi

    echo "${vol_percent}%,${muted}"
)


main() (
    vol=$(get_from_pipewire)

    echo "${vol}"
)


main

