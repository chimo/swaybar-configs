#!/bin/sh -eu

_get_devices_ids() (
    devices=$(bluetoothctl devices)

    while IFS= read -r device
    do
        echo "${device}" | cut -d ' ' -f2
    done<<EOF
$devices
EOF
)

_get_state() (
    in="${1}"

    while IFS= read -r info
    do
        state=$(echo "${info}" | grep "Connected" | cut -d " " -f2)

        if [ -n "${state}" ]; then
            break
        fi
    done<<EOF
$in
EOF

    echo "${state}"
)


_get_name() (
    in="${1}"

    while IFS= read -r info
    do
        name=$(echo "${info}" | grep "Name" | cut -d " " -f2-)

        if [ -n "${name}" ]; then
            break
        fi
    done<<EOF
$in
EOF

    echo "${name}"
)


get_connected_devices() (
    device_ids=$(_get_devices_ids)
    connected_devices=""

    while IFS= read -r device_id
    do
        device_info=$(bluetoothctl info "${device_id}" | grep -e 'Connected\|Name')
        state=$(_get_state "${device_info}")

        if [ "${state}" = "yes" ]; then
            name=$(_get_name "${device_info}")
            connected_devices=$(printf '%s\n%s' "${connected_devices}" "${name}")
        fi
    done<<EOF
$device_ids
EOF

    # Remove the first line since it'll be blank due to concatenation in the
    # while loop
    echo "${connected_devices}" | tail -n +2
)


main() (
    connected_devices=$(get_connected_devices)

    nb=$(echo "${connected_devices}" | wc -l)

    if [ "${nb}" -gt 1 ]; then
        msg="${nb} devices"
    else
        msg="${connected_devices}"
    fi

    if [ -n "${msg}" ]; then
        printf "\xEF\x8A\x94 %s" "${msg}"
    fi
)


main

