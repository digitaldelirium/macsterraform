provider "azurerm" {
  subscription_id = "9661a81b-1bc6-4836-ad63-41ddb2515f1b"
  client_id       = "44c4e2a1-4b32-4d7b-b063-ab00907ab449"
  tenant_id       = "ce30a824-b64b-4702-b3e8-8ff93ba9da38"
  client_secret   = "${var.client_secret}"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "macsterraformgroup" {
  name     = "${var.resource_name}"
  location = "eastus"

  tags {
    environment = "Mac's Camping Area"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Create Mac's Storage account
resource "azurerm_storage_account" "macsstatestorage" {
  name                      = "macsstatestorage"
  resource_group_name       = "${azurerm_resource_group.macsterraformgroup.name}"
  location                  = "eastus"
  account_kind              = "BlobStorage"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  access_tier               = "Hot"
  enable_blob_encryption    = true
  enable_https_traffic_only = true

  lifecycle {
    prevent_destroy = true
  }
}

# Create State Storage Container
resource "azurerm_storage_container" "macs_state" {
  name                  = "tfstate"
  resource_group_name   = "macscampinggroup"
  storage_account_name  = "${azurerm_storage_account.macsstatestorage.name}"
  container_access_type = "blob"

  lifecycle {
    prevent_destroy = true
  }
}

terraform {
  backend "azurerm" {
    storage_account_name = "macsstatestorage"
    container_name       = "tfstate"
    access_key           = {}
    key                  = "prod.state.tfstate"
  }
}
