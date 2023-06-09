terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.14"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.58.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.15.2"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.3.2"
    }
  }
}

resource "random_password" "lxcpassword" {
  length  = 25
  special = true
}

locals {
  lxc_size = {
    "small" = {
      cores  = 1
      memory = 1024
      size   = "10G"
    }
    "medium" = {
      cores  = 2
      memory = 2048
      size   = "20G"
    }
    "large" = {
      cores  = 4
      memory = 4096
      size   = "30G"
    }
    "xlarge" = {
      cores  = 8
      memory = 8192
      size   = "40G"
    }
  }
}


resource "proxmox_lxc" "lxc-servers" {
  target_node     = "epyc"
  hostname        = var.hostname
  description     = var.description
  ostemplate      = var.template
  password        = random_password.lxcpassword.result
  unprivileged    = var.unprivileged
  cores           = local.lxc_size[var.size].cores
  memory          = local.lxc_size[var.size].memory
  onboot          = var.onboot
  start           = var.start
  ssh_public_keys = var.ssh_public_keys

  // Terraform will crash without rootfs defined
  rootfs {
    storage = "vmpool"
    size    = local.lxc_size[var.size].size
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = format("%s/24", var.ip_address)
    gw     = "10.0.0.1"
  }

  lifecycle {
    ignore_changes = [
      description,
    ]
  }

}

resource "azurerm_key_vault_secret" "lxcpassword" {
  name         = proxmox_lxc.lxc-servers.hostname
  value        = random_password.lxcpassword.result
  key_vault_id = "/subscriptions/433a5766-0b1a-475e-aa9b-9556b6dab416/resourceGroups/Lab/providers/Microsoft.KeyVault/vaults/map-Vault-lab"
}

resource "vault_generic_secret" "lxclocalpassword" {
  path = "proxmox/${var.hostname}"
  data_json = jsonencode({
    password = random_password.lxcpassword.result
  })
}

resource "dns_a_record_set" "lxc_lab" {
  zone      = "lab.markaplay.net."
  name      = format("%s", var.hostname)
  addresses = [var.ip_address]
  ttl       = 3600
}

resource "dns_ptr_record" "lxc_reverse_lab" {
  zone = "0.0.10.in-addr.arpa."
  name = split(".", var.ip_address)[3]
  ptr  = format("%s.lab.markaplay.net.", var.hostname)
  ttl  = 3600
}

#output "lxc_resource" {
#  value = var.lxc_data
#}