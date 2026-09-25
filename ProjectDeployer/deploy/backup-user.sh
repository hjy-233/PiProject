#!/usr/bin/env bash

set -euo pipefail

data_root="${PROJECT_DEPLOYER_DATA_ROOT:-$HOME/.local/share/project-deployer}"
config_root="${PROJECT_DEPLOYER_CONFIG_ROOT:-$HOME/.config/project-deployer}"
backup_root="${PROJECT_DEPLOYER_BACKUP_ROOT:-$HOME/.local/share/project-deployer-backups}"

for path in "$data_root" "$config_root" "$backup_root"; do
    if [[ "$path" != /* ]]; then
        echo "Backup paths must be absolute." >&2
        exit 64
    fi
done

[[ -d "$data_root" ]] || { echo "Data directory does not exist: $data_root" >&2; exit 66; }
[[ -d "$config_root" ]] || { echo "Configuration directory does not exist: $config_root" >&2; exit 66; }

install -d -m 700 "$backup_root"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
archive="$backup_root/project-deployer-$timestamp.tar.gz"
temporary_archive="$archive.partial"
service_was_active="$(systemctl --user is-active project-deployer.service 2>/dev/null || true)"

restart_service() {
    rm -f "$temporary_archive"
    if [[ "$service_was_active" == "active" ]]; then
        systemctl --user start project-deployer.service
    fi
}
trap restart_service EXIT

if [[ "$service_was_active" == "active" ]]; then
    systemctl --user stop project-deployer.service
fi

tar --create --gzip --file "$temporary_archive" \
    --directory / \
    "${data_root#/}" \
    "${config_root#/}"
chmod 600 "$temporary_archive"
mv "$temporary_archive" "$archive"
trap - EXIT
if [[ "$service_was_active" == "active" ]]; then
    systemctl --user start project-deployer.service
fi

sha256sum "$archive" > "$archive.sha256"
chmod 600 "$archive.sha256"
echo "$archive"
