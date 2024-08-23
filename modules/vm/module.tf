resource "azurerm_public_ip" "t-publicip" {
  count = var.configuration.nic.ip_config.public_ip != null ? 1 : 0

  name                = var.configuration.nic.ip_config.public_ip.name
  resource_group_name = var.resource_group
  location            = var.location
  allocation_method   = var.configuration.nic.ip_config.public_ip.allocation_method
  sku = var.configuration.nic.ip_config.public_ip.sku
}

resource "azurerm_network_interface" "t-interface" {
  name                = var.configuration.nic.name
  location            = var.location
  resource_group_name = var.resource_group
  ip_configuration {
    name                          = var.configuration.nic.ip_config.name
    subnet_id                     = var.subnet_reference[var.configuration.nic.ip_config.subnet_key].id
    private_ip_address_allocation = var.configuration.nic.ip_config.private_ip_address_allocation
    /*
    Erste Möglichkeit:
    public_ip_address_id          = length(azurerm_public_ip.t-publicip) > 0 ? azurerm_public_ip.t-publicip.0.id : null
    */
    public_ip_address_id = one(azurerm_public_ip.t-publicip.*.id)
  }
}

resource "azurerm_windows_virtual_machine" "t-vm" {
  name                = var.configuration.name
  resource_group_name = var.resource_group
  location            = var.location
  size                = var.configuration.size
  admin_username      = var.configuration.admin_username
  admin_password      = var.configuration.admin_password
  network_interface_ids = [
    azurerm_network_interface.t-interface.id,
  ]
  os_disk {
    caching              = var.configuration.os_disk.caching
    storage_account_type = var.configuration.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = var.configuration.source_image_reference.publisher
    offer     = var.configuration.source_image_reference.offer
    sku       = var.configuration.source_image_reference.sku
    version   = var.configuration.source_image_reference.version
  }
  lifecycle {
    precondition {
        condition = strcontains(var.configuration.os_disk.storage_account_type, "LRS")
        error_message = "OS Disk should be a LRS - currently: ${var.configuration.os_disk.storage_account_type}"
    }
  }
}

/*
//Prüft ob OS_Disk eine SSD ist
check "t-vm" {
    assert{
        condition = strcontains(var.configuration.os_disk.storage_account_type, "SSD")
        error_message = "OS Disk should be a SSD - currently: ${var.configuration.os_disk.storage_account_type}"
    }
}
*/
