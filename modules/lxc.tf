terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.14.0"
    }
  }
}

variable "lxc_data" {
  type = object({
    hostname        = string
    description     = string
    ostemplate      = string
    unprivileged    = bool
    cores           = number
    memory          = number
    onboot          = bool
    start           = bool
    ssh_public_keys = string
    rootfs = object({
      storage = string
      size    = string
    })
    network = object({
      name   = string
      bridge = string
      ip     = string
      gw     = string
    })
  })
}

resource "random_password" "lxcpassword" {
  length  = 25
  special = true
}

locals {
  lxc_resource = merge({ password = random_password.lxcpassword.result }, var.lxc_data)
}

resource "proxmox_lxc" "lxc-servers" {
  target_node     = "epyc"
  hostname        = local.lxc_resource.hostname
  description     = local.lxc_resource.description
  ostemplate      = local.lxc_resource.ostemplate
  password        = local.lxc_resource.password
  unprivileged    = local.lxc_resource.unprivileged
  cores           = local.lxc_resource.cores
  memory          = local.lxc_resource.memory
  onboot          = local.lxc_resource.onboot
  start           = local.lxc_resource.start
  ssh_public_keys = local.lxc_resource.ssh_public_keys

  // Terraform will crash without rootfs defined
  rootfs {
    storage = local.lxc_resource.rootfs.storage
    size    = local.lxc_resource.rootfs.size
  }

  network {
    name   = local.lxc_resource.network.name
    bridge = local.lxc_resource.network.bridge
    ip     = local.lxc_resource.network.ip
    gw     = local.lxc_resource.network.gw
  }

}

resource "azurerm_key_vault_secret" "lxcpassword" {
  name         = proxmox_lxc.lxc-servers.hostname
  value        = local.lxc_resource.password
  key_vault_id = "/subscriptions/433a5766-0b1a-475e-aa9b-9556b6dab416/resourceGroups/Lab/providers/Microsoft.KeyVault/vaults/map-Vault-lab"
}

resource "vault_generic_secret" "lxclocalpassword" {
  path = "secret/lxc/${proxmox_lxc.lxc-servers.hostname}"
  data_json = jsonencode({
    password = local.lxc_resource.password
  })
}

resource "dns_a_record_set" "lsc_lab" {
  zone      = "lab.markaplay.net."
  name      = local.lxc_data.hostname
  addresses = local.lxc_data.ip
  ttl       = 3600
}

resource "dns_ptr_record" "lxc_reverse_lab" {
  zone = "0.0.10.in-addr.arpa."
  name = local.lxc_data.ip
  ptr  = local.lxc_data.hostname
  ttl  = 3600
}

#output "lxc_resource" {
#  value = var.lxc_data
#}