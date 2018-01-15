output "public_ip" {
  value = "${data.azurerm_public_ip.selected.ip_address}"
}

output "macs_vault" {
  value = "${azurerm_key_vault.macsvault.vault_uri}"
}