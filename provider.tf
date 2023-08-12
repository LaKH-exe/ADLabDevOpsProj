# To change the number of VMs to created, change the resources_name and number_of_resources variables.


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.66.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {} # Added this block to enable the provider features
}

# create the resource group
resource "azurerm_resource_group" "main_rg" {

  name     = var.rg
  location = var.location

}
# Create the Vnet
resource "azurerm_virtual_network" "main_net" {

  name                = "vnet-ADLab"
  resource_group_name = azurerm_resource_group.main_rg.name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  tags = {
    Env    = "Lab",
    Region = "East US"

  }

  subnet {

    name           = "snet-ADLab"
    address_prefix = "10.0.0.0/24"

  }
}
# create public ip

resource "azurerm_public_ip" "pip" {
  count               = var.number_of_resources
  name                = "pip-${element(var.resources_name, count.index)}"
  resource_group_name = azurerm_resource_group.main_rg.name
  allocation_method   = "Dynamic"
  location            = var.location
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
  resource_group_name = azurerm_resource_group.main_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = tolist(azurerm_virtual_network.main_net.subnet)[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = element(azurerm_public_ip.pip.*.name, count.index)
  }
}


resource "azurerm_network_security_group" "main-nsg" {
  name                = "main-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main_rg.name
  count               = var.number_of_resources
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


resource "azurerm_network_interface_security_group_association" "example" {
  count                     = var.number_of_resources
  network_interface_id      = element(azurerm_network_interface.nic.*.id, count.index) # Removed the square brackets around the element function
  network_security_group_id = azurerm_network_security_group.main-nsg[count.index].id  # Added the count.index suffix to the network_security_group_id argument
}

resource "azurerm_windows_virtual_machine" "VMs" {
  # get the admin pass from key vault
  count               = var.number_of_resources
  admin_username      = "owa"
  admin_password      = data.azurerm_key_vault_secret.secret.value
  name                = "VM-${element(var.resources_name, count.index)}"
  resource_group_name = azurerm_resource_group.main_rg.name

  location              = var.location
  network_interface_ids = [element(azurerm_network_interface.nic.*.id, count.index)] # Removed the square brackets around the element function

  size = "Standard_D4_v3"

  os_disk {

    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"

  }

  source_image_reference {
    publisher = var.resources_name[count.index] == "DC" ? "MicrosoftWindowsServer" : "MicrosoftWindowsDesktop"
    offer     = var.resources_name[count.index] == "DC" ? "WindowsServer" : "windows10preview"
    sku       = var.resources_name[count.index] == "DC" ? "2019-Datacenter" : "win10-22h2-pro"
    version   = "latest"
  }


   tags = {
    Env    = "Lab",
    Region = "East US"
    Type = var.resources_name[count.index] == "DC" ? "DC" : "Client"



  }
}
