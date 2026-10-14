# syntax=docker/dockerfile:1
FROM python:3.14.8-slim-trixie

ARG TERRAFORM_VERSION=1.16.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git openssh-client unzip \
    && rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    zip="terraform_${TERRAFORM_VERSION}_linux_amd64.zip"; \
    sums="terraform_${TERRAFORM_VERSION}_SHA256SUMS"; \
    cd /tmp; \
    curl -fsSLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${zip}"; \
    curl -fsSLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${sums}"; \
    grep " ${zip}\$" "${sums}" | sha256sum -c -; \
    unzip -o "${zip}" terraform -d /usr/local/bin; \
    rm -f "${zip}" "${sums}"

COPY tools/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

ENV ANSIBLE_COLLECTIONS_PATH=/usr/share/ansible/collections
COPY ansible/requirements.yml /tmp/requirements.yml
RUN ansible-galaxy collection install -r /tmp/requirements.yml -p /usr/share/ansible/collections

# Ansible ignores an ansible.cfg found in a world-writable working directory, which is what every
# Windows bind mount looks like, unless the file is named explicitly.
ENV ANSIBLE_CONFIG=/work/ansible/ansible.cfg
# Provider plugins stay in a Linux volume: on a Windows bind mount they lose their executable bit.
ENV TF_DATA_DIR=/tf-data
RUN git config --system --add safe.directory '*'

COPY tools/entrypoint.sh /usr/local/bin/entrypoint
WORKDIR /work
ENTRYPOINT ["bash", "/usr/local/bin/entrypoint"]
