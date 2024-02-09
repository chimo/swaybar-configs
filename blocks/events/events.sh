#!/bin/sh -eu

action="${1-}"

if [ "${action}" = "--click" ]; then
    foot -- sh -c 'khal.sh calendar today; read -r -s'
else
    events=$(khal.sh list -a personal today today)
    bdays=$(khal.sh list -a contact_birthdays today today)
    output=""

    if [ -n "${events}" ]; then
        output="${output}\xEF\x81\xB3"
    fi

    if [ -n "${bdays}" ]; then
        output="${output} \xEF\x87\xBD"
    fi

    printf "%b" "${output}"
fi

