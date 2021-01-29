provider "azurerm" {
  version = "~>2.0"
  features {}
}

# Create Azure Resource Group
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "${var.resource_group_name}"
    location = "${var.resource_group_location}"

    tags = {
        environment = "Terraform Demo"
    }
}
# Create Azure Vnet and  Default Subnet
resource "azurerm_virtual_network" "myterraformnet" {
  name                = "terra-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_subnet" "myterrasubnet" {
  name                 = "internal"
  resource_group_name  = "${var.resource_group_name}"
  virtual_network_name = azurerm_virtual_network.myterraformnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create Azure Network Interface Card(NIC)
resource "azurerm_network_interface" "myterraNIC" {
  name                = "terra-nic"
  location            = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.myterrasubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Azure Public IP
resource "azurerm_public_ip" "MyterraPubIp" {
  name                = "MyterraPublicIp1"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.resource_group_location}"
  allocation_method   = "Static"

  tags = {
    environment = "Test"
  }
}
# Create Azure Network Security Group
resource "azurerm_network_security_group" "MyTerrasecNSG" {
  name                = "myscrptterraSecurityGroup1"
  location            = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group_name}"

  security_rule {
    name                       = "myRDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3389"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "HTTP"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "8080"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}
# Associate NIC with Network Security Group
resource "azurerm_network_interface_security_group_association" "myterrantassociteNIC" {
    network_interface_id      = azurerm_network_interface.myterraNIC.id
    network_security_group_id = azurerm_network_security_group.MyTerrasecNSG.id
    }
 # Associate Subnet with Network Security Group   
    resource "azurerm_subnet_network_security_group_association" "myterrasubnetas" {
  subnet_id                 = azurerm_subnet.myterrasubnet.id
  network_security_group_id = azurerm_network_security_group.MyTerrasecNSG.id
}
# Create Azure Storage Account
resource "azurerm_storage_account" "Myterrastorescrt" {
  name                     = "myerrastore"
  resource_group_name      = "${var.resource_group_name}"
  location                 = "${var.resource_group_location}"
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "Test"
  }
}

# Create Azure Virtual Machine name mytmcpk
resource "azurerm_windows_virtual_machine" "MynewTerraVM" {
  name                = "${var.virtual_machine_name}"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.resource_group_location}"
  size                = "${var.vm_size}"
  admin_username      = "${var.admin_username}"
  admin_password      = "${var.admin_password}"
  network_interface_ids = [
    azurerm_network_interface.myterraNIC.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
# Create azure VM extension for install IIS using Powershell script
resource "azurerm_virtual_machine_extension" "vm_extension_install_iis" {
  name                       = "vm_extension_install_iis"
  virtual_machine_id         = azurerm_windows_virtual_machine.MynewTerraVM.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
    }
SETTINGS
}
