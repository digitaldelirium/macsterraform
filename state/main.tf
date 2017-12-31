resource "azurerm_resource_group" "macs_resources" {
   name = "macs_camping_rg"
   location = "East US 2"
}

resource "azurerm_storage_account" "macs_storage" {
   name = "macsstorage"
   resource_group_name = "${azurerm_resource_group.macs_resources.name}"
   location = "East US 2"
   account_tier = "Standard"
   account_kind = "BlobStorage"
   account_replication_type = "LRS"
   access_tier = "Hot"
   enable_blob_encryption = "true"
   enable_https_traffic_only = "true"
}

resource "azurerm_storage_container" "macs_state" {
   name = "tfstate"
   resource_group_name = "${azurerm_resource_group.macs_resources.name}"
   storage_account_name = "${azurerm_storage_account.macs_storage.name}"
   container_access_type = "private"
}

data "azurerm_resource_group" "macs_resources" {
    name = "${azurerm_resource_group.macs_resources.name}"
    depends_on = ["azurerm_resource_group.macs_resources"]
}

data "azurerm_subscription" "current" {
    subscription_id = "9661a81b-1bc6-4836-ad63-41ddb2515f1b"
}

/*  Enable after creating objects - Comment otherwise */
terraform {
    backend "azurerm" {
        storage_account_name = "macsstorage"
        container_name = "tfstate"
        key = "prod.terraform.state"
    }
}