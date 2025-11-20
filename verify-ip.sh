#!/usr/bin/env bash

HOSTS_FILE=${1:-"$HOME/etc/hosts"}

verify_IP() {
    local host="$1"
    local expected_ip="$2"
    if [[ $host == "localhost" && $expected_ip == "::1" ]]; then
        return 0
    fi

    local resolved_ip
    resolved_ip=$(nslookup "$host" | grep Name -a1 | cut -d ':' -f2)
    set -- $resolved_ip
    # echo $2
    resolved_ip=$2

    if [[ -z "$resolved_ip" ]]; then
        printf 'nslookup fail for %s\n' "$host" >&2
        return 2
    fi

    if [[ "$resolved_ip" != "$expected_ip" ]]; then
        printf 'Bogus IP for %s in %s/etc/hosts !\n' "$host" "$HOME"
        echo "$resolved_ip"
        echo "$expected_ip"
        return 1
    fi

    return 0
}

if ! [[ -f HOSTS_FILE ]]; then
    >&2 echo "File $HOSTS_FILE does not exist"
    exit 1
fi

any_failure=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # strip spatii
    line="${line##+([[:space:]])}"
    line="${line%%+([[:space:]])}"
    # ignore gol si comentariu
    [[ -z "$line" ]] && continue
    [[ "${line:0:1}" = "#" ]] && continue

    set -- $line
    ip="$1"
    shift
    if ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # daca nu e ipv4, papa
        continue
    fi

    for host in "$@"; do
        verify_IP "$host" "$ip"
        a_mers=$?
        if [[ $a_mers -ne 0 ]]; then
            any_failure=1
        fi
    done
done <"$HOSTS_FILE"

if [[ $any_failure -ne 0 ]]; then
    exit 1
else
    exit 0
fi

