#!/usr/bin/env bash
# Runs a command in the pinned toolbox image: bash scripts/toolbox.sh <command...>
# TOOLBOX_WORKDIR selects a subdirectory of the repository as the working directory.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)

# Git Bash rewrites container paths such as /work into C:/Program Files/Git/work, and Docker
# Desktop needs C:/ host paths rather than /c/ ones.
export MSYS_NO_PATHCONV=1
hostpath() { if command -v cygpath > /dev/null; then cygpath -m "$1"; else printf '%s' "$1"; fi; }

docker build --quiet --tag infra-toolbox:local \
  --file "$(hostpath "$root/tools/Dockerfile")" "$(hostpath "$root")" > /dev/null

args=(--rm --interactive
  --volume "$(hostpath "$root"):/work"
  --workdir "/work/${TOOLBOX_WORKDIR:-}"
  --volume infra-tf-data:/tf-data)
if [ -t 0 ] && [ -t 1 ]; then args+=(--tty); fi
if [ -d "$HOME/.ssh" ]; then args+=(--volume "$(hostpath "$HOME/.ssh"):/ssh-host:ro"); fi
# OVH_*, TF_TOKEN_app_terraform_io and ACME_EMAIL: kept out of the repository.
if [ -f "$HOME/.infra.env" ]; then args+=(--env-file "$(hostpath "$HOME/.infra.env")"); fi

exec docker run "${args[@]}" infra-toolbox:local "$@"
