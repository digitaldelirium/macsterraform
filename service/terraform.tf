data "terraform_remote_state" "state" {
  backend = "azurerm"
  config {
    storage_account_name = "macsstatestorage"
    container_name = "tfstate"
    key = "prod.state.tfstate"
    access_key = "${var.access_key}"
  }
}

data "azurerm_resource_group" "macsvaultgroup" {
  name = "${data.terraform_remote_state.state.resource_group}"
}

data "azurerm_subscription" "current" { }

# Create virtual network
resource "azurerm_virtual_network" "macsterraformnetwork" {
  name                = "macsVnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = "${data.terraform_remote_state.state.resource_group}"

  tags {
    environment = "Mac's Camping Area"
  }
}

# Create subnet
resource "azurerm_subnet" "macsterraformsubnet" {
  name                 = "macsSubnet"
  resource_group_name  = "${data.terraform_remote_state.state.resource_group}"
  virtual_network_name = "${azurerm_virtual_network.macsterraformnetwork.name}"
  address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "macsterraformpublicip" {
  name                         = "macsPublicIP"
  location                     = "eastus"
  resource_group_name          = "${data.terraform_remote_state.state.resource_group}"
  public_ip_address_allocation = "dynamic"

  tags {
    environment = "Mac's Camping Area"
  }
}

# Get Public IP datasource
data "azurerm_public_ip" "selected" {
  name = "${azurerm_public_ip.macsterraformpublicip.name}"
  resource_group_name = "${data.terraform_remote_state.state.resource_group}"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "macsterraformnsg" {
  name                = "macsNetworkSecurityGroup"
  location            = "eastus"
  resource_group_name = "${data.terraform_remote_state.state.resource_group}"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Docker"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2376"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "Mac's Camping Area"
  }
}

# Create network interface
resource "azurerm_network_interface" "macsterraformnic" {
  name                      = "macsNIC"
  location                  = "eastus"
  resource_group_name       = "${data.terraform_remote_state.state.resource_group}"
  network_security_group_id = "${azurerm_network_security_group.macsterraformnsg.id}"

  ip_configuration {
    name                          = "macsNicConfiguration"
    subnet_id                     = "${azurerm_subnet.macsterraformsubnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.macsterraformpublicip.id}"
  }

  tags {
    environment = "Mac's Camping Area"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${data.terraform_remote_state.state.resource_group}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "macsdiagstorage" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${data.terraform_remote_state.state.resource_group}"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    environment = "Mac's Camping Area"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "macsterraformvm" {
  name                  = "macsvm"
  location              = "eastus"
  resource_group_name   = "${data.terraform_remote_state.state.resource_group}"
  network_interface_ids = ["${azurerm_network_interface.macsterraformnic.id}"]
  vm_size               = "Standard_B1MS"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = "macsOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    os_type           = "linux"
    disk_size_gb      = 32
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "macsvm"
    admin_username = "macs"

    custom_data = "${file("cloud-init.txt")}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/macs/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCpWJ3lqjUnkcmuz7mqZyzLBa01ZY5g/GrbbLUCjFTPI1EWST+WDeRAAvHXiaAmFKxyo6kRToF9equyewHF9xESD0NL7NaEx7brTLeqfMzK1eHKM6T+D+6RIJuuBoZ9C7dmofdJADpGx4UoGoHy4rG1XdnF6kxAIB5/CGnA/7B8NWNWM8Bj//VOCp8BzD3IsXVDF1sAg0oyBN8wuNO1wt+IIliTSuUGQQPcPHlQ52bL0xUY/6KT1Tf0hf6DxIeE8lFuJM2CIcDMvmLVW0boAZDY1gQtIF+6Yr3dH25oziMwp7la010ZhD8UQQMem4iotDRem0W2IvjK5uh0DiWBJ3NQHUmMNjxHm4xCQGxOK3zRn/LPU5WHqR4UOzZ+j+2R3g/KVW9A+FHa7B5lo4fp2XCvdmHZSHA9h7RxQF8TcuHctUrzthOklCtY2Xb3Q/J3XRB8tnjUvpmzSlUxv5iweJt4hYyysdm/0nzhya7D6HskLOz1PZLTTA683VcCvX3vi8O+st84seA6XZBC/VAXsjZ44NxdrZe2tuW8tTuktWyZWOkEA2GnWi2d3YQoElCl5WTHrhyzGbpBOqoCTuX5QGluLsOepHjFeUwBlsnjGRHimeZIhajKjvIYp61v1TLgiG6nFZuKgS67VdYM76mCSA1BiOFue/hXAGv/7RJuraGY6Q== ian@Easley"
    }

    ssh_keys {
      path     = "/home/macs/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdrExWQTnGoTgZJhgaPaUVymOJOnrVeFSPeQpeqhCdEL1r1G6QgpRrDXKB0WDZ+n3hbiI0m2EEvxcxGMQ0GV4h1HmApaM0dJmmhhfPr6LFwopyJoDJ3OkYJYkgnVOz4PE/8MnadPswno/wKXu+xPB7P5m729Lrr3yShNl8ySAWuRIDPxO4NX8jK4JZMdhSyK7eyvpqBDcpUzBk4wdLL+p4RJwT0cNZANrVIugSS+jMWNndvX0HlerCBzfWgmciC7IM1RhCmn0EQGVmEaSKigIFTdwsFs3xF4Q6iaGdqdp2uaAN/R5QDJaJkMLhkT6pk9HHjGMje+Qb+EOV2jKUKImMIl6HGtAjJz5/0ohWdhyica0xsdlnMJ+p/A4NtCbHz2zHFojQ1RlYxqGBlDsZm1Zvz0yNNaz5utwpyc14VociYR+QzK64iO+j/thaFtM93J0/BXpLbJm+6AmJXVjHkdr6CiM92gQpOQaBdRvRMN7TPZP5cH33su4tnEFcs3OgUfm2FLHrzfzZt1URaeUi0epD7dtC7lqkzTHzTT8Asp+rrSobDNZaD0zIJ5UQYDM5fS3nX0TSRB7x7pffvmYA+IZ93tpgNwxAsas5X05/i8F/Cp5rLowFjt0AOAgafKWiVgU0UNTrrS6G4Dlx8J8Y2QdyhKLNexNBmT25BESCkl9ZKw== ian@Easley"
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.macsdiagstorage.primary_blob_endpoint}"
  }

  tags {
    environment = "Mac's Camping Area"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_virtual_machine_extension" "msi" {
  name                 = "macsvm"
  virtual_machine_name = "${azurerm_virtual_machine.macsterraformvm.name}"
  publisher            = "Microsoft.ManagedIdentity"
  type                 = "ManagedIdentityExtensionForLinux"
  type_handler_version = "1.0"
  location             = "eastus"
  resource_group_name  = "${data.terraform_remote_state.state.resource_group}"

  settings = <<SETTINGS
    {
        "port": 50342
    }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "macsDockerExt" {
   name = "macsDocker"
   location = "eastus"
  resource_group_name  = "${data.terraform_remote_state.state.resource_group}"
   virtual_machine_name = "${azurerm_virtual_machine.macsterraformvm.name}"
   publisher = "Microsoft.Azure.Extensions"
   type = "DockerExtension"
   type_handler_version = "1.1"

  settings = <<SETTINGS
  {
      "dockerPort": 2376
  }
  SETTINGS

  protected_settings = <<SETTINGS
  {
      "dockerCACert": "${base64encode(file("intermediate.cert.pem"))}",
      "dockerServerCert": "${base64encode(file("macscampingarea.crt"))}",
      "dockerServerKey": "${base64encode(file("macscampingarea.key"))}"
  }
  SETTINGS
}

resource "azurerm_virtual_machine_extension" "myNetworkWatcher" {
   name = "my_NetworkWatcher"
   location = "eastus"
  resource_group_name  = "${data.terraform_remote_state.state.resource_group}"
   virtual_machine_name = "${azurerm_virtual_machine.macsterraformvm.name}"
   publisher = "Microsoft.Azure.NetworkWatcher"
   type = "NetworkWatcherAgentLinux"
   type_handler_version = "1.4"
}

resource "azurerm_key_vault" "macsvault" {
  name                = "macscampvault"
  location            = "eastus"
  resource_group_name = "${data.terraform_remote_state.state.resource_group}"

  sku {
    name = "standard"
  }

  tenant_id = "ce30a824-b64b-4702-b3e8-8ff93ba9da38"

  access_policy {
    tenant_id      = "ce30a824-b64b-4702-b3e8-8ff93ba9da38"
    object_id      = "6e1ed4eb-026a-424c-8c03-b87418b69c6e"
    application_id = "44c4e2a1-4b32-4d7b-b063-ab00907ab449"

    key_permissions = [
      "get",
      "list",
      "update",
      "create",
      "import",
      "delete",
      "recover",
      "backup",
      "restore",
    ]

    secret_permissions = [
      "get",
      "list",
      "set",
      "delete",
      "recover",
      "backup",
      "restore",
    ]

    certificate_permissions = [
      "get",
      "list",
      "update",
      "create",
      "import",
      "delete",
      "managecontacts",
      "manageissuers",
      "getissuers",
      "listissuers",
      "setissuers",
      "deleteissuers",
    ]
  }

  access_policy {
    tenant_id = "ce30a824-b64b-4702-b3e8-8ff93ba9da38"
    object_id = "1714df59-7463-4437-9478-b126a07a1187"

    key_permissions = [
      "get",
      "list",
      "update",
      "create",
      "import",
      "delete",
      "recover",
      "backup",
      "restore",
    ]

    secret_permissions = [
      "get",
      "list",
      "set",
      "delete",
      "recover",
      "backup",
      "restore",
    ]

    certificate_permissions = [
      "get",
      "list",
      "update",
      "create",
      "import",
      "delete",
      "managecontacts",
      "manageissuers",
      "getissuers",
      "listissuers",
      "setissuers",
      "deleteissuers",
    ]
  }

  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  enabled_for_deployment          = true

  lifecycle {
    prevent_destroy = true
  }
}

terraform {
  backend "azurerm" {
    storage_account_name = "macsstatestorage"
    container_name = "tfstate"
    key = "prod.service.tfstate"
  }
}