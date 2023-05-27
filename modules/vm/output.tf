output "id" {
  value = proxmox_vm_qemu.vm-server.id
}

output "hostname" {
  value =proxmox_vm_qemu.vm-server.name
}

output "ip" {
  value = proxmox_vm_qemu.vm-server.ipconfig0
}

