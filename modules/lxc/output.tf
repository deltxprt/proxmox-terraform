output "id" {
  value = proxmox_lxc.lxc-servers.id
}

output "hostname" {
  value = proxmox_lxc.lxc-servers.hostname
}

output "ip" {
  value = proxmox_lxc.lxc-servers.network.0.ip
}

