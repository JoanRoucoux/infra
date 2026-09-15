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

Filled in by the monitoring setup.

## Rebuilding the server from scratch

The data is not critical: the portfolio re-imports from its CSV and passkeys re-register.

1. OVH manager: reinstall the VPS with Ubuntu 26.04 LTS and the `ubuntu` user's SSH key.
2. Record the new host key (`ssh-keyscan -t ed25519 51.255.42.146`) in `DEPLOY_KNOWN_HOSTS` of
   both applications' deploy workflows, and in `~/.ssh/known_hosts`.
3. `bash scripts/play.sh --diff`.
4. Recreate `/srv/cairn/.env` (mode 600, owner `deploy`), redeploy `cairn` then `cairn-web` by
   running their Deploy workflows with the current `main` SHA.
5. Recreate the Kuma and Beszel accounts and monitors from the Monitoring section.
