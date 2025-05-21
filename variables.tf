variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the domain controller VM"
}

variable "admin_password" {
  type        = string
  description = "Admin password for the domain controller VM"
  sensitive   = true
}