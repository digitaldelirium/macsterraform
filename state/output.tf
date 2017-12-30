output "resource_group" {
    value = "${data.azurerm_resource_group.macs_resources.name}"
}

output "location" {
    value = "${data.azurerm_resource_group.macs_resources.location}"
}

output "subscription" {
    value = "${data.azurerm_subscription.current.subscription_id}"
}

output "storage_account" {
    value = "${azurerm_storage_account.macs_storage.id}"
}

output "storage_account_key" {
    value = "${azurerm_storage_account.macs_storage.primary_access_key}"
    sensitive = true    
}