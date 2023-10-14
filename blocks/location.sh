#!/bin/sh -e

get_location() (
    lon="${1}"
    lat="${2}"
    api_root="https://nominatim.openstreetmap.org/reverse"

    wget -O- -q \
        "${api_root}?lat=${lat}&lon=${lon}&format=json"
)


# FIXME: Poor `jq` replacement
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
    states_dir="${script_dir}/../states"
    blocks_dir="${script_dir}/../blocks"

    # TODO: If no coordinates, call coordinates.sh
    #       (even though this should be unlikely?)
    coords=$(cat "${states_dir}/coordinates.state")

    lon="${coords#*,}"
    lat="${coords%,*}"

    json=$(get_location "${lon}" "${lat}")

    # TODO: Open browser map instead?
    foot -- sh -c "echo ${json}; read -r -s"
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
        suburb=$(extract "${json}" "suburb")

        if [ -n "${suburb}" ]; then
            printf "\xEF\x8F\x85 %s" "${suburb}"
        fi
    fi
)


main "${@}"

