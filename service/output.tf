output "public_ip" {
  value = "${data.azurerm_public_ip.selected.ip_address}"
}
