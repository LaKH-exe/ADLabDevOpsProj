# To change the number of VMs to created, change the resources_name and number_of_resources variables.
# error: Error: Incorrect attribute value type
# │
# │   on provider.tf line 72, in resource "azurerm_network_interface" "nic":
# │   72:     subnet_id = azurerm_virtual_network.main_net.*.subnet.id
# │     ├────────────────
# │     │ azurerm_virtual_network.main_net is object with 14 attributes
# │
# │ Inappropriate value for attribute "subnet_id": string required.

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.66.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
features {}
}

# create the resource group
resource "azurerm_resource_group" "main_rg" {

  name     = var.rg
  location = var.location

}
# Create the Vnet
resource "azurerm_virtual_network" "main_net" {

  name                = "vnet-ADLab"
  resource_group_name = var.rg
  address_space       = ["10.0.0.0/24"]
  location            = var.location
  tags = {
    Env    = "Lab",
    Region = "East US"

  }

  subnet {

    name = "snet-ADLab"
    address_prefix = "10.0.2.0/24"

  }
}
# create public ip

resource "azurerm_public_ip" "pip" {
  count               = var.number_of_resources
  name                = "pip-${element(var.resources_name, count.index)}"
  resource_group_name = var.rg
  allocation_method   = "Dynamic"
  location = var.location
 tags = {
    Env    = "Lab",
    Region = "East US"

  }
}


# create a network interface to attach to the vm

resource "azurerm_network_interface" "nic" {
  count = var.number_of_resources
  name  = "nic-${element(var.resources_name, count.index)}"

  location            = var.location
  resource_group_name = var.rg

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_virtual_network.main_net.*.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_network_security_group" "main-nsg" {
  name                = "main-nsg"
  location            = var.location
  resource_group_name = var.rg
   count = var.number_of_resources
  # RDP
  security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  # WinRM
  security_rule {
    name                       = "Allow-WinRM"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


# resource "azurerm_network_interface_security_group_association" "example" {
#   count = var.number_of_resources
#   network_interface_id      =  [element(azurerm_network_interface.nic.*.id, count.index)]
#   network_security_group_id = azurerm_network_security_group.main-nsg[count.index]
# }

# resource "azurerm_network_interface_security_group_association" "example" {
#   for_each = toset(azurerm_network_interface.nic.*.id)
#   network_interface_id      = each.value
#   network_security_group_id = azurerm_network_security_group.main-nsg.id
# }

resource "azurerm_network_interface_security_group_association" "example" {
  count = var.number_of_resources
  network_interface_id      =  element(azurerm_network_interface.nic.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.main-nsg[count.index].id
}

resource "azurerm_windows_virtual_machine" "VMs"{
# get the admin pass from key vault
count = var.number_of_resources
admin_username = "owa"
admin_password = data.azurerm_key_vault_secret.secret.value
name = "VM-${element(var.resources_name, count.index)}"
resource_group_name = var.rg

location = var.location

network_interface_ids =  [element(azurerm_network_interface.nic.*.id, count.index)]

size = "Standard_D4_v3"

os_disk {

  caching = "ReadWrite"
  storage_account_type = "StandardSSD_LRS"
}

 source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

 tags = {
    Env    = "Lab",
    Region = "East US"

  }

}





