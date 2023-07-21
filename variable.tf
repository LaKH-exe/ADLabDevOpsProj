variable "rg" {
description = "The default resource group for this proj"
type = string   
default = "rg_ADLab"

}

variable "location"{

    description = "the default location for this proj"
    type = string
    default = "East US"

}


variable "resources_name" {
    type = list(string)
    default = [ "DC","Client1", "Client2" ]
  
}


variable "number_of_resources"{
    type = number

    default = 3
}