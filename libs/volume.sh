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


# I had this from a previous non-pipewire install, so why no use it as
# fallback, I guess.
get_from_alsa() (
    # Volume
    vol=$(amixer get Master | grep "Mono: Playback")
    vol_percent=$(echo "$vol" | awk '{print $4}' | tr -d "[]")

    # Mute state
    state=$(echo "$vol" | awk '{print $6}' | tr -d "[]")

    if [ "${state}" = "off" ]; then
        muted="muted"
    else
        muted="unmuted"
    fi

    echo "${vol_percent},${muted}"
)


main() (
    if ! vol=$(get_from_pipewire); then
        vol=$(get_from_alsa)
    fi

    echo "${vol}"
)

main

