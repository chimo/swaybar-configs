#!/bin/sh -e

# TODO: split os-specific things into their own files

get_container_version() (
    container="${1}"
    cmd="grep 'VERSION_ID=' /etc/os-release | grep -oE '[0-9]+\.[0-9]+'"

    container_os_version=$(
        lxc exec "${container}" -- sh -c "${cmd}" < /dev/null
    )

    echo "${container_os_version}"
)


check_dist_upgrade() (
    container="${1}"
    latest_alpine_version="${2}"

    needs_dist_upgrade=0

    # Get container alpine version
    container_os_version=$(get_container_version "${container}")

    if [ 1 -eq "$(echo "${latest_alpine_version} > ${container_os_version}" | bc)" ]; then
        needs_dist_upgrade=1
    fi

    echo "${needs_dist_upgrade}"
)


_apk() (
    container="${1}"

    cmd="apk -q update && apk list -u | wc -l"

    _exec "${container}" "${cmd}"
)


get_latest_alpine_version() (
    # https://stackoverflow.com/a/12704727
    git -c 'versionsort.suffix=-' \
        ls-remote --exit-code --refs --sort='version:refname' \
        --tags https://git.alpinelinux.org/aports '*.*.*' \
        | grep -vE '[0-9]+\.[0-9]+_rc' \
        | tail -n 1 \
        | cut -d '/' -f3 \
        | grep -oE '[0-9]+\.[0-9]+'
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
        printf "%b %s" "\xEF\x84\x89" "${total_host}"
    fi
)


check_containers() (
    latest_alpine_version=""
    total_containers=0
    total_dist_upgrades=0
    total_updates=0
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
            "alpine"|"alpinelinux")
                if [ "${latest_alpine_version}" = "" ]; then
                    latest_alpine_version=$(get_latest_alpine_version)
                fi

                needs_dist_upgrade=$(check_dist_upgrade "${name}" "${latest_alpine_version}")

                updates=$(_apk "${name}" "${latest_alpine_version}")
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

        total_dist_upgrades=$((total_dist_upgrades + needs_dist_upgrade))
        total_updates=$((total_updates + updates))
    done<<EOF
$containers
EOF

    if [ "${total_updates}" -gt 0 ]; then
        printf "%b %s, %b %s" "\xEF\x81\xA2" "${total_updates}" "\xEF\x91\xA6" "${total_containers}"
    fi

    if [ "${total_dist_upgrades}" -gt 0 ]; then
        printf "%b %s" "\xEE\x93\x82" "${total_dist_upgrades}"
    fi
)


main() (
    check_containers
    check_host
)


main

