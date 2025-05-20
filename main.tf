# Azure AD Domain Controller Lab - Terraform Scaffold

# -------------------------
# 1. Terraform Provider Setup
# -------------------------
provider "azurerm" {
  features {}

  subscription_id = "929d7635-207a-4b22-8d24-34e2ae29092b"
  tenant_id       = "afa83c1b-f72b-41e3-a84a-5d8d9f0b4654"
}

# -------------------------
# 2. Resource Group
# -------------------------
resource "azurerm_resource_group" "dc_lab" {
  name     = "rg-ad-dc-lab"
  location = "UK South"
}

# -------------------------
# 3. Virtual Network + Subnet
# -------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-ad-dc"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.dc_lab.location
  resource_group_name = azurerm_resource_group.dc_lab.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-ad-dc"
  resource_group_name  = azurerm_resource_group.dc_lab.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# -------------------------
# 4. Public IP
# -------------------------
resource "azurerm_public_ip" "pip" {
  name                = "pip-ad-dc"
  location            = azurerm_resource_group.dc_lab.location
  resource_group_name = azurerm_resource_group.dc_lab.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

# -------------------------
# 5. Network Security Group + RDP Rule
# -------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-ad-dc"
  location            = azurerm_resource_group.dc_lab.location
  resource_group_name = azurerm_resource_group.dc_lab.name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# -------------------------
# 6. Network Interface (with Public IP)
# -------------------------
resource "azurerm_network_interface" "nic" {
  name                = "nic-ad-dc"
  location            = azurerm_resource_group.dc_lab.location
  resource_group_name = azurerm_resource_group.dc_lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# -------------------------
# 7. Windows VM for DC
# -------------------------
resource "azurerm_windows_virtual_machine" "dc" {
  name                  = "vm-ad-dc"
  location              = azurerm_resource_group.dc_lab.location
  resource_group_name   = azurerm_resource_group.dc_lab.name
  size                  = "Standard_DS2_v2"
  admin_username        = "robadmin"
  admin_password        = "P@ssword1234!"
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# -------------------------
# 8. Managed Data Disk
# -------------------------
resource "azurerm_managed_disk" "data_disk" {
  name                 = "disk-ad-dc-data"
  location             = azurerm_resource_group.dc_lab.location
  resource_group_name  = azurerm_resource_group.dc_lab.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128
}

# -------------------------
# 9. Attach Data Disk to VM
# -------------------------
resource "azurerm_virtual_machine_data_disk_attachment" "disk_attach" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.dc.id
  lun                = 0
  caching            = "ReadOnly"
}

# -------------------------
# 10. VM Extension to Run PowerShell Script (Optional Promotion to DC)
# -------------------------
resource "azurerm_virtual_machine_extension" "provision_ad" {
  name                 = "install-ad-ds"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
  {
    "fileUris": ["https://raw.githubusercontent.com/rrichley/azure-ad-dc-lab/main/install-ad.ps1"],
    "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File install-ad.ps1"
  }
  SETTINGS
}