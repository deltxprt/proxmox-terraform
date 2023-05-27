# proxmox-terraform

## Description

This repository contains a set of Terraform modules to deploy a Proxmox resources.

## Requirements

- [Terraform](https://www.terraform.io/downloads.html) >= 0.13
- [Proxmox](https://www.proxmox.com/en/downloads) >= 7.0
- [Proxmox Provider requirement](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- bind9 or any dns provider that support dynamic dns
- [cloud-init](https://cloudinit.readthedocs.io/en/latest/) (optional)
- [Hashicorp Vault](https://www.vaultproject.io/)
- [Azure Key Vault](https://azure.microsoft.com/en-us/services/key-vault/)

## Usage

### LXC

```yaml
hostname: "mylxc"
description: "a description"
template: "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst" # image path on proxmox
unprivileged: true # can be true or false
size: "small" # size of the container. Can be "small", "medium", "large" or "xlarge"
onboot: true # start on boot can be true or false
start: true # start after creation can be true or false
ssh_public_keys:
  MySSHPublicKey
ip_address: "10.0.0.105" # static ip address
tags: "lxc,ubuntu,monitoring" # comma separated list of tags
```

### VM

```yaml
hostname: "testvm"
description: "testvm"
os: "rocky" # can be "rocky", "debian" or "rhel"
size: "small" # size of the container. Can be "small", "medium", "large" or "xlarge"
ip_address: "10.0.0.122" # static ip address
tags: "testvm,test" # comma separated list of tags
```

## Modules specifications

size:
- small: 
  - lxc: 1 CPU, 1GB RAM, 10GB Disk
  - vm: 2 sockets, 2 Core, 1GB RAM, 10GB Disk
- medium:
  - lxc: 2 CPU, 2GB RAM, 20GB Disk
  - vm: 2 sockets, 2 Core, 2GB RAM, 20GB Disk
- large:
  - lxc: 4 CPU, 4GB RAM, 30GB Disk
  - vm: 2 sockets, 4 Core, 4GB RAM, 40GB Disk
- xlarge:
  - lxc: 8 CPU, 8GB RAM, 40GB Disk
  - vm: 2 sockets, 8 Core, 8GB RAM, 80GB Disk

## LXC specifications

Vault and Azure Key Vault are supported to store the generated password from terraform.