terraform {
  backend "azurerm" {
    storage_account_name = "macsstorage"
    container_name       = "tfstate"
    key                  = "prod.terraform.keyvault"
  }
}

# Create Key Vault
resource "azurerm_key_vault" "macs_vault" {
  name                = "macs-camping-vault"
  location            = "${data.terraform_remote_state.state_server.location}"
  resource_group_name = "${data.terraform_remote_state.state_server.resource_group}"

  sku {
    name = "standard"
  }

  tenant_id = "ce30a824-b64b-4702-b3e8-8ff93ba9da38"

  access_policy {
    tenant_id      = "ce30a824-b64b-4702-b3e8-8ff93ba9da38"
    object_id      = "ab520a90-476b-4c52-b11f-e5a2fe44226e"
    application_id = "6c36d239-f3d9-4554-b100-f6c0859c214d"

    key_permissions = [
      "backup",
      "create",
      "decrypt",
      "delete",
      "encrypt",
      "get",
      "import",
      "list",
      "purge",
      "recover",
      "restore",
      "sign",
      "unwrapKey",
      "update",
      "verify",
    ]

    secret_permissions = [
      "get",
      "backup",
      "delete",
      "list",
      "purge",
      "recover",
      "restore",
      "set",
    ]

    certificate_permissions = [
      "create",
      "delete",
      "deleteissuers",
      "get",
      "getissuers",
      "import",
      "list",
      "listissuers",
      "managecontacts",
      "manageissuers",
      "setissuers",
      "update",
    ]
  }

  access_policy {
    tenant_id = "ce30a824-b64b-4702-b3e8-8ff93ba9da38"
    object_id = "1714df59-7463-4437-9478-b126a07a1187"

    key_permissions = [
      "backup",
      "create",
      "decrypt",
      "delete",
      "encrypt",
      "get",
      "import",
      "list",
      "purge",
      "recover",
      "restore",
      "sign",
      "unwrapKey",
      "update",
      "verify",
    ]

    secret_permissions = [
      "get",
      "backup",
      "delete",
      "list",
      "purge",
      "recover",
      "restore",
      "set",
    ]

    certificate_permissions = [
      "create",
      "delete",
      "deleteissuers",
      "get",
      "getissuers",
      "import",
      "list",
      "listissuers",
      "managecontacts",
      "manageissuers",
      "setissuers",
      "update",
    ]
  }

  enabled_for_disk_encryption = true
}

# Allow for disk encryption
#resource "azurerm_key_vault_certificate" "disk_encryption" {
#  name      = "disk-encryption"
#  vault_uri = "${azurerm_key_vault.macs_vault.vault_uri}"

#  certificate_policy {
#    issuer_parameters {
#      name = "Self"
#    }

#    key_properties {
#      exportable = true
#      key_size   = "2048"
#      key_type   = "RSA"
#      reuse_key  = true
#    }
  
#    lifetime_action {
#      action {
#        action_type = "AutoRenew"
#      }

#      trigger {
#        days_before_expiry = 30
#      }
#    }

#    secret_properties {
#      content_type = "application/x-pkcs12"
#    }
  

#    x509_certificate_properties {
#      key_usage = [
#        "dataEncipherment",
#      ]

#      subject            = "CN=MacsEncryption"
#      validity_in_months = 12
#    }
#  }
#}

# Generate Root Password for MSSQL
resource "random_string" "mysql_root_password" {
  length  = 24
  special = false
}

# Save SQL Password
resource "azurerm_key_vault_secret" "sql_root" {
  name      = "SQLRoot"
  value     = "${random_string.mysql_root_password.result}"
  vault_uri = "${azurerm_key_vault.macs_vault.vault_uri}"
  content_type = "string"
  depends_on = ["random_string.mysql_root_password"]
}

# Generate User Password for MySQL
resource "random_string" "macs_datauser_password" {
  length  = 12
  special = false
}

# Save SQL User Password
resource "azurerm_key_vault_secret" "sql_user" {
  name      = "MySqlUser"
  value     = "${random_string.macs_datauser_password.result}"
  vault_uri = "${azurerm_key_vault.macs_vault.vault_uri}"
  content_type = "string"
  depends_on = ["random_string.macs_datauser_password"]
}

# Recall State Server
data "terraform_remote_state" "state_server" {
  backend = "azurerm"

  config {
    storage_account_name = "macsstorage"
    container_name       = "tfstate"
    key                  = "prod.terraform.state"
    access_key           = "${var.access_key}"
  }
}
