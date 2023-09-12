#!/bin/sh -e

_apk() (
    container="${1}"
    cmd="apk list -u | wc -l"

    _exec "${container}" "${cmd}"
)


_apt() (
    # TODO: finish this if/when I have apt-based containers
    echo "apt: To be implemented..."
)


_exec() (
    container="${1}"
    cmd="${2}"

    lxc exec "${container}" -- sh -c "${cmd}" < /dev/null
)


check_host() (
    total_host=$(apk list -u | wc -l)

    if [ "${total_host}" -gt 0 ]; then
        echo "host: ${total_host}"
    fi
)


check_containers() (
    total_updates=0
    total_containers=0
    containers=$(lxc list status=running -c n,config:image.os --format csv)

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
    done<<EOF
$containers
EOF

    if [ "${total_updates}" -gt 0 ]; then
        echo "updates: ${total_updates}"
        echo "containers: ${total_containers}"
    fi
)


main() (
    check_containers
    check_host
)


main

