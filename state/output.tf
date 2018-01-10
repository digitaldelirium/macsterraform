output "resource_group" {
  value = "${azurerm_resource_group.macsterraformgroup.name}"
}

output "primary_access_key" {
  value     = "${azurerm_storage_account.macsstatestorage.primary_access_key}"
  sensitive = true
}
