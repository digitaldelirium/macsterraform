output "public_ip" {
  value = "${azurerm_public_ip.macsterraformpublicip.ip_address}"
}

output "macs_vault" {
  value = "${azurerm_key_vault.macsvault.vault_uri}"
}
