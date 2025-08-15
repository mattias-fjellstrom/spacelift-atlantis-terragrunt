output "atlantis_web_password" {
  description = "Atlantis basic auth web password"
  value       = random_password.web.result
  sensitive   = true
}

output "ssh" {
  description = "SSH command for connecting to the Atlantis server"
  value       = "ssh -i servers.pem azureuser@${azurerm_public_ip.atlantis.ip_address} -p 2222"
}
