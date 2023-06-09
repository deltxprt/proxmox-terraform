terraform {
  cloud {
    organization = "markaplay"
    workspaces {
      name = "proxmox-terraform"
    }
  }
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

variable "address" {}
variable "roleid" {}
variable "secretid" {}

provider "vault" {
  address = var.address
  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id   = var.roleid
      secret_id = var.secretid
    }
  }
}

data "vault_generic_secret" "azure_secrets" {
  path = "proxmox/azure"
}

provider "azurerm" {
  client_id       = data.vault_generic_secret.azure_secrets.data["client_id"]
  client_secret   = data.vault_generic_secret.azure_secrets.data["client_secret"]
  tenant_id       = data.vault_generic_secret.azure_secrets.data["tenant_id"]
  subscription_id = data.vault_generic_secret.azure_secrets.data["subscription_id"]
  features {
    key_vault {
      purge_soft_deleted_secrets_on_destroy = true
      recover_soft_deleted_secrets          = true
    }
  }
}

data "vault_generic_secret" "dns-key" {
  path = "bind-dns/ns1"
}

#data.vault_generic_secret.dns-key.data["tsig"]
provider "dns" {
  update {
    server        = "10.0.0.111"
    key_name      = "tsig-key."
    key_algorithm = "hmac-sha256"
    key_secret    = data.vault_generic_secret.dns-key.data["tsig"]
  }
}

data "vault_generic_secret" "proxmox_secrets" {
  path = "proxmox/terraform"
}

provider "proxmox" {
  pm_api_url          = data.vault_generic_secret.proxmox_secrets.data["url"]
  pm_api_token_id     = data.vault_generic_secret.proxmox_secrets.data["user"]
  pm_api_token_secret = data.vault_generic_secret.proxmox_secrets.data["key"]
}



locals {
  lxc_files = fileset(".", "lxc/*.yaml")
  lxc       = { for file in local.lxc_files : basename(file) => yamldecode(file(file)) }
  vm_files  = fileset(".", "vm/*.yaml")
  vm        = { for file in local.vm_files : basename(file) => yamldecode(file(file)) }
}

module "lxc_resource" {
  source          = "./modules/lxc"
  for_each        = local.lxc
  hostname        = each.value.hostname
  description     = each.value.description
  template        = each.value.template
  unprivileged    = each.value.unprivileged
  size            = each.value.size
  onboot          = each.value.onboot
  start           = each.value.start
  ssh_public_keys = each.value.ssh_public_keys
  ip_address      = each.value.ip_address
  tags            = each.value.tags
}
module "vm_resource" {
  source      = "./modules/vm"
  for_each    = local.vm
  hostname    = each.value.hostname
  description = each.value.description
  os          = each.value.os
  size        = each.value.size
  ip_address  = each.value.ip_address
  tags        = each.value.tags
}

#output "test" {
#  value = module.lxc_resource
#}