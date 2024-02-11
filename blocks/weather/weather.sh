#!/bin/sh -eu

get_weather() (
    lon="${1}"
    lat="${2}"

    wget -O- --header "Secret: ${WEATHER_SECRET}" \
        "${WEATHER_ENDPOINT}/?lon=${lon}&lat=${lat}" -q
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


outdoors() (
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
        "Clear")
            icon="\xEF\x86\x86" # Moon
            ;;
        "Mainly Sunny"|"Sunny")
            icon="\xEF\x86\x85" # Sun
            ;;
        "Mostly Cloudy"|"Cloudy")
            icon="\xEF\x83\x82" # Cloud
            ;;
        "Partly Cloudy"|"Mainly Clear") # TODO: sun/moon should be based on sunrise/sunset times
            if [ "$(date +%H)" -lt 20 ]; then
                icon="\xEF\x9B\x84" # Sun cloud
            else
                icon="\xEF\x9B\x83" # Moon cloud
            fi
            ;;
        "Thunderstorm with rainshowers")
            icon="\xEF\x9D\xAC"
            ;;
        "Light Rain"|"Light Drizzle"|"Light Rainshower")
            icon="\xEF\x9C\xBD"
            ;;
        "Rainshower")
            if [ "$(date +%H)" -lt 20 ]; then
                icon="\xEF\x9D\x83" # Sun rain
            else
                icon="\xEF\x9C\xBC" # Moon rain
            fi
            ;;
    esac

    # Icons before text when an icon is present.
    if [ -z "${icon-}" ]; then
        out="${temperature}°, ${humidity}%"

        # Turns out "condition" isn't always there
        if [ -n "${condition}" ]; then
            out="${out}, ${condition}"
        fi

        echo "${out}"
    else
        printf "%b %s°, %s%%" "${icon}" "${temperature}" "${humidity}"
    fi
)


indoors() (
    json=$(
        wget -O- --header "Secret: ${INDOORS_SECRET}" \
            "${INDOORS_ENDPOINT}" -q
    )

    temp=$(_extract "${json}" 6 | cut -d "." -f1)
    humidity=$(_extract "${json}" 7)

    printf "%b %s, %s%%" "\xEF\x80\x95" "${temp}°" "${humidity}"
)


main() (
    coords="${1-}"

    # If coords weren't provided as args, get them from the "coordinates.sh"
    # block
    if [ -z "${coords}" ]; then
        # Define some paths
        main_dir=$(dirname -- "$( readlink -f -- "$0"; )")
        libs_dir="${main_dir}/../../libs"

        coords=$("${libs_dir}/run_block.sh" -b "coordinates.sh" -c "3600" -p "plain")
    fi

    weather=$(outdoors "${coords}")
    house_temp=$(indoors)

    echo "${weather} ${house_temp}"
)


main "${@}"

