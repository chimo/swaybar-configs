#!/bin/sh -eu

# Define some paths
main_dir=$(dirname -- "$( readlink -f -- "$0"; )")
blocks_dir="${main_dir}/blocks"
states_dir="${main_dir}/states"

mkdir -p "${states_dir}"

usage() { echo "Usage: ${0} -b <block> [-p <json|plain>]" 1>&2; exit 1; }


argparse() (
    block=""
    protocol="json"

    while getopts ':p:b:' opt; do
        case $opt in
            p)
                protocol="${OPTARG}"

                [ "${protocol}" = "json" ] \
                    || [ "${protocol}" = "plain" ] \
                    || usage
                ;;
            b)
                block="${OPTARG}"
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

    main "${block}" "${protocol}"
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
        (
            if [ -e "${envfile}" ]; then
                . "${envfile}"
            fi

            ${script} "${@}" > "${statefile}"
        )&
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
            printf '{"full_text": "%s", "name": "%s", "instance": "%s"}' "${out}" "${filename}" "${filename}"
            echo "" # FIXME: newline...
        fi
    fi
)


main() (
    block="${1}"
    protocol="${2}"
    cooldown="-1" # A value of "-1" for cooldown forces a refresh

    run "${block}" "${cooldown}" "${protocol}"
)


argparse "${@}"

