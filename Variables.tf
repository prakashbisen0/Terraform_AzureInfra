
variable "resource_group_name" {
  description = "Name of the azure resource group."
  default     = "myTerraResourceGroup"
}
variable "resource_group_location" {
  type        = "string"
  description = "Location of the azure resource group."
  default     = "West Europe"
}
variable "virtual_machine_name" {
  default     = "mytmcpk"
}

variable "vm_size" {
  default     = "Standard_B4ms"
}

variable "admin_username" {
  default     = "terraprak"
}

variable "admin_password" {
  default     = "Thinkpad@612"
}

