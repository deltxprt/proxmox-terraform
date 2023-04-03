terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.2.4"
    }
  }
}
locals {
  vm_size = {
    "small" = {
      sockets = 2
      cores   = 1
      memory  = 1024
      disk    = "10G"
    }
    "medium" = {
      sockets = 2
      cores   = 2
      memory  = 2048
      disk    = "20G"
    }
    "large" = {
      sockets = 2
      cores   = 4
      memory  = 4096
      disk    = "40G"
    }
    "xlarge" = {
      sockets = 2
      cores   = 8
      memory  = 8192
      disk    = "80G"
    }
  }
  operating_system = {
    "debian" = "debian11"
    "rhel"   = "rhel9"
  }
}

resource "proxmox_vm_qemu" "vm-server" {
  target_node = "epyc"
  name        = var.hostname
  desc        = var.description
  agent       = 1
  full_clone  = true
  clone       = local.operating_system[var.os]
  cpu         = "EPYC-Rome"
  numa        = true
  sockets     = local.vm_size[var.size].sockets
  cores       = local.vm_size[var.size].cores
  memory      = local.vm_size[var.size].memory
  onboot      = true
  os_type     = "cloud-init"

  disk {
    type    = "virtio"
    storage = "vm-data"
    ssd     = 1
    size    = local.vm_size[var.size].disk
  }

  network {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }
  ipconfig0 = format("ip=%s/24,gw=10.0.0.1", var.ip_address)

  lifecycle {
    ignore_changes = [disk]
  }

}

resource "dns_a_record_set" "vm_lab" {
  zone      = "lab.markaplay.net."
  name      = format("%s.lab.markaplay.net.", var.hostname)
  addresses = [var.ip_address]
  ttl       = 3600
}

resource "dns_ptr_record" "vm_reverse_lab" {
  zone = "0.0.10.in-addr.arpa."
  name = split(".",var.ip_address)[2]
  ptr  = format("%s.lab.markaplay.net.", var.hostname)
  ttl  = 3600
}