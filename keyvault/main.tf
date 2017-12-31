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
    object_id      = "6e1ed4eb-026a-424c-8c03-b87418b69c6e"
    application_id = "44c4e2a1-4b32-4d7b-b063-ab00907ab449"

    key_permissions = [
      "backup",
      "create",
      "delete",
      "get",
      "import",
      "list",
      "recover",
      "restore",
      "update",
    ]

    secret_permissions = [
      "get",
      "backup",
      "delete",
      "list",
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
      "recover"
    ]
  }

  access_policy {
    tenant_id = "ce30a824-b64b-4702-b3e8-8ff93ba9da38"
    object_id = "1714df59-7463-4437-9478-b126a07a1187"

    key_permissions = [
      "backup",
      "create",
      "delete",
      "get",
      "import",
      "list",
      "recover",
      "restore",
      "update",
    ]

    secret_permissions = [
      "get",
      "backup",
      "delete",
      "list",
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
      "recover"
    ]
  }

  access_policy {
    tenant_id      = "ce30a824-b64b-4702-b3e8-8ff93ba9da38"
    object_id      = "9ba6a68e-40fb-4311-b5f2-41920b92e188"
    application_id = "36011f72-2743-4b0b-a97f-99c37235684e"

    key_permissions = [
      "backup",
      "create",
      "delete",
      "get",
      "import",
      "list",
      "recover",
      "restore",
      "update",
    ]

    secret_permissions = [
      "get",
      "backup",
      "delete",
      "list",
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
      "recover"
    ]
  }

  enabled_for_disk_encryption = true
  enabled_for_deployment = true
}

# Allow for disk encryption
/*resource "azurerm_key_vault_certificate" "disk_encryption" {
  name      = "disk-encryption"
  vault_uri = "${azurerm_key_vault.macs_vault.vault_uri}"

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = "2048"
      key_type   = "RSA"
      reuse_key  = true
    }
  
    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  

    x509_certificate_properties {
      key_usage = [
        "dataEncipherment",
      ]

      subject            = "CN=MacsEncryption"
      validity_in_months = 12
    }
  }
}*/

# Generate Root Password for MSSQL
resource "random_string" "mysql_root_password" {
  length  = 24
  special = false
}

# Save SQL Password
resource "azurerm_key_vault_secret" "sql_root" {
  name      = "MySQLRootPW"
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
  name      = "MySqlUserPW"
  value     = "${random_string.macs_datauser_password.result}"
  vault_uri = "${azurerm_key_vault.macs_vault.vault_uri}"
  content_type = "string"
  depends_on = ["random_string.macs_datauser_password"]
}

resource "null_resource" "create_ssh_key" {
    provisioner "local-exec" {
      interpreter = ["/bin/bash", "-c"]
      command = "ssh-keygen -t rsa -b 4096 -f macscampingarea -C 'MacsCampingAreaVM' -q -N ''"
      when = "create"
    }
}

/*resource "azurerm_key_vault_secret" "macs_ssh_privatekey" {
  name = "MacsSSHPrivateKey"
  value = "${file("${path.cwd}/macscampingarea")}"
  vault_uri = "${azurerm_key_vault.macs_vault.vault_uri}"
  content_type = "private-key"
  depends_on = ["null_resource.create_ssh_key"]
}*/

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
