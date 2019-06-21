---
title: Manage secrets in Terraform on Azure
description: 
author: <github account>
ms.author: tarcher
ms.service: terraform
ms.topic: tutorial
ms.custom: mvc
ms.date: 06/20/2019

---

# Tutorial: Manage secrets in Terraform on Azure

<!-- What are secrets? A few examples, out of many possibilities:
- Terraform state 
- Security principal id and password
- Certificates
- Storage access keys
- SSH private key and password
- Configuration details for network rules and endpoints
- URLs -->


This walkthrough is oriented towards using Terraform in automation, such as a CI/CD pipeline. The sample configuration relies on Azure Managed Identity to reduce the amount of sensitive information exposed to the host environment. 

Typically, secrets are passed to Terraform by several methods:
* Through environment variables set in the host environment. 
* Using tfvars.tvar files
* Terraform CLI command line 

Long running pipeline, repeatedly calls Terraform stage but perhaps over a period of days or weeks, during which Terraform is evoked on a new instance each time. Need to store all necessary info in secure central storage, be self contained without the need to persist secrets in the pipeline


The sample configuration and walkthrough show you how to:

> [!div class="checklist"]
> * Configure Terraform and Providers to use msi
> * Find the virtual machine service principal objectID, called the principal_id in Terraform.
> * RBAC role assignments
> * Use the Random, Null, and Local providers 
> * Use Local_file and local_exec provisioners to interact with the host environment
> * Using null_resource to wrap a provisioner
> * Enforce resource dependencies with depends_on=[]
> * Use Key Vault to manage ssh keys
> * Save state on Azure Storage

<!-- outline 

- make modifications to the existing sample, Break it into two:

Part 1, creates kv, storage
Part 2, creates a vm and secrets

Overall flow:

Assume reader is using cloud shell; it simplifies the setup and instructions. 

1. download the sample configs from azure-devops/terraform-secrets
2. apply part 1 config
3. Decide how to deal with remote backend config. Couple of ways to do it here, which one provides greatest enlightenment?
4. apply part 2 config
5. retrieve the secrets and SSH to the VM

-->



## Prerequisites

 * An Azure subscription. If you don't have an Azure subscription, create a [free account](https://azure.microsoft.com/free/?WT.mc_id=A261C142F) before you begin.
 * *Owner* or *Contributor* and *User Access Administrator* roles in your Azure subscription. These roles are needed to create a managed identity and RBAC role assigment.


## Install the sample Terraform configuration

The sample configurations create the following Azure resources:

<!-- part 1 -->
* Resource group
* Key Vault and access policy
* Azure Storage account for Terraform state
* A blob container and access policy for Terraform state 

<!-- part 2 -->

* Storage account for boot diagnostics
* Vnet, subnet, nic, nsg, public IP
* A new Linux virtual machine with managed identity
* A unique ssh private key and password for every new virtual machine
* RBAC role assignments for the key vault and backend storage to enable the virtual machine identity to access those resources
* Several new secrets stored in the vault: admin username, ssh key passphrase, and ssh private key


## Procedure 3



## Clean up resources

If you're not going to continue to use this application, delete
<resources> with the following steps:

1. From the left-hand menu...
2. ...click Delete, type...and then click Delete


## Next steps

Advance to the next article to learn how to create...
> [!div class="nextstepaction"]
> [Next steps button](contribute-get-started-mvc.md)

