#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "aarch64" ]]; then
    echo "This installer only supports Linux aarch64." >&2
    exit 1
fi

for command_name in swift git docker systemctl curl; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing required command: $command_name" >&2
        exit 1
    fi
done

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_directory="$(cd "$script_directory/.." && pwd)"
service_directory="$project_directory/service"
install_root="${PROJECT_DEPLOYER_INSTALL_ROOT:-$HOME/.local/lib/project-deployer}"
configuration_directory="${PROJECT_DEPLOYER_CONFIG_ROOT:-$HOME/.config/project-deployer}"
data_root="${PROJECT_DEPLOYER_DATA_ROOT:-$HOME/.local/share/project-deployer}"
unit_directory="$HOME/.config/systemd/user"
build_jobs="${PROJECT_DEPLOYER_BUILD_JOBS:-2}"
service_host="0.0.0.0"
service_port="10000"

if [[ "$install_root" != /* || "$configuration_directory" != /* || "$data_root" != /* ]]; then
    echo "Installation, configuration, and data paths must be absolute." >&2
    exit 1
fi

commit_id="$(git -C "$project_directory" rev-parse --short=12 HEAD 2>/dev/null || printf 'source')"
release_name="$(date -u +%Y%m%dT%H%M%SZ)-$commit_id"
release_directory="$install_root/releases/$release_name"
current_link="$install_root/current"
next_link="$install_root/.current-next"
previous_release=""

prune_old_binary_releases() {
    local active_release candidate
    active_release="$(readlink -f "$current_link")"
    for candidate in "$install_root"/releases/*; do
        if [[ ! -d "$candidate" || "$(readlink -f "$candidate")" == "$active_release" ]]; then
            continue
        fi
        find "$candidate" -depth -delete
    done
}

if [[ -L "$current_link" ]]; then
    previous_release="$(readlink -f "$current_link")"
fi

swift build \
    --package-path "$service_directory" \
    --configuration release \
    --jobs "$build_jobs"

binary_path="$(swift build \
    --package-path "$service_directory" \
    --configuration release \
    --show-bin-path)/project-deployer-service"

install -d -m 700 "$release_directory" "$configuration_directory" "$data_root" "$unit_directory"
install -m 755 "$binary_path" "$release_directory/project-deployer-service"
install -m 644 "$script_directory/project-deployer.service" "$unit_directory/project-deployer.service"

environment_file="$configuration_directory/environment"
if [[ ! -e "$environment_file" ]]; then
    install -m 600 /dev/null "$environment_file"
    {
        printf 'PROJECT_DEPLOYER_HOST=%s\n' "$service_host"
        printf 'PROJECT_DEPLOYER_PORT=%s\n' "$service_port"
        printf 'PROJECT_DEPLOYER_LOG_LEVEL=info\n'
        printf 'PROJECT_DEPLOYER_DATA_ROOT=%s\n' "$data_root"
        printf 'PROJECT_DEPLOYER_GIT_EXECUTABLE=%s\n' "$(command -v git)"
        printf 'PROJECT_DEPLOYER_DOCKER_EXECUTABLE=%s\n' "$(command -v docker)"
        printf 'PROJECT_DEPLOYER_POLL_SWEEP_SECONDS=5\n'
    } >> "$environment_file"
else
    environment_file_next="$(mktemp "$configuration_directory/environment.XXXXXX")"
    awk -v service_host="$service_host" -v service_port="$service_port" '
        BEGIN { found_host = 0; found_port = 0 }
        /^PROJECT_DEPLOYER_HOST=/ {
            if (found_host == 0) {
                print "PROJECT_DEPLOYER_HOST=" service_host
                found_host = 1
            }
            next
        }
        /^PROJECT_DEPLOYER_PORT=/ {
            if (found_port == 0) {
                print "PROJECT_DEPLOYER_PORT=" service_port
                found_port = 1
            }
            next
        }
        { print }
        END {
            if (found_host == 0) {
                print "PROJECT_DEPLOYER_HOST=" service_host
            }
            if (found_port == 0) {
                print "PROJECT_DEPLOYER_PORT=" service_port
            }
        }
    ' "$environment_file" > "$environment_file_next"
    chmod 600 "$environment_file_next"
    mv -f "$environment_file_next" "$environment_file"
fi

if [[ -e "$next_link" || -L "$next_link" ]]; then
    unlink "$next_link"
fi
ln -s "$release_directory" "$next_link"
mv -Tf "$next_link" "$current_link"

systemctl --user daemon-reload
systemctl --user enable --now project-deployer.service
systemctl --user restart project-deployer.service

health_url="http://127.0.0.1:$service_port/health"
for attempt in {1..30}; do
    if curl --fail --silent --show-error --max-time 2 "$health_url" >/dev/null; then
        prune_old_binary_releases
        echo "ProjectDeployer installed: $release_name"
        echo "Health: $health_url"
        exit 0
    fi
    sleep 1
done

echo "The new ProjectDeployer release did not become healthy." >&2
if [[ -n "$previous_release" && -d "$previous_release" ]]; then
    ln -s "$previous_release" "$next_link"
    mv -Tf "$next_link" "$current_link"
    systemctl --user restart project-deployer.service
    echo "Restored previous release: $previous_release" >&2
else
    systemctl --user stop project-deployer.service
    if [[ -L "$current_link" ]]; then
        unlink "$current_link"
    fi
fi
exit 1
