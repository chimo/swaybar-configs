#!/bin/sh -eu

action="${1-}"

if [ "${action}" = "--click" ]; then
    foot -- sh -c 'cal -y; read -r -s'
else
    date +'%Y-%m-%d %H:%M:%S %Z'
fi

