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

    if [ -z "${coords}" ]; then
        # Fallback to capital if location is nil
        lon="-75.695"
        lat="45.424722"
    else
        lon="${coords#*,}"
        lat="${coords%,*}"
    fi

    json=$(get_weather "${lon}" "${lat}")

    temperature=$(get_temperature "${json}")
    humidity=$(get_humidity "${json}")
    condition=$(get_condition "${json}")


    case "${condition}" in
        "Mostly Cloudy")
            icon="\xEF\x83\x82" # Cloud
            ;;
        "Partly Cloudy"|"Mainly Clear") # TODO: sun/moon should be based on sunrise/sunset times
            if [ "$(date +%H)" -lt 20 ]; then
                icon="\xEF\x9B\x84" # Sun cloud
            else
                icon="\xEF\x9B\x83" # Moon cloud
            fi
            ;;
    esac

    # Icons before text when an icon is present.
    if [ -z "${icon}" ]; then
        echo "${temperature}°, ${humidity}%, ${condition}"
    else
        printf "%b %s°, %s%%" "${icon}" "${temperature}" "${humidity}"
    fi
)


main "${@}"

