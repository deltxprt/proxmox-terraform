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

variable "roleid" {}
variable "secretid" {}

provider "vault" {
  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id   = var.roleid
      secret_id = var.secretid
    }
  }
}

#data.vault_generic_secret.dns-key.data["tsig"]
provider "dns" {
  update {
    server        = "10.0.0.100"
    key_name      = "terraform-key."
    key_algorithm = "hmac-sha256"
    transport     = "tcp"
    key_secret    = "cQ5H8avnX637M74XUP0vO4YaZkv6uVHjaLqfWVkK4q8="
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
  hostname        = each.value.hostname
  description     = each.value.description
  template        = each.value.template
  unprivileged    = each.value.unprivileged
  size            = each.value.size
  onboot          = each.value.onboot
  start           = each.value.start
  ssh_public_keys = each.value.ssh_public_keys
  ip_address      = each.value.ip_address
}
module "vm_resource" {
  source      = "./modules/vm"
  for_each    = local.vm
  hostname    = each.value.hostname
  description = each.value.description
  os          = each.value.os
  size        = each.value.size
  ip_address  = each.value.ip_address
  #  tags        = each.value.tags
}

#output "test" {
#  value = module.lxc_resource
#}