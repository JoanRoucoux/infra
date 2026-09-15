#!/usr/bin/env bash
# ansible-playbook site.yml, run from ansible/ in the toolbox: bash scripts/play.sh --check --diff
set -euo pipefail
TOOLBOX_WORKDIR=ansible exec bash "$(dirname "$0")/toolbox.sh" ansible-playbook site.yml "$@"
