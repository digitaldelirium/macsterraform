variable "resourcename" {
  default = "macscampinggroup"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "9661a81b-1bc6-4836-ad63-41ddb2515f1b"
    client_id       = "44c4e2a1-4b32-4d7b-b063-ab00907ab449"
    tenant_id       = "ce30a824-b64b-4702-b3e8-8ff93ba9da38"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "macsterraformgroup" {
    name     = "macscampinggroup"
    location = "eastus"

    tags {
        environment = "Mac's Camping Area"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "macsterraformnetwork" {
    name                = "macsVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
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
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.macsterraformgroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "Mac's Camping Area"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "macsterraformnsg" {
    name                = "macsNetworkSecurityGroup"
    location            = "eastus"
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
    location                  = "eastus"
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
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "Mac's Camping Area"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "macsterraformvm" {
    name                  = "macsvm"
    location              = "eastus"
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
        custom_data    = <<-EOF
                            #cloud-init
                            apt:
                              primary:
                                - arches: [default]
                                  uri: https://download.docker.com/linux/ubuntu

                            package_upgrade: true
                            packages:
                              - apt-utils
                              - software-properties-common
                              - docker-ce

                            ssh_authorized_keys:
                              - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdrExWQTnGoTgZJhgaPaUVymOJOnrVeFSPeQpeqhCdEL1r1G6QgpRrDXKB0WDZ+n3hbiI0m2EEvxcxGMQ0GV4h1HmApaM0dJmmhhfPr6LFwopyJoDJ3OkYJYkgnVOz4PE/8MnadPswno/wKXu+xPB7P5m729Lrr3yShNl8ySAWuRIDPxO4NX8jK4JZMdhSyK7eyvpqBDcpUzBk4wdLL+p4RJwT0cNZANrVIugSS+jMWNndvX0HlerCBzfWgmciC7IM1RhCmn0EQGVmEaSKigIFTdwsFs3xF4Q6iaGdqdp2uaAN/R5QDJaJkMLhkT6pk9HHjGMje+Qb+EOV2jKUKImMIl6HGtAjJz5/0ohWdhyica0xsdlnMJ+p/A4NtCbHz2zHFojQ1RlYxqGBlDsZm1Zvz0yNNaz5utwpyc14VociYR+QzK64iO+j/thaFtM93J0/BXpLbJm+6AmJXVjHkdr6CiM92gQpOQaBdRvRMN7TPZP5cH33su4tnEFcs3OgUfm2FLHrzfzZt1URaeUi0epD7dtC7lqkzTHzTT8Asp+rrSobDNZaD0zIJ5UQYDM5fS3nX0TSRB7x7pffvmYA+IZ93tpgNwxAsas5X05/i8F/Cp5rLowFjt0AOAgafKWiVgU0UNTrrS6G4Dlx8J8Y2QdyhKLNexNBmT25BESCkl9ZKw== ian@Easley

                            ca-certs:
                              remove-defaults: false
                              trusted:
                              - |
                              -----BEGIN CERTIFICATE-----
                            MIIF4DCCA8igAwIBAgIFFRKJiIgwDQYJKoZIhvcNAQELBQAwdDELMAkGA1UEBhMC
                            VVMxEzARBgNVBAgMCldhc2hpbmd0b24xEjAQBgNVBAcMCVNob3JlbGluZTElMCMG
                            A1UECgwcRGlnaXRhbERlbGlyaXVtIFRlY2hub2xvZ2llczEVMBMGA1UEAwwMRGVs
                            aXJpdW1Sb290MB4XDTE3MTIxMjA1NTU0NVoXDTI3MTIxMDA1NTU0NVowgYYxCzAJ
                            BgNVBAYTAlVTMRMwEQYDVQQIDApXYXNoaW5ndG9uMSUwIwYDVQQKDBxEaWdpdGFs
                            RGVsaXJpdW0gVGVjaG5vbG9naWVzMRMwEQYDVQQDDApEZWxpcml1bUNBMSYwJAYJ
                            KoZIhvcNAQkBFhdpYW4uY29ybmV0dEBvdXRsb29rLmNvbTCCAiIwDQYJKoZIhvcN
                            AQEBBQADggIPADCCAgoCggIBAKcF4KessV+gGYRd5iDnwm8SHwur1yZBux/Qo+gK
                            L4h5ZMhW2pxYZMs4NpyJrgkiGdJn4DDyugx5oiP0KEbMR3h3OG4WIA0oA8Abe39j
                            6xy/i7Dw/mDPogW2gQC/b6zkqPQWcGrcnWkFWqwhXcExobwjZDVP7/cSd9S57M0r
                            HKLkkhnZ09fve72RjodCsS4ED3bPNs3A68KRYrOyqtBp5BqCCjb9mouCB4Vo14Qa
                            tJfDMxVBy6U/76b3UN2E3W8x9e+AY7d5GfE7r1r8qHSVON7oWuvAxecPZefJeY0f
                            Xxa2mhx1xgkdxo2WZ7g+dMKAlQUElHtpaT+Fz24YqrLlqbgD9AGUVztMatD2x4O0
                            Q/5x2X3Isr2ezq/vHR63or8ztmKs4yUPgTXkujxCYK5Q+HYtBuQ748LOPrk4cph+
                            /1ozKAvtOsYEc+A+2C8VuvPci8E0GPK1QJbQSd83Ghl1wFlHlLsKt9UInHGjGuyY
                            7639spjjQ+CyTonEnYJZTh8rxchRyOJYfOxYqtyPn/VC4KQPU91ZM6V+UDmEKry6
                            yibynPR8+Z3fI38OGWmR5QuHB9spBbU4y/tmVD3hhTiMA8Q3NxUD2t6KJr+oq19L
                            u9vu9FW5bmNs5PBBP0oiFY6vkeQXuQrTFAOK3u/u0caewZD2jlTgn6U9lLtxj9jU
                            Yhg1AgMBAAGjZjBkMB0GA1UdDgQWBBTwkz5puiMLFvq4gBvozJTmXm6BUTAfBgNV
                            HSMEGDAWgBQcIyOBoARS3OSemltdi7dIJhBQyzASBgNVHRMBAf8ECDAGAQH/AgEA
                            MA4GA1UdDwEB/wQEAwIBhjANBgkqhkiG9w0BAQsFAAOCAgEAILAVzq/mm5/UBeFu
                            NODHlRfNdn/EQGl1EjFPPgwNfLWw3HbzauzUn4Bv1TV2cMJJDzPfCtxFHWGXkAKh
                            zgU4iW4bAgCITo0ewq1e76bMySOwJyQXAjyqGX9U+uEcyR/WPXFY32/l/Du8R0ar
                            55ZHGNMVLhiNt1cObeu9fQP4zYYRYRxC1IGfJaQkqgStZ72Pd81pvbsnQvwGvPA/
                            fvw8DrNOAKERBiEkiPblh3A1uS/kJt26hwG5QJaCMc1U6ayx6JEB3cmMXixPlAFn
                            5ngc4NXGl/ewe+3jvG7f6xP/TH8az0hkhS6o0ogq5c3qxbC2cUH8dbe8/QSB5L9J
                            10NbqRQ6nt+RsBm0JiFPcdRQx71x7k7YhqGwaQTxzI2kAXb92yTqVSfSBfWuJ1jl
                            GWdKQsBrlC+v2nLK9/g85WP7tH9MVF9CWrBbHwrLZwLLf0eayWQLDC5avvzQilqS
                            zadyPyMi4kgon+NWoO+A5FWZYd3dykCOdApHrIvM/1L5a3T/CIg9h18TL/R1tznO
                            y1Yg+sv/2xKLgmRD0G/3xWNp5aB9093Kgv/WkFRM5Xkp87PsxaLfDLTtuiMKRw2J
                            ybOAwhIt3gr8Hxke7Mt0aYmvoUL3Qf1fuRq4lvhr5IJEcUwZzeXRquzhtLbRHP/q
                            eFDbcw5hwiL6PfJyCvShgWnGVcU=
                            -----END CERTIFICATE-----
                          write_files:
                          - content: <<-EOF
                          #! /bin/bash
                          docker volume create portainer_data
                          docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data --name portainer --restart=always portainer/portainer
                          EOF
                          runcmd:
                                            EOF
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
          path     = "/home/macsuser/.ssh/authorized_keys"
          key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdrExWQTnGoTgZJhgaPaUVymOJOnrVeFSPeQpeqhCdEL1r1G6QgpRrDXKB0WDZ+n3hbiI0m2EEvxcxGMQ0GV4h1HmApaM0dJmmhhfPr6LFwopyJoDJ3OkYJYkgnVOz4PE/8MnadPswno/wKXu+xPB7P5m729Lrr3yShNl8ySAWuRIDPxO4NX8jK4JZMdhSyK7eyvpqBDcpUzBk4wdLL+p4RJwT0cNZANrVIugSS+jMWNndvX0HlerCBzfWgmciC7IM1RhCmn0EQGVmEaSKigIFTdwsFs3xF4Q6iaGdqdp2uaAN/R5QDJaJkMLhkT6pk9HHjGMje+Qb+EOV2jKUKImMIl6HGtAjJz5/0ohWdhyica0xsdlnMJ+p/A4NtCbHz2zHFojQ1RlYxqGBlDsZm1Zvz0yNNaz5utwpyc14VociYR+QzK64iO+j/thaFtM93J0/BXpLbJm+6AmJXVjHkdr6CiM92gQpOQaBdRvRMN7TPZP5cH33su4tnEFcs3OgUfm2FLHrzfzZt1URaeUi0epD7dtC7lqkzTHzTT8Asp+rrSobDNZaD0zIJ5UQYDM5fS3nX0TSRB7x7pffvmYA+IZ93tpgNwxAsas5X05/i8F/Cp5rLowFjt0AOAgafKWiVgU0UNTrrS6G4Dlx8J8Y2QdyhKLNexNBmT25BESCkl9ZKw== ian@Easley"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.macsstorageaccount.primary_blob_endpoint}"
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
  type                 = "ManagedIdentityExtensionForWindows"
  type_handler_version = "1.0"
  location             = "eastus"
  resource_group_name  = "${var.resourcename}"

  settings = <<SETTINGS
    {
        "port": 50342
    }
SETTINGS
}

resource "azurerm_key_vault" "MacsResource" {
   name = "macscampvault"
   location = "eastus"
   resource_group_name = "${azurerm_resource_group.macsterraformgroup.name}"

   sku {
       name = "standard"
   }

   tenant_id = "ce30a824-b64b-4702-b3e8-8ff93ba9da38"

   access_policy {
       tenant_id = "ce30a824-b64b-4702-b3e8-8ff93ba9da38"
       object_id = "6e1ed4eb-026a-424c-8c03-b87418b69c6e"
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
           "restore"
       ]
       secret_permissions = [
           "get",
           "list",
           "set",
           "delete",
           "recover",
           "backup",
           "restore"
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
         "deleteissuers"
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
      "restore"
    ]

    secret_permissions = [
      "get",
      "list",
      "set",
      "delete",
      "recover",
      "backup",
      "restore"
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
      "deleteissuers"
    ]
   }

  enabled_for_disk_encryption = true
  enabled_for_template_deployment = true
  enabled_for_deployment = true
}

resource "azurerm_storage_container" "macs_state" {
   name = "tfstate"
   resource_group_name = "macscampinggroup"
   storage_account_name = "${azurerm_storage_account.macsstorageaccount.name}"
   container_access_type = "private"
}

data "azurerm_resource_group" "macs_resources" {
    name = "macscampinggroup"
    depends_on = ["azurerm_resource_group.macsterraformgroup"]
}

data "azurerm_subscription" "current" {
    subscription_id = "9661a81b-1bc6-4836-ad63-41ddb2515f1b"
}