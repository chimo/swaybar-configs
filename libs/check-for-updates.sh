#!/bin/sh -e

_apk() (
    container="${1}"
    cmd="apk update > /dev/null && apk list -u | wc -l"

    _exec "${container}" "${cmd}"
)


_apt() (
    echo "Running apt"
)


_exec() (
    container="${1}"
    cmd="${2}"

    lxc exec "${container}" -- sh -c "${cmd}"
)


# FIXME: checking the host for updates requires root privs...
check_host() (
    #apk update > /dev/null && apk list -u | wc -l

    total_host=$(apk list -u | wc -l)

    if [ "${total_host}" -gt 0 ]; then
        echo "host: ${total_host}"
    fi
)


check_containers() (
    total_updates=0
    total_containers=0

    while IFS= read -r line
    do
        updates=0

        # `line` is "container-name,container-os", lowercased
        # `name` is everything before the comma
        # `os` is everything after the comma
        line=$(echo "${line}" | tr '[:upper:]' '[:lower:]')
        name="${line%,*}"
        os="${line#*,}"

        case "${os}" in
            "alpine")
                updates=$(_apk "${name}")
                ;;
            "debian")
                updates=$(_apt "${name}")
                ;;
            *)
                echo "Unknown OS: ${os}"
                ;;
        esac

        if [ "${updates}" -gt 0 ]; then
            total_containers=$((total_containers + 1))
        fi

        total_updates=$((total_updates + updates))
    done < <(lxc list status=running -c n,config:image.os --format csv)

    if [ "${total_updates}" -gt 0 ]; then
        echo "updates: ${total_updates}"
        echo "containers: ${total_containers}"
    fi
)


main() (
    check_containers
    check_host
    #host=$(check_host)

    #echo -e "${containers}\n${host}"
    #echo "${containers}"
)


main

