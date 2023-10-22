#!/bin/sh -e

get_token() (
    endpoint="${API_ROOT}/accounts/ClientLogin"
    post_data="Email=${USERNAME}&Passwd=${API_KEY}"

    response=$(wget -O- -q --post-data "${post_data}" "${endpoint}")
    auth=$(echo "${response}" | grep "Auth")
    token="${auth#*=}"

    echo "${token}"
)


get_unread_count() (
    token="${1}"
    header="Authorization:GoogleLogin auth=${token}"
    endpoint="${API_ROOT}/reader/api/0/unread-count?output=json"

    response=$(wget -O- -q --header "${header}" "${endpoint}")

    echo "${response}" | cut -d, -f1 | cut -d: -f2
)


check_for_new_articles() (
    token=$(get_token)
    unread_count=$(get_unread_count "${token}")

    if [ "${unread_count}" -gt 0 ]; then
        printf "\xEF\x82\x9E %s" "${unread_count}"
    fi
)


launch_reader() (
    foot -- sh -c 'TERM=tmux-256color newsboat.sh'
)


main() (
    action="${1}"

    if [ "${action}" = "--click" ]; then
        launch_reader
    else
        check_for_new_articles
    fi
)


main "${@}"

