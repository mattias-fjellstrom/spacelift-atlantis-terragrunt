resource "azurerm_dns_a_record" "atlantis" {
  name                = "atlantis"
  resource_group_name = var.azure_dns_resource_group
  zone_name           = var.azure_dns_zone_name
  records             = [azurerm_public_ip.atlantis.ip_address]
  ttl                 = 300
}
