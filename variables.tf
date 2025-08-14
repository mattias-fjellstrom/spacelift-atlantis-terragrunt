variable "azure_dns_resource_group" {
  type        = string
  description = "Name of the Azure DNS resource group"
}

variable "azure_dns_zone_name" {
  type        = string
  description = "Name of the Azure DNS zone"
}

variable "github_owner" {
  type        = string
  description = "Your GitHub handle"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub token for Atlantis"
}

variable "location" {
  type        = string
  description = "Name of the Azure location where to create resources"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}
