#!/bin/sh -eu

main() (
    nb=$(find ~/.local/mail/INBOX/new -type f | grep -vE ',[^,]*S[^,]*$' | wc -l)

    if [ "${nb}" -gt 0 ]; then
        echo "M: ${nb}"
    fi
)

main

