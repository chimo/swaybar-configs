#!/bin/sh -e

# Define some paths
script_dir=$(dirname -- "$( readlink -f -- "$0"; )")
libs_dir="${script_dir}/libs"
states_dir="${script_dir}/states"

# Secrets
. "${script_dir}"/.env

mkdir -p "${states_dir}"
now=$(date +'%s')

run() (
    filename="${1}"
    cooldown="${2}"
    shift; shift
    script="${libs_dir}/${filename}"
    statefile="${states_dir}/${filename%.*}".state

    # No cooldown. No need for statefile.
    # Just execute and return
    if [ -z "${cooldown}" ]; then
        ${script} "${@}"
        return
    fi

    # Get last executed time
    if [ -f "${statefile}" ]; then
        last_run=$(stat -c %Y "${statefile}")
    else
        echo "0" > "${statefile}"
        last_run=0
    fi

    next_run=$((last_run + cooldown))

    # If the cooldown has exipred, run the command
    # Otherwise, print the output of the last run
    if [ "${now}" -gt "${next_run}" ]; then
        out=$(${script} "${@}" | tee "${statefile}")
    else
        out=$(cat "${statefile}")
    fi

    if [ -n "${out}" ]; then
        echo "${out}"
    fi
)


main() (
    # Network
    # TODO: split signal quality out of this so we can run it more frequently
    run network.sh 3600

    # VPN status
    # TODO

    # Packages due for updates in running containers
    run check-for-updates.sh 3600

    # Bluetooth
    run bluetooth.sh 600

    # Battery
    if [ -n "${BATTERY_UEVENT}" ]; then
        run battery.sh 60 "${BATTERY_UEVENT}"
    fi

    # Get coordinates
    if [ -n "${LOCATION_SECRET}" ]; then
        coords=$(run coordinates.sh 3600)
    fi

    # Weather
    if [ -n "${WEATHER_SECRET}" ]; then
        run weather.sh 3600 "${coords}"
    fi

    # Audio state
    run volume.sh 5

    # Datetime
    run datetime.sh
)


format() (
    out=$(main)
    printf '%s' "${out}" | tr '\n' '|' | sed 's/|/ | /g'
)

format

