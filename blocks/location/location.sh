#!/bin/sh -e

get_location() (
    lon="${1}"
    lat="${2}"
    api_root="https://nominatim.openstreetmap.org/reverse"

    wget -O- -q \
        "${api_root}?lat=${lat}&lon=${lon}&format=json"
)


# Poor `jq` replacement
extract() (
    json="${1}"
    field="${2}"

    match=$(
        echo "${json}" \
            | grep -oE '"'"${field}"'":"[^"]+"' \
            | cut -d: -f2 \
            | tr -d '"'
    )

    echo "${match}"
)


handle_click() (
    script_dir=$(dirname -- "$( readlink -f -- "$0"; )")
    states_dir="${script_dir}/../../states"

    coords=$(cat "${states_dir}/coordinates.state")

    lon="${coords#*,}"
    lat="${coords%,*}"
    url="https://www.openstreetmap.org/search?query=${lon}%2C${lat}"

    qutebrowser.sh "${url}"
)


main() (
    param="${1}"

    if [ "${param}" = "--click" ]; then
        handle_click
    else
        coords="${param}"

        lon="${coords#*,}"
        lat="${coords%,*}"

        json=$(get_location "${lon}" "${lat}")
        
        location=""

        fields="
neighbourhood
suburb
        "

        for field in ${fields}
        do
            location=$(extract "$json" "${field}")

            if [ -n "${location}" ]; then
                break
            fi
        done

        if [ -n "${location}" ]; then
            printf "\xEF\x8F\x85 %s" "${location}"
        fi
    fi
)


main "${@}"

