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

module "instances_resource" {
  source   = "./modules"
  for_each = local.lxc
  lxc_data = each.value
  for_each_vm = local.vm
  vm_data  = each.value
}

#output "test" {
#  value = module.lxc_resource
#}