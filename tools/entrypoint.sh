#!/usr/bin/env bash
# OpenSSH refuses a private key whose permissions look open, and a Windows bind mount shows every
# file as 777: the keys are copied in with mode 600 rather than mounted where ssh reads them.
# The host's ssh config is left out, since its IdentityFile lines are Windows paths.
set -euo pipefail

if [ -d /ssh-host ]; then
  mkdir -p /root/.ssh
  find /ssh-host -maxdepth 1 -type f ! -name config -exec cp {} /root/.ssh/ \;
  chmod 700 /root/.ssh
  find /root/.ssh -type f -exec chmod 600 {} \;
fi

exec "$@"
