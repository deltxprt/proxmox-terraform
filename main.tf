terraform {
  backend "http" {}
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
    dns = {
      source  = "hashicorp/dns"
      version = "3.2.4"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_secrets_on_destroy = true
      recover_soft_deleted_secrets          = true
    }
  }
}

variable "login_approle_role_id" {}
variable "login_approle_secret_id" {}

provider "vault" {
  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id   = var.login_approle_role_id
      secret_id = var.login_approle_secret_id
    }
  }
}

data "vault_generic_secret" "dns-key" {
  path = "/bind-dns/ns1"
}

provider "dns" {
  update {
    server        = "10.0.0.111"
    key_name      = "terraform-key."
    key_algorithm = "hmac-sha256"
    key_secret    = data.vault_generic_secret.dns-key.data["tsig"]
  }
}

provider "proxmox" {}

locals {
  lxc_files = fileset(".", "lxc/*.yaml")
  lxc       = { for file in local.lxc_files : basename(file) => yamldecode(file(file)) }
  vm_files  = fileset(".", "vm/*.yaml")
  vm        = { for file in local.vm_files : basename(file) => yamldecode(file(file)) }
}

module "lxc_resource" {
  source          = "./modules/lxc"
  for_each        = local.lxc
  hostname        = each.key.hostname
  description     = each.key.description
  template        = each.key.template
  unprivileged    = each.key.unprivileged
  size            = each.key.size
  onboot          = each.key.onboot
  start           = each.key.start
  ssh_public_keys = each.key.ssh_public_keys
  ip_address     = each.key.ip_addresse
}
module "vm_resource" {
  source      = "./modules/vm"
  for_each    = local.vm
  hostname    = each.key.hostname
  description = each.key.description
  os          = each.key.os
  size        = each.key.size
  ip_address = each.key.ip_addresse
  tags        = each.key.tags
}

#output "test" {
#  value = module.lxc_resource
#}