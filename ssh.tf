resource "tls_private_key" "servers" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.servers.private_key_pem
  filename        = "${path.module}/servers.pem"
  file_permission = "0400"
}

resource "azurerm_ssh_public_key" "servers" {
  name                = "atlantis"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  public_key          = tls_private_key.servers.public_key_openssh
}
