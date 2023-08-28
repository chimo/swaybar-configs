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
    script="${libs_dir}/${filename}"
    statefile="${states_dir}/${filename%.*}".state

    # No cooldown. No need for statefile.
    # Just execute and return
    if [ -z "${cooldown}" ]; then
        ${script}
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
        ${script} | tee "${statefile}"
    else
        cat "${statefile}"
    fi
)


main() (
    # Network
    # TODO: split signal quality out of this so we can run it more frequently
    run network.sh 3600

    # VPN status
    # TODO

    # Audio state
    # TODO

    # Packages due for updates in running containers
    run check-for-updates.sh 3600

    # Battery
    run battery.sh 600

    # Weather
    run weather.sh 3600

    # Datetime
    run datetime.sh
)


format() (
    out=$(main)
    printf '%s' "${out}" | tr '\n' '|' | sed 's/|/ | /g'
)

format

