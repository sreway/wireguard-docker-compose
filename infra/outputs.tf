output "ansible_inventory_data" {
  value = module.ansible_inventory.data
}

output "ssh_config" {
  value = local.ssh_config
}
