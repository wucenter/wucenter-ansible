# TIP: docker build [ --build-arg PACKER_VERSION=X.Y.Z ] - < samples/docker/wucenter-source.Dockerfile

# WUcenter Ansible framework: dependencies
FROM ubuntu:18.04 AS wucenter-base
RUN    apt-get update \
    && apt-get install -y --no-install-recommends unzip git python3-pip python3-setuptools iproute2 openssh-client \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --no-cache-dir ansible \
    && mkdir -p /data \
    && cd /data
WORKDIR /data

# WUcenter Ansible framework: install from Docker COPY
FROM wucenter-base AS wucenter-ansible-source
COPY ansible_collections wucenter-ansible/ansible_collections


# WUcenter Ansible framework: setup Ansible workspace
FROM wucenter-ansible-source AS wucenter-ansible
RUN    cd /data/wucenter-ansible \
    && ansible_collections/wucenter/wucenter/wucenter_setup.sh
WORKDIR /data/wucenter-ansible
CMD ["books/apply.yml", "-vv"]

# WUcenter Distribution: Ansible framwork + Packer template builder
FROM wucenter-ansible AS wucenter
ARG PACKER_VERSION=1.5.6
ADD "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" /tmp/packer.zip
RUN    cd /data \
    && git clone --depth 1 git://github.com/wucenter/wucenter-packer.git \
    && unzip /tmp/packer.zip -d /usr/local/bin \
    && rm /tmp/packer.zip
ENV PACKER_LOG 1
