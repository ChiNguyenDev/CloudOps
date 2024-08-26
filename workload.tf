resource "azurerm_resource_group" "applicationgroup" {
  name     = "app-${module.naming.resource_group.name}"
  location = "West Europe"
  tags = local.common_tags
}

locals {
  common_tags = {
    project = "azrinfra"
    environment = var.environment_decleration
  }
}

locals {
  vms = {
    vm1 = {
      backup_policy_name = "vm_weekly_1h"
      admin_username     = "chi.nguyen"
      admin_password     = module.keyvault.vm_password_secret
      nic = {
        ip_config = {
          name       = "internal"
          subnet_key = "app"
          public_ip = {
            allocation_method = "Static"
          }
        }
      }
    }
    vm2 = {
      backup_policy_name = "vm_weekly_1h"
      admin_username     = "chi.nguyen"
      admin_password     = module.keyvault.vm_password_secret
      nic = {
        ip_config = {
          subnet_key = "app"
          public_ip = {
            allocation_method = "Static"
          }
        }
      }
    }
  }
}


module "vm" {
  source   = "./modules/vm/"
  // iterates over vm's defined as locals and creates instances
  for_each = local.vms
  resource_group   = azurerm_resource_group.applicationgroup.name
  location         = azurerm_resource_group.applicationgroup.location
  configuration    = each.value
  subnet_reference = module.network.subnet_reference
  naming = module.naming
  tags = local.common_tags

  vm_name = each.key
  environment_decleration = var.environment_decleration
}

module "naming" {
  source  = "Azure/naming/azurerm"
  suffix = [ var.environment_decleration ]
  prefix = [ "cl-ops" ]
}
