#!/bin/sh -e

get_weather() (
    lon="${1}"
    lat="${2}"

    wget -O- --header "Secret: ${WEATHER_SECRET}" \
        "https://weather.chromic.org/?lon=${lon}&lat=${lat}" -q
)

# This is a job for `jq` really, but I'm trying to keep things minimal and I
# control the JSON on the other end so I know what to expect.
# (inb4 future-self curses at me when I inevitably change the server response)
_extract() (
    json="${1}"
    field="${2}"

    printf '%s' "${json}" | cut -d, -f "${field}" | cut -d: -f2 | tr -d '"'
)


get_condition() (
    json="${1}"

    res=$(_extract "${json}" 3)

    # Remove closing curly bracket
    printf '%s' "${res}" | sed 's/.$//'
)


get_humidity() (
    json="${1}"

    _extract "${json}" 1
)


get_temperature() (
    json="${1}"

    _extract "${json}" 2
)


main() (
    coords="${1}"

    if [ ! -z "${coords}" ]; then
        lat=$(echo "${coords}" | cut -d, -f1)
        lon=$(echo "${coords}" | cut -d, -f2)
    fi

    # Fallback to capital if location is nil
    if [ -z "${coords}" ]; then
        lat="45.424722"
        lon="-75.695"
    fi

    json=$(get_weather "${lon}" "${lat}")

    temperature=$(get_temperature "${json}")
    humidity=$(get_humidity "${json}")
    condition=$(get_condition "${json}")

    echo "${temperature}°, ${humidity}%, ${condition}"
)


main "${@}"

