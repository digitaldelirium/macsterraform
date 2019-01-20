locals {
  long_name = "${var.project_name}-${var.environment_name}"
}


data "azurerm_resource_group" "rg" {
    name = "${local.long_name}"
}

data "azurerm_storage_account" "storage_acct" {
  name = "${var.project_name}${var.environment_name}"
  resource_group_name = "${local.long_name}"
}


resource "azurerm_app_service_plan" "consumption" {
  name = "${local.long_name}"
  location = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  kind = "FunctionApp"

  sku {
      tier = "Dynamic"
      size = "Y1"
  }
}

resource "azurerm_storage_container" "function-diag" {
  name = "${local.long_name}-functions-diag"
  resource_group_name = "${local.long_name}"
  storage_account_name = "${data.azurerm_storage_account.storage_acct.name}"
}

resource "azurerm_function_app" "monitors" {
  name = "${local.long_name}-monitors"
  resource_group_name = "${local.long_name}"
  app_service_plan_id = "${azurerm_app_service_plan.consumption.id}"
  storage_connection_string = "${data.azurerm_storage_account.storage_acct.primary_connection_string}"
  version = 2

  identity {
      type = "SystemAssigned"
  }
}

resource "azurerm_function_app" "functions" {
  name = "${local.long_name}-functions"
  resource_group_name = "${local.long_name}"
  app_service_plan_id = "${azurerm_app_service_plan.consumption.id}"
  storage_connection_string = "${data.azurerm_storage_account.storage_acct.primary_connection_string}"
  version = 2
  https_only = true
  

  identity {
      type = "SystemAssigned"
  }
}
