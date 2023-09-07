#!/bin/sh -e

get_token() (
    endpoint="https://rss.chromic.org/api/greader.php/accounts/ClientLogin"
    post_data="Email=chimo&Passwd=${RSS_API_KEY}"

    response=$(wget -O- -q --post-data "${post_data}" "${endpoint}")
    auth=$(echo "${response}" | grep "Auth")
    token="${auth#*=}"

    echo "${token}"
)


get_unread_count() (
    token="${1}"
    header="Authorization:GoogleLogin auth=${token}"
    endpoint='https://rss.chromic.org/api/greader.php/reader/api/0/unread-count?output=json'

    response=$(wget -O- -q --header "${header}" "${endpoint}")

    echo "${response}" | cut -d, -f1 | cut -d: -f2
)


main() (
    token=$(get_token)
    unread_count=$(get_unread_count "${token}")

    if [ "${unread_count}" -gt 0 ]; then
        echo "rss: ${unread_count}"
    fi
)


main

