#!/bin/sh -eu

# Define some paths
main_dir=$(dirname -- "$( readlink -f -- "$0"; )")
blocks_dir="${main_dir}/../blocks"
states_dir="${main_dir}/../states"

mkdir -p "${states_dir}"

usage() (
    message=""
    newline="
"

    while IFS= read -r line
    do
        message="${message}${line}${newline}"
    done <<EOF
Usage: ${0} -b <block> [-c <cooldown>] [-p <json|plain>]

options:
-b      the block to run (ex: datetime.sh)
-c      cooldown value in seconds. Defaults to block's config value
-p      protocol ("json" or "plain"). Defaults to "json".
EOF

    echo "${message}" 1>&2
    exit 1
)


argparse() (
    block=""
    cooldown="-1"
    protocol="json"

    while getopts ':b:c:p:' opt; do
        case $opt in
            b)
                block="${OPTARG}"
                ;;
            c)
                cooldown="${OPTARG}"
                ;;
            p)
                protocol="${OPTARG}"

                [ "${protocol}" = "json" ] \
                    || [ "${protocol}" = "plain" ] \
                    || usage
                ;;
            *)
                usage
                ;;
        esac
    done

    shift "$((OPTIND - 1))"

    if [ "${block}" = "" ]; then
        usage
    fi

    main "${block}" "${protocol}" "${cooldown}" "${@}"
)


run() (
    filename="${1}"
    cooldown="${2}"
    protocol="${3}"
    shift 3

    script_dirname=$(basename "${filename}" ".sh")
    script_dir="${blocks_dir}/${script_dirname}"
    script="${script_dir}/${filename}"
    envfile="${script_dir}/.env"
    statefile="${states_dir}/${filename%.*}".state

    if [ ! -e "${script}" ]; then
        echo "${script}: No such file"
        return 1
    fi

    if [ "${cooldown}" -eq 0 ]; then
        out=$(${script} "${@}")
    elif [ "${cooldown}" -eq -1 ]; then
        # Cache-busting implies running in the foreground
        if [ -e "${envfile}" ]; then
            . "${envfile}"
        fi

        out=$(${script} "${@}" | tee "${statefile}")
    else
        # Get last executed time
        if [ -f "${statefile}" ]; then
            last_run=$(stat -c %Y "${statefile}")
        else
            echo "" > "${statefile}"
            last_run=0
        fi

        next_run=$((last_run + cooldown))
        now=$(date +'%s')

        out=$(cat "${statefile}")

        # If the cooldown has expired, run the command so we get updated data
        # on the next run
        if [ "${now}" -gt "${next_run}" ]; then
            (
                if [ -e "${envfile}" ]; then
                    . "${envfile}"
                fi

                ${script} "${@}" > "${statefile}"
            )&
        fi
    fi

    if [ -n "${out-}" ]; then
        if [ "${protocol}" = "plain" ]; then
            echo "${out}"
        else
            printf '{"full_text": "%s", "name": "%s", "instance": "%s"}\n' \
                "${out}" "${filename}" "${filename}"
        fi
    fi
)


main() (
    block="${1}"
    protocol="${2}"
    cooldown="${3}"
    shift 3

    run "${block}" "${cooldown}" "${protocol}" "${@}"
)


argparse "${@}"

