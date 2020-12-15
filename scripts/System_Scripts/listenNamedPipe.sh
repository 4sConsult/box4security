#!/usr/bin/bash
pipe=/var/lib/box4s/web.pipe
[ -p "$pipe" ] || mkfifo -m 0600 "$pipe" || exit 1
while :; do
    while read -r cmd; do
        if [ "$cmd" ]; then
            printf 'From web container got: %s ...\n' "$cmd"
            bash -c "$cmd" sh
        fi
    done <"$pipe"
done