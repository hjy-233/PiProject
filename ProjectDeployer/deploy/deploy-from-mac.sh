#!/usr/bin/env bash

set -euo pipefail

for command_name in ssh rsync; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing required command: $command_name" >&2
        exit 1
    fi
done

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_directory="$(cd "$script_directory/.." && pwd)"
remote_target="${PROJECT_DEPLOYER_TARGET:-hjy@pi.local}"
remote_host="${remote_target##*@}"

if [[ -z "$remote_target" || "$remote_target" == -* || "$remote_target" == *$'\n'* ]]; then
    echo "PROJECT_DEPLOYER_TARGET is invalid." >&2
    exit 1
fi

remote_source_directory="$(ssh -o BatchMode=yes "$remote_target" '
    set -eu
    source_directory="$HOME/.cache/project-deployer/source"
    mkdir -p "$source_directory"
    printf "%s" "$source_directory"
')"

if [[ "$remote_source_directory" != /* ]]; then
    echo "The remote source directory is invalid." >&2
    exit 1
fi

rsync \
    --archive \
    --compress \
    --delete \
    --exclude '.DS_Store' \
    --exclude '.git/' \
    --exclude 'service/.build/' \
    "$project_directory/" \
    "$remote_target:$remote_source_directory/"

ssh -o BatchMode=yes "$remote_target" "
    set -eu
    export PATH=\"\$HOME/.local/bin:\$PATH\"
    cd '$remote_source_directory'
    ./deploy/install-user.sh
"

echo "ProjectDeployer is available at http://$remote_host:10000/health."
