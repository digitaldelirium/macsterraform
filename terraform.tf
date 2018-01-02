variable "resourcename" {
  default = "macscampinggroup"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    client_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    client_secret   = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    tenant_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "macsterraformgroup" {
    name     = "macscampinggroup"
    location = "Canada East"

    tags {
        environment = "Mac's Camping Area"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "macsterraformnetwork" {
    name                = "macsVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "Canada East"
    resource_group_name = "${azurerm_resource_group.macsterraformgroup.name}"

    tags {
        environment = "Mac's Camping Area"
    }
}

# Create subnet
resource "azurerm_subnet" "macsterraformsubnet" {
    name                 = "macsSubnet"
    resource_group_name  = "${azurerm_resource_group.macsterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.macsterraformnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "macsterraformpublicip" {
    name                         = "macsPublicIP"
    location                     = "Canada East"
    resource_group_name          = "${azurerm_resource_group.macsterraformgroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "Mac's Camping Area"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "macsterraformnsg" {
    name                = "macsNetworkSecurityGroup"
    location            = "Canada East"
    resource_group_name = "${azurerm_resource_group.macsterraformgroup.name}"

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

/*    security_rule {
        name                       = "Docker"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "2375"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    } */

    tags {
        environment = "Mac's Camping Area"
    }
}


# Create network interface
resource "azurerm_network_interface" "macsterraformnic" {
    name                      = "macsNIC"
    location                  = "Canada East"
    resource_group_name       = "${azurerm_resource_group.macsterraformgroup.name}"
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
        resource_group = "${azurerm_resource_group.macsterraformgroup.name}"
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "macsstorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.macsterraformgroup.name}"
    location                    = "Canada East"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "Mac's Camping Area"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "macsterraformvm" {
    name                  = "macsvm"
    location              = "Canada East"
    resource_group_name   = "${azurerm_resource_group.macsterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.macsterraformnic.id}"]
    vm_size               = "Standard_B1MS"

    storage_os_disk {
        name              = "macsOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "macsvm"
        admin_username = "macsuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/macsuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3Nz{snip}hwhqT9h"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.macsstorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Mac's Camping Area"
    }
}