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

provider "proxmox" {}

locals {
  #cloudinit = yamldecode(templatefile("cloudinit.yaml", {
  #  delta_public_key   = "${harvester_ssh_key.delta.public_key}"
  #  ansible_public_key = "${harvester_ssh_key.ansible.public_key}"
  #}))
  # virtualmachines = yamldecode(file("virtualmachines.yaml"))
  lxc = yamldecode(file("lxc.yaml"))
}

#resource "proxmox_vm_qemu" "virtualmachines" {
#  for_each             = local.virtualmachines
#  name                 = each.value.name
#  namespace            = each.value.namespace
#  restart_after_update = each.value.restart_after_update
#  description          = each.value.description
#  cpu                  = each.value.cpu
#  memory               = each.value.memory
#  efi                  = each.value.efi
#  secure_boot          = each.value.secure_boot
#  run_strategy         = each.value.run_strategy
#  hostname             = each.value.hostname
#  machine_type         = each.value.machine_type
#  network_interface {
#    name           = each.value.nic-1.name
#    network_name   = each.value.nic-1.network_name
#    wait_for_lease = each.value.nic-1.wait_for_lease
#  }
#  disk {
#    name        = each.value.rootdisk.name
#    type        = each.value.rootdisk.type
#    size        = each.value.rootdisk.size
#    bus         = each.value.rootdisk.bus
#    boot_order  = each.value.rootdisk.boot_order
#    image       = each.value.rootdisk.image_name
#    auto_delete = each.value.rootdisk.auto_delete
#  }
#  cloudinit {
#    user_data    = (each.value.cloud_init == "ubuntu-debian" ? local.cloudinit.ubuntu-debian.UserData : local.cloudinit.rhel.UserData)
#    network_data = (each.value.cloud_init == "ubuntu-debian" ? local.cloudinit.ubuntu-debian.NetworkData : local.cloudinit.rhel.NetworkData)
#  }
#  lifecycle {
#    ignore_changes = [disk]
#  }
#}

module "lxc_resource" {
  source   = "./modules"
  for_each = local.lxc
  lxc_data = each.value
}

#output "test" {
#  value = module.lxc_resource
#}