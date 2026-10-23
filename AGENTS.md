# infra

Owns the OVH VPS that hosts Cairn and, later, other applications: the OVH resources (Terraform),
the server's configuration (Ansible), the shared Caddy proxy and the monitoring stack. It never
deploys an application: each application deploys itself from its own repository.

## Commands

Nothing but Docker is needed. Terraform, Ansible and ansible-lint run in the toolbox image built
from `tools/Dockerfile`, the same image CI uses.

    bash scripts/check.sh                   # offline checks, same as CI
    bash scripts/tf.sh plan -out=tfplan     # needs ~/.infra.env
    bash scripts/tf.sh apply tfplan
    bash scripts/play.sh --check --diff     # dry run against the server
    bash scripts/play.sh --diff             # apply (ACME_EMAIL in ~/.infra.env)
    bash scripts/toolbox.sh <command>       # anything else, e.g. an ad hoc `ansible` call

`~/.infra.env`, outside the repository, holds `OVH_ENDPOINT`, `OVH_APPLICATION_KEY`,
`OVH_APPLICATION_SECRET`, `OVH_CONSUMER_KEY`, `TF_TOKEN_app_terraform_io` and `ACME_EMAIL`.

## Conventions

- Images pinned to an exact tag, never `latest`; Python packages and collections pinned to an
  exact version. Actions pinned by SHA.
- Comments flag traps only.
- LF line endings everywhere: a CRLF breaks bash, cron and sshd files.
- Secrets never in Git: application `.env` files are placed on the server by hand.
- Dependabot runs monthly with a 7-day cooldown. Minor and patch updates merge themselves through `.github/workflows/dependabot-auto-merge.yml` once the required checks pass, and majors are reviewed by hand. The README names major versions only, since the exact ones live in the manifests Dependabot bumps.

## Gotchas

- **The socket proxy mounts `/var/run`, not `docker.sock`.** An unattended Docker upgrade restarts
  dockerd, which recreates the socket, while `live-restore` keeps the proxy running. A bind mount of
  the socket file keeps the old inode, so every request got a 503 and every Kuma container monitor
  and Beszel's container stats stayed down from 2026-10-10 until the proxy was recreated.
- **Docker bypasses ufw.** A port published by a container ignores ufw's rules. The OVH network
  firewall, upstream of the machine, is the real barrier; only Caddy publishes public ports.
- **The OVH network firewall is stateless and IPv4 only.** Its rules must permit UDP replies from
  source ports 53 (DNS) and 123 (NTP), or apt, Docker and Let's Encrypt stop resolving. IPv6 is
  filtered by ufw alone.
- **sshd keeps the first value it reads.** Ubuntu's `50-cloud-init.conf` re-enables passwords;
  `10-hardening.conf` wins only because it sorts first.
- **Never rename the `proxy` compose project or move `/srv/proxy`.** The volume holding every
  certificate is `proxy_caddy-data`; a new project name starts from an empty one and re-issues all
  certificates against Let's Encrypt's rate limits. Application workflows also reload Caddy
  through the container name `proxy-caddy-1`.
- **Log rotation only applies to recreated containers.** Changing `daemon.json` leaves running
  containers on their old log settings until `docker compose up -d --force-recreate`.
- **Never import a DNS record Terraform does not own.** The apex, `www` and the MX records serve
  OVH web hosting and mail. CAA sits on each managed subdomain, not the apex, for the same reason.
- **Uptime Kuma's monitors live in its SQLite volume**, not in this repository. README.md lists
  them so they can be recreated.
- **A Windows bind mount shows every file as 777.** The toolbox names `ANSIBLE_CONFIG` explicitly
  (Ansible ignores `ansible.cfg` in a world-writable directory), copies SSH keys in with mode 600,
  and keeps Terraform's plugins in the `infra-tf-data` volume.
- **Git Bash rewrites paths passed to Docker.** Every script exports `MSYS_NO_PATHCONV=1` and
  converts host paths with `cygpath -m`.
- A merge made with `GITHUB_TOKEN` triggers no `push` workflow, which is why `dependabot-auto-merge.yml` uses the `DEPENDABOT_MERGE_TOKEN` secret when it exists.
