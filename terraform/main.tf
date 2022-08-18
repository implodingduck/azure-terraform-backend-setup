terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.18.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.1.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}

resource "random_string" "unique" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-tf-be-${random_string.unique.result}"
  location = var.location
}

resource "azurerm_storage_account" "sa" {
  name                     = "satfbe${random_string.unique.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_key_vault" "kv" {
  name                        = "kv-tf-be-${random_string.unique.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

resource "azurerm_key_vault_access_policy" "spn" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge"
  ]
}

resource "azurerm_key_vault_secret" "container" {
  depends_on = [
    azurerm_key_vault_access_policy.spn
  ]
  name         = "container-name"
  value        = azurerm_storage_container.state.name
  key_vault_id = azurerm_key_vault.kv.id
}


resource "azurerm_key_vault_secret" "rg" {
  depends_on = [
    azurerm_key_vault_access_policy.spn
  ]
  name         = "resource-group-name"
  value        = azurerm_resource_group.rg.name
  key_vault_id = azurerm_key_vault.kv.id
}


resource "azurerm_key_vault_secret" "sa" {
  depends_on = [
    azurerm_key_vault_access_policy.spn
  ]
  name         = "storage-account-name"
  value        = azurerm_storage_account.sa.name
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "subscription" {
  depends_on = [
    azurerm_key_vault_access_policy.spn
  ]
  name         = "subscription-id"
  value        = data.azurerm_client_config.current.subscription_id
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "clientid" {
  depends_on = [
    azurerm_key_vault_access_policy.spn
  ]
  name         = "ARM-CLIENT-ID"
  value        = data.azurerm_client_config.current.client_id
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "tenantid" {
  depends_on = [
    azurerm_key_vault_access_policy.spn
  ]
  name         = "ARM-TENANT-ID"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.kv.id
}