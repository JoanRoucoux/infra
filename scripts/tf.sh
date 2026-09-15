#!/usr/bin/env bash
# terraform, run from terraform/ in the toolbox: bash scripts/tf.sh plan
set -euo pipefail
TOOLBOX_WORKDIR=terraform exec bash "$(dirname "$0")/toolbox.sh" terraform "$@"
