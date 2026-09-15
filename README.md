# infra

Terraform, Ansible, the shared proxy and the monitoring for the OVH VPS at `51.255.42.146`.

    terraform/     OVH resources: VPS (imported), DNS records, network firewall
    ansible/       Server configuration: users, sshd, ufw, Docker, updates, proxy, monitoring
    proxy/         Shared Caddy: ports 80/443, one snippet per site in /srv/proxy/sites/
    monitoring/    Uptime Kuma, Beszel hub and agent, read-only Docker socket proxy
    tools/         The toolbox image: Terraform, Ansible, ansible-lint, pinned collections
    scripts/       toolbox.sh, tf.sh, play.sh, check.sh

## Workstation

Docker is the only requirement. The first `scripts/*.sh` call builds the toolbox image, later ones
reuse it. Credentials go in `~/.infra.env`, never in this repository:

    OVH_ENDPOINT=ovh-eu
    OVH_APPLICATION_KEY=...
    OVH_APPLICATION_SECRET=...
    OVH_CONSUMER_KEY=...
    TF_TOKEN_app_terraform_io=...
    ACME_EMAIL=...

SSH keys are read from `~/.ssh`.

## Monitoring

Uptime Kuma at `https://status.joanroucoux.fr` (2FA), Beszel at `https://metrics.joanroucoux.fr`,
UptimeRobot outside the server. All three alert by email through Gmail SMTP with an app password,
configured in each tool's UI and stored in its own volume, never in this repository.

Kuma's monitors live in its SQLite volume. To recreate them:

| Name | Type | Target | Interval |
| --- | --- | --- | --- |
| cairn api | HTTP(s), 200, certificate expiry | `https://cairn.joanroucoux.fr/api/actuator/health` | 60 s |
| cairn web | HTTP(s), 200 | `https://cairn.joanroucoux.fr/` | 60 s |
| container cairn-api-1, cairn-web-1, cairn-postgres-1, proxy-caddy-1 | Docker Container, host `tcp://socket-proxy:2375` | container name | 60 s |
| batch equity | Push | URL in `/srv/cairn/.env` as `KUMA_PUSH_EQUITY` | 73 h |
| batch etf | Push | `KUMA_PUSH_ETF` | 73 h |
| batch fund | Push | `KUMA_PUSH_FUND` | 73 h |
| batch crypto | Push | `KUMA_PUSH_CRYPTO` | 4 h 30 |

A container with a healthcheck restarts through `starting`, which Kuma records as Pending, and Kuma
notifies neither DOWN to Pending nor Pending to UP: container monitors send their DOWN email but
no UP email. The HTTP monitors report the recovery.

A push monitor only takes a fixed interval: equities and ETFs run on weekdays and funds from
Tuesday to Saturday, so all three tolerate a weekend gap of 72 hours.

Beszel: system `vps` at `/beszel_socket/beszel.sock`, its public key in
`ansible/group_vars/all.yml`. Alerts: CPU above 80 % for 10 minutes, memory above 90 %, disk
above 80 %, system down. Its SMTP settings live in PocketBase (`/_/`): on port 465, TLS encryption
must be `Always`, not `Auto (StartTLS)`.

UptimeRobot: `https://cairn.joanroucoux.fr/api/actuator/health` and
`https://status.joanroucoux.fr/`, every 5 minutes. The second one is what notices the whole
server going down, Kuma included.

First-run pages are public: create the Kuma and Beszel admin accounts right after the stack
starts, before anyone else reaches them.

## Rebuilding the server from scratch

The data is not critical: the portfolio re-imports from its CSV and passkeys re-register.

1. OVH manager: reinstall the VPS with Ubuntu 26.04 LTS and the `ubuntu` user's SSH key.
2. Record the new host key (`ssh-keyscan -t ed25519 51.255.42.146`) in `DEPLOY_KNOWN_HOSTS` of
   both applications' deploy workflows, and in `~/.ssh/known_hosts`.
3. `bash scripts/play.sh --diff`.
4. Recreate `/srv/cairn/.env` (mode 600, owner `deploy`), redeploy `cairn` then `cairn-web` by
   running their Deploy workflows with the current `main` SHA.
5. Recreate the Kuma and Beszel accounts and monitors from the Monitoring section.
