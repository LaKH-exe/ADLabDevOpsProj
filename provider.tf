# To change the number of VMs to created, change the resources_name and number_of_resources variables.


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
  allocation_method   = "dynamic"

 tags = {
    Env    = "Lab",
    Region = "East US"

  }
}


# create a network interface to attach to the vm

resource "azurerm_network_interface" "nic" {
  count = var.number_of_resources
  name  = "nic-${element(var.resourcese_name, count.index)}"

  location            = var.location
  resource_group_name = var.rg

  ip_configuration {
    subnet_id = main_net.subnet[0].id
  }


resource "azurerm_windows_virtual_machine" "VMs"{
# get the admin pass from key vault
admin_username = "owa"
admin_password = data.azurerm_key_vault_secret.secret.value
name = "VM-${element(var.resources_name, count.index)}"
resource_group_name = var.rg

location = var.location

network_interface_ids = network_interface_ids.nic[var.resources_name[count.index]]

size = "Standard_D4_v3"

os_disk {

  caching = "ReadWrite"
  storage_account_type = "StandardSSD_LRS"
}


 tags = {
    Env    = "Lab",
    Region = "East US"

  }

}




}
