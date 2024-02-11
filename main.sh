#!/bin/sh -eu

# Define some paths
main_dir=$(dirname -- "$( readlink -f -- "$0"; )")
blocks_dir="${main_dir}/blocks"
states_dir="${main_dir}/states"
libs_dir="${main_dir}/libs"

mkdir -p "${states_dir}"

# https://unix.stackexchange.com/a/598047
is_integer ()
(
    case "${1#[+-]}" in
        (*[!0123456789]*) return 1 ;;
        ('')              return 1 ;;
        (*)               return 0 ;;
    esac
)


run() (
    blocks="${1}"
    protocol="${2}"

    while IFS= read -r line
    do
        block="${line%=*}"
        cooldown="${line#*=}"

        "${libs_dir}"/run_block.sh -b "${block}.sh" -c "${cooldown}" -p "${protocol}"
    done <<EOF
$blocks
EOF

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


get_block_cooldown() (
    config_file="${1}"

    while read -r line
    do
        key="${line%=*}"

        if [ "${key}" = "cooldown" ]; then
            value="${line#*=}"

            echo "${value}"
            break
        fi
    done < "${config_file}"
)


get_blocks() (
    main_config_file="${main_dir}/config"

    if [ ! -f "${main_config_file}" ]; then
        echo "Couldn't find config file: '${main_config_file}'" 1>&2
        exit 1
    fi

    while read -r block
    do
        # Skip blank lines
        if [ -z "${block}" ]; then
            continue
        fi

        cooldown=""
        block_config_file="${blocks_dir}/${block}/config"

        # Check if block has config file
        if [ -f "${block_config_file}" ]; then
            cooldown=$(get_block_cooldown "${block_config_file}")
        fi

        # Default cooldown is an hour
        # TODO: should default to an hour if the value isn't a valid int
        if ! is_integer "${cooldown}"; then
            cooldown="3600"
        fi

        echo "${block}=${cooldown}"
    done < "${main_config_file}"
)


main() (
    protocol="plain"

    if [ "${1-}" = "--json" ]; then
        protocol="json"
    fi

    if [ "${protocol}" = "json" ]; then
        send_header
    fi

    blocks=$(get_blocks)
    echo "${blocks}"

    (while true
    do
        out=$(run "${blocks}" "${protocol}")

        format "${out}" "${protocol}"

        sleep 1
    done)&

    listen
)


main "${@}"

