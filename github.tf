resource "github_repository" "example" {
  name        = "spacelift-atlantis-infrastructure"
  description = "Sample repository for trying out Atlantis"
  visibility  = "private"

  has_discussions = false
  has_issues      = false
  has_projects    = false
  has_wiki        = false
  has_downloads   = false

  license_template   = "mpl-2.0"
  gitignore_template = "Terraform"
}

# Atlantis repo webhook
resource "github_repository_webhook" "name" {
  repository = github_repository.example.name
  active     = true

  configuration {
    url          = "http://${azurerm_dns_a_record.atlantis.name}.${var.azure_dns_zone_name}/events"
    content_type = "application/json"
    secret       = random_string.webhook_secret.result
  }

  events = [
    "pull_request_review",
    "push",
    "issue_comment",
    "pull_request",
  ]
}

# Atlantis repo configuration file (overrides server configuration file)
resource "github_repository_file" "atlantis_yaml" {
  repository     = github_repository.example.name
  branch         = "main"
  file           = "atlantis.yaml"
  content        = file("${path.module}/repos/spacelift-atlantis-infrastructure/atlantis.yaml")
  commit_message = "Add Atlantis configuration"

  lifecycle {
    ignore_changes = [
      content,
    ]
  }
}

# Terragrunt root configuration file
resource "github_repository_file" "root_hcl" {
  repository = github_repository.example.name
  branch     = "main"
  file       = "root.hcl"
  content = templatefile("${path.module}/repos/spacelift-atlantis-infrastructure/root.hcl.tmpl", {
    resource_group  = azurerm_resource_group.default.name
    storage_account = azurerm_storage_account.state.name
    container       = azurerm_storage_container.state.name
    tenant_id       = data.azurerm_client_config.current.tenant_id
  })
  commit_message = "Add root.hcl file"

  lifecycle {
    ignore_changes = [
      content,
    ]
  }
}

# Terragrunt dev environment configuration file
resource "github_repository_file" "dev_terragrunt_hcl" {
  repository     = github_repository.example.name
  branch         = "main"
  file           = "dev/terragrunt.hcl"
  content        = file("${path.module}/repos/spacelift-atlantis-infrastructure/dev/terragrunt.hcl")
  commit_message = "Add dev terragrunt file"

  lifecycle {
    ignore_changes = [
      content,
    ]
  }
}

# Terragrunt prod environment configuration file
resource "github_repository_file" "prod_terragrunt_hcl" {
  repository     = github_repository.example.name
  branch         = "main"
  file           = "prod/terragrunt.hcl"
  content        = file("${path.module}/repos/spacelift-atlantis-infrastructure/prod/terragrunt.hcl")
  commit_message = "Add prod terragrunt file"

  lifecycle {
    ignore_changes = [
      content,
    ]
  }
}

# Simple Terraform module for a random integer
resource "github_repository_file" "modules_random_number_main_tf" {
  repository     = github_repository.example.name
  branch         = "main"
  file           = "modules/random-number/main.tf"
  content        = file("${path.module}/repos/spacelift-atlantis-infrastructure/modules/random-number/main.tf")
  commit_message = "Add random number module"

  lifecycle {
    ignore_changes = [
      content,
    ]
  }
}
