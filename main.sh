#!/bin/sh -e

# Define some paths
script_dir=$(dirname -- "$( readlink -f -- "$0"; )")
blocks_dir="${script_dir}/blocks"
states_dir="${script_dir}/states"

# Secrets
. "${script_dir}"/.env

mkdir -p "${states_dir}"

run() (
    filename="${1}"
    cooldown="${2}"
    protocol="${3}"
    shift; shift; shift
    script="${blocks_dir}/${filename}"
    statefile="${states_dir}/${filename%.*}".state

    if [ "${cooldown}" -eq 0 ]; then
        out=$(${script} "${@}")
    else
        # Get last executed time
        if [ -f "${statefile}" ]; then
            last_run=$(stat -c %Y "${statefile}")
        else
            echo "0" > "${statefile}"
            last_run=0
        fi

        next_run=$((last_run + cooldown))
        now=$(date +'%s')

        out=$(cat "${statefile}")

        # If the cooldown has expired, run the command
        # Otherwise, print the output of the last run
        if [ "${now}" -gt "${next_run}" ]; then
            ( ${script} "${@}" > "${statefile}" )&
        fi
    fi

    if [ -n "${out}" ]; then
        if [ "${protocol}" = "plain" ]; then
            echo "${out}"
        else
            printf '{"full_text": "%s", "name": "%s", "instance": "%s"}' "${out}" "${filename}" "${filename}"
            echo "" # FIXME: newline...
        fi
    fi
)


run_all() (
    protocol="${1}"
    # Network
    # TODO: split signal quality out of this so we can run it more frequently
    run network.sh 3600 "${protocol}"

    # VPN status
    # TODO

    # Packages due for updates in running containers
    run updates.sh 3600 "${protocol}"

    # Bluetooth
    run bluetooth.sh 600 "${protocol}"

    # Battery
    if [ -n "${BATTERY_UEVENT}" ]; then
        run battery.sh 60 "${protocol}" "${BATTERY_UEVENT}"
    fi

    # Get coordinates
    if [ -n "${LOCATION_SECRET}" ]; then
        coords=$(run coordinates.sh 3600 "plain")
    fi

    # Weather
    if [ -n "${WEATHER_SECRET}" ]; then
        run weather.sh 3600 "${protocol}" "${coords}"
    fi

    # RSS
    if [ -n "${RSS_API_KEY}" ]; then
        run rss.sh 3600 "${protocol}"
    fi

    # Email
    run mail.sh 300 "${protocol}"

    # Audio state
    run volume.sh 5 "${protocol}"

    # Datetime
    run datetime.sh 0 "${protocol}"
)


send_header() (
    header='{"version": 1,"click_events": true}'

    echo "${header}"

    # Endless array
    echo "["
    echo "[]"
)


format() (
    out="${1}"
    protocol="${2}"

    if [ "${protocol}" = "plain" ]; then
        printf '%s' "${out}" | tr '\n' '|' | sed 's/|/ | /g'
    else
        # json
        printf ',[%s]' "${out}" | tr '\n' ','
    fi
)


listen() (
    while read -r line
    do
        # FIXME: should actually parse the json
        block_name=$(echo "${line}" | awk '{print $3}' | tr -d '",')

        block_file="${blocks_dir}/${block_name}"

        if [ -f "${block_file}" ]; then
            sh -c -- "${block_file} --click&"
        fi
    done
)


main() (
    protocol="plain"

    # FIXME: getops
    if [ "${1}" = "--json" ]; then
        protocol="json"
    fi

    if [ "${protocol}" = "json" ]; then
        send_header
    fi

    (while true
    do
        out=$(run_all "${protocol}")

        format "${out}" "${protocol}"

        sleep 1
    done)&

    listen
)


main "${@}"

