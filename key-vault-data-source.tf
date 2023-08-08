# Get the admin password from AZ key vault

data "azurerm_key_vault" "AKV" {

    name = "KeyVault5002"
    resource_group_name = "eg-keys"
}


data "azurerm_key_vault_secret" "secret" {


    name = "owe"

    key_vault_id = data.azurerm_key_vault.AKV.id


}

