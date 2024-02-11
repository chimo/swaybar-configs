#!/bin/sh -eu

# Define some paths
main_dir=$(dirname -- "$( readlink -f -- "$0"; )")
blocks_dir="${main_dir}/blocks"
states_dir="${main_dir}/states"
libs_dir="${main_dir}/libs"

mkdir -p "${states_dir}"

run() (
    filename="${1}"
    cooldown="${2}"
    protocol="${3}"
    shift 3

    "${libs_dir}"/run_block.sh -b "${filename}" -c "${cooldown}" -p "${protocol}" "${@}"
)


run_all() (
    protocol="${1}"
    # Network
    run network.sh 3600 "${protocol}"

    # Packages due for updates in running containers
    run updates.sh 3600 "${protocol}"

    # Bluetooth
    run bluetooth.sh 600 "${protocol}"

    # Battery
    run battery.sh 60 "${protocol}"

    # Weather
    run weather.sh 3600 "${protocol}"

    # Location
    run location.sh 3600 "${protocol}"

    # RSS
    run rss.sh 3600 "${protocol}"

    # Email
    run mail.sh 300 "${protocol}"

    # Audio state
    run volume.sh 5 "${protocol}"

    # Datetime
    run datetime.sh 0 "${protocol}"

    # Event
    run events.sh 3600 "${protocol}"
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
        block_dir="${block_name%.*}"

        block_file="${blocks_dir}/${block_dir}/${block_name}"

        if [ -f "${block_file}" ]; then
            sh -c -- "${block_file} --click&"
        fi
    done
)


main() (
    protocol="plain"

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

