resource "azurerm_storage_account" "state" {
  name                     = "atlantisstate"
  resource_group_name      = azurerm_resource_group.default.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "state" {
  name                  = "state"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}
