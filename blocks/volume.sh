#!/bin/sh

get_from_wireplumber() (
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

    printf '%b %s%%' "${state}" "${vol_percent}"
)

handle_click() (
    script_dir=$(dirname -- "$( readlink -f -- "$0"; )")
    states_dir="${script_dir}/../states"
    
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

    get_from_wireplumber > "${states_dir}/volume.state"
)

main() (
    # FIXME: getops
    action="${1}"

    if [ "${action}" = "--click" ]; then
        handle_click
    else
        get_from_wireplumber
    fi
)


main "${@}"

