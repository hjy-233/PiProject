#!/usr/bin/env bash

set -euo pipefail

data_root="${PROJECT_DEPLOYER_DATA_ROOT:-$HOME/.local/share/project-deployer}"
credentials_directory="$data_root/credentials"
known_hosts_file="$data_root/known_hosts"

usage() {
    echo "Usage: $0 credential install <id> <private-key-file>" >&2
    echo "       $0 credential remove <id>" >&2
    echo "       $0 credential list" >&2
    echo "       $0 known-host add <host>" >&2
    echo "       $0 known-host remove <host>" >&2
    echo "       $0 known-host list" >&2
    exit 64
}

validate_identifier() {
    if [[ ! "$1" =~ ^[a-z0-9][a-z0-9._-]{0,63}$ ]]; then
        echo "Invalid credential id: $1" >&2
        exit 64
    fi
}

install -d -m 700 "$credentials_directory"
touch "$known_hosts_file"
chmod 600 "$known_hosts_file"

category="${1:-}"
action="${2:-}"
case "$category:$action" in
credential:install)
    [[ $# -eq 4 ]] || usage
    validate_identifier "$3"
    [[ -f "$4" ]] || { echo "Private key file does not exist: $4" >&2; exit 66; }
    ssh-keygen -y -f "$4" >/dev/null
    install -m 600 "$4" "$credentials_directory/$3"
    echo "Installed SSH credential: $3"
    ;;
credential:remove)
    [[ $# -eq 3 ]] || usage
    validate_identifier "$3"
    [[ -f "$credentials_directory/$3" ]] || { echo "Credential does not exist: $3" >&2; exit 66; }
    rm "$credentials_directory/$3"
    echo "Removed SSH credential: $3"
    ;;
credential:list)
    [[ $# -eq 2 ]] || usage
    find "$credentials_directory" -mindepth 1 -maxdepth 1 -type f -exec basename {} \; | LC_ALL=C sort
    ;;
known-host:add)
    [[ $# -eq 3 ]] || usage
    command -v ssh-keyscan >/dev/null 2>&1 || { echo "Missing required command: ssh-keyscan" >&2; exit 69; }
    temporary_file="$(mktemp "$data_root/known-hosts.XXXXXX")"
    trap 'rm -f "$temporary_file"' EXIT
    ssh-keyscan -H -- "$3" > "$temporary_file"
    [[ -s "$temporary_file" ]] || { echo "No host key received from: $3" >&2; exit 69; }
    cat "$temporary_file" >> "$known_hosts_file"
    LC_ALL=C sort -u "$known_hosts_file" -o "$known_hosts_file"
    chmod 600 "$known_hosts_file"
    ssh-keygen -F "$3" -f "$known_hosts_file"
    echo "Verify the displayed fingerprint through a trusted channel before deployment."
    ;;
known-host:remove)
    [[ $# -eq 3 ]] || usage
    ssh-keygen -R "$3" -f "$known_hosts_file" >/dev/null
    chmod 600 "$known_hosts_file"
    echo "Removed known-host entries for: $3"
    ;;
known-host:list)
    [[ $# -eq 2 ]] || usage
    cat "$known_hosts_file"
    ;;
*)
    usage
    ;;
esac
