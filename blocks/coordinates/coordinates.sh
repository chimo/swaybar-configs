#!/bin/sh -eu

get_coordinates() (
    wget -O- --header "Secret: ${COORDINATES_SECRET}" \
        "${COORDINATES_ENDPOINT}" -q
)


# This is a job for `jq` really, but I'm trying to keep things minimal and I
# control the JSON on the other end so I know what to expect.
# (inb4 future-self curses at me when I inevitably change the server response)
_extract() (
    json="${1}"
    field="${2}"

    printf '%s' "${json}" | cut -d, -f "${field}" | cut -d: -f2 | tr -d '"'
)


get_latitude() (
    json="${1}"

    res=$(_extract "${json}" 2)

    # Remove closing curly bracket
    printf '%s' "${res}" | sed 's/.$//'
)


get_longitude() (
    json="${1}"

    _extract "${json}" 1
)


main() (
    json=$(get_coordinates)

    lat=$(get_latitude "${json}")
    lon=$(get_longitude "${json}")

    echo "${lat},${lon}"
)


main

