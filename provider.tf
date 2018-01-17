# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "9661a81b-1bc6-4836-ad63-41ddb2515f1b"
  client_id       = "44c4e2a1-4b32-4d7b-b063-ab00907ab449"
  tenant_id       = "ce30a824-b64b-4702-b3e8-8ff93ba9da38"
  client_secret   = "${var.client_secret}"
}
