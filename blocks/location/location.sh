#!/bin/sh -eu

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
    lon="${1}"
    lat="${2}"
    url="https://www.openstreetmap.org/search?query=${lon}%2C${lat}"

    qutebrowser.sh "${url}"
)


main() (
    param="${1-}"
    coords="" # TODO: getopts and handle [-c] <coords>

    # If coords weren't provided as args, get them from the "coordinates.sh"
    # block
    if [ -z "${coords}" ]; then
        # Define some paths
        main_dir=$(dirname -- "$( readlink -f -- "$0"; )")
        libs_dir="${main_dir}/../../libs"

        coords=$("${libs_dir}/run_block.sh" -b "coordinates.sh" -p "plain")
    fi

    lon="${coords#*,}"
    lat="${coords%,*}"

    if [ -z "${lon}" ] || [ -z "${lat}" ]; then
        echo "Invalid coords: '${coords}'" 1>&2
        exit 1
    fi

    if [ "${param}" = "--click" ]; then
        handle_click "${lon}" "${lat}"
    else
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

