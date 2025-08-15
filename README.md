# How to run Atlantis with Terragrunt

This repository contains sample code to run Atlantis with Terragrunt. It is an accompanying GitHub repository to a blog post on [Spacelift.io](https://spacelift.io) (a link to the blog post will be added later when it is published)

Atlantis is deployed on virtual machines on Azure, and it is connected to a GitHub repository.

> [!CAUTION]
> This is not a production-ready deployment of Atlantis.
>
> The connection to Atlantis is public and over HTTP.
>
> Only use this example for POC/demo and learning how everything works. For production you need to extend the code to fit your environment and security requirements.

## Prerequisites

To provision the sample you will need the following:

* An **Azure subscription** and the **Azure CLI** (see [docs](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) for instructions) installed and authenticated on your local system (or where you will provision this sample code from).
* The Azure subscription should have at least one public **Azure DNS zone** that you can use. 
* A GitHub account and a GitHub PAT token with repository permissions (see [docs](https://www.runatlantis.io/docs/access-credentials.html#github-user) for required permissions).

## Instructions

1. Create a `terraform.tfvars` file and provide values for all variables, an example is shown below:
    ```hcl
    github_owner             = "mattias-fjellstrom"
    location                 = "Sweden Central"
    subscription_id          = "e710ceac-2fbd-4efd-b131-74eaaf64fa7e"
    github_token             = "ghp_tokenvaluehere123"
    azure_dns_resource_group = "my-dns-resource-group"
    azure_dns_zone_name      = "example.com"
    ```
1. Provision resources using `terraform apply`.

When the apply is complete you can open your Atlantis instance on `http://atlantis.<your azure dns zone name>` (e.g. `http://atlantis.example.com`). You will have a new GitHub repository named `spacelift-atlantis-infrastructure` where you can test Atlantis with Terragrunt. The repository contains a sample Terragrunt configuration with a dev and a prod environment.

Sign in to the web interface using `atlantis` as the username, and obtain the password using the following command:

```console
$ terraform output -raw atlantis_web_password
abcdefgh1234...
```

If you need to access the underlying virtual machine you can do so using the SSH key that is provisioned by Terraform:

```console
$ eval $(terraform output -raw ssh)
```

Find the public IP of the virtual machine in your Azure environment.

# References

* Learn more about [Atlantis](https://www.runatlantis.io/)
* Learn more about [Terragrunt](https://terragrunt.gruntwork.io/)
* Learn more about [Spacelift](https://spacelift.io)

You can find my private blog on [mattias.engineer](https://mattias.engineer)