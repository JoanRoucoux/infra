#!/usr/bin/env bash
# Offline checks for the whole repository: no credentials, no server, no OVH or HCP account.
set -euo pipefail
cd "$(dirname "$0")/.."

export MSYS_NO_PATHCONV=1
hostpath() { if command -v cygpath > /dev/null; then cygpath -m "$1"; else printf '%s' "$1"; fi; }
step() { printf '\n==> %s\n' "$*"; }

if [ -d terraform ]; then
  step terraform
  TOOLBOX_WORKDIR=terraform bash scripts/toolbox.sh bash -c \
    'terraform fmt -check -recursive && terraform init -backend=false -input=false > /dev/null && terraform validate'
fi

if [ -f ansible/site.yml ]; then
  step ansible
  TOOLBOX_WORKDIR=ansible bash scripts/toolbox.sh bash -c \
    'ansible-playbook --syntax-check site.yml && ansible-lint'
fi

if [ -d proxy ]; then
  step proxy
  dir=$(mktemp -d)
  cp -r proxy/. "$dir/"
  mkdir -p "$dir/sites"
  cat > "$dir/.env" <<'ENV'
ACME_EMAIL=ops@example.test
CAIRN_DOMAIN=cairn.example.test
STATUS_DOMAIN=status.example.test
METRICS_DOMAIN=metrics.example.test
ENV
  if [ -d monitoring ]; then cp monitoring/*.caddy "$dir/sites/"; fi
  compose=(docker compose --project-directory "$(hostpath "$dir")" -f "$(hostpath "$dir/compose.yaml")")
  "${compose[@]}" config --quiet
  image=$("${compose[@]}" config --images | tr -d '\r')
  docker run --rm --env-file "$(hostpath "$dir/.env")" \
    -v "$(hostpath "$dir/Caddyfile"):/etc/caddy/Caddyfile:ro" -v "$(hostpath "$dir/sites"):/etc/caddy/sites:ro" \
    "$image" caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
  rm -rf "$dir"
fi

if [ -d monitoring ]; then
  step monitoring
  dir=$(mktemp -d)
  cp monitoring/compose.yaml "$dir/"
  printf 'METRICS_DOMAIN=metrics.example.test\nBESZEL_AGENT_KEY=ssh-ed25519 AAAAtest\n' > "$dir/.env"
  docker compose --project-directory "$(hostpath "$dir")" -f "$(hostpath "$dir/compose.yaml")" --profile agent config --quiet
  rm -rf "$dir"
fi

if [ -d .github/workflows ]; then
  step workflows
  docker run --rm -v "$(hostpath "$PWD"):/repo" -w /repo rhysd/actionlint:1.7.12
fi

step 'all checks passed'
