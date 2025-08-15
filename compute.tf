resource "azurerm_user_assigned_identity" "default" {
  name                = "mi-atlantis"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
}

# Allow the identity to manage Terraform state files in the storage account
resource "azurerm_role_assignment" "blobs" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.default.principal_id
}

# Atlantis webhook secret
resource "random_password" "webhook_secret" {
  length  = 32
  special = false
}

# Atlantis web password
resource "random_password" "web" {
  length = 32
}

locals {
  cloudinit_files = {
    write_files = [
      # Atlantis server configuration file
      {
        path    = "/etc/atlantis.d/repos.yaml"
        content = <<-EOF
          repos:
            - id: "github.com/${github_repository.example.full_name}"
              branch: /.*/
              allowed_overrides: [workflow]
              allow_custom_workflows: true
        EOF
      },
      # Atlantis systemd service file
      {
        path    = "/etc/systemd/system/atlantis.service"
        content = <<-EOF
          [Unit]
          Description="Atlantis - Terraform runner"
          Documentation=https://www.runatlantis.io/
          Requires=network-online.target
          After=network-online.target

          [Service]
          User=atlantis
          Group=atlantis
          ExecStart=/usr/bin/atlantis server \
            --repo-config="/etc/atlantis.d/repos.yaml" \
            --atlantis-url="http://${azurerm_dns_a_record.atlantis.name}.${var.azure_dns_zone_name}" \
            --gh-user="${var.github_owner}" \
            --gh-token="${var.github_token}" \
            --gh-webhook-secret="${random_password.webhook_secret.result}" \
            --repo-allowlist="github.com/${github_repository.example.full_name}" \
            --web-basic-auth=true \
            --web-username=atlantis \
            --web-password="${random_password.web.result}"
          ExecReload=/bin/kill --signal HUP $MAINPID
          KillMode=process
          KillSignal=SIGTERM
          Restart=on-failure
          LimitNOFILE=65536

          [Install]
          WantedBy=multi-user.target
        EOF
      },
    ]
  }
}

data "cloudinit_config" "atlantis_server" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get clean
      apt-get install -y curl unzip
    EOF
  }

  # Install Terraform
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      curl \
        --silent \
        --remote-name https://releases.hashicorp.com/terraform/1.12.2/terraform_1.12.2_linux_amd64.zip
      unzip terraform_1.12.2_linux_amd64.zip
      chown root:root terraform
      mv terraform /usr/bin/
    EOF
  }

  # Install Atlantis
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      wget https://github.com/runatlantis/atlantis/releases/download/v0.35.1/atlantis_linux_amd64.zip
      unzip atlantis_linux_amd64.zip
      chown root:root atlantis
      mv atlantis /usr/bin/

      # create the Atlantis user
      useradd --system --home /etc/atlantis.d --shell /bin/false atlantis

      # create the Atlantis configuration directory
      mkdir -p /etc/atlantis.d/repos

      chown -R atlantis:atlantis /etc/atlantis.d
    EOF
  }

  # Install Terragrunt
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      wget https://github.com/gruntwork-io/terragrunt/releases/download/alpha-20250813/terragrunt_linux_amd64
      mv terragrunt_linux_amd64 terragrunt
      chown root:root terragrunt
      chmod +x terragrunt
      mv terragrunt /usr/bin/
    EOF
  }

  # Create Atlantis configuration files
  part {
    content_type = "text/cloud-config"
    content      = yamlencode(local.cloudinit_files)
  }

  # Install Azure CLI (required for authentication for Terraform state storage)
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

      # We need to run this command as the atlantis user (not the root user)
      sudo -H -u atlantis bash -c 'az login --identity --resource-id "${azurerm_user_assigned_identity.default.id}"'
    EOF
  }

  # Start the Atlantis service
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      systemctl daemon-reload
      systemctl enable atlantis
      systemctl start atlantis
    EOF
  }
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "default" {
  name                = "vmss-atlantis"
  resource_group_name = azurerm_resource_group.default.name
  location            = var.location

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.default.id]
  }

  platform_fault_domain_count = 1
  single_placement_group      = false
  zone_balance                = false
  zones                       = ["1", "2", "3"]

  sku_name  = "Standard_D2s_v3"
  instances = 1

  user_data_base64 = data.cloudinit_config.atlantis_server.rendered

  network_interface {
    name    = "nic-atlantis"
    primary = true

    ip_configuration {
      name      = "primary"
      subnet_id = azurerm_subnet.atlantis.id
      version   = "IPv4"

      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.public.id,
      ]
    }
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = 30
  }

  os_profile {
    linux_configuration {
      admin_username                  = "azureuser"
      computer_name_prefix            = "atlantis"
      disable_password_authentication = true

      admin_ssh_key {
        username   = "azureuser"
        public_key = azurerm_ssh_public_key.servers.public_key
      }
    }
  }

  source_image_reference {
    offer     = "ubuntu-24_04-lts"
    publisher = "canonical"
    sku       = "server"
    version   = "latest"
  }

  lifecycle {
    ignore_changes = [
      instances,
      user_data_base64,
    ]
  }
}
