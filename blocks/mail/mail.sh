#!/bin/sh -eu

main() (
    nb=$(find "${NEW_MAIL_FOLDER}" -type f | grep -vEc ',[^,]*S[^,]*$')

    if [ "${nb}" -gt 0 ]; then
        echo "M: ${nb}"
    fi
)

main

