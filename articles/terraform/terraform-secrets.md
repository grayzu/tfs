---
title: Manage secrets in Terraform on Azure
description: 
author: <github account>
ms.author: tarcher
ms.service: terraform
ms.topic: 
ms.custom: mvc
ms.date: 07/08/2019
---

# How to manage secrets in Terraform on Azure

A *secret* is any information you don't want to compromise, such as security credentials, connection strings, network configuration details, and much more. It's impossible to work with Terraform on Azure without using secrets. Often, a Terraform configuration will create new secrets. Protecting secrets while still making them available to authorized users for automation and collaboration is a real challenge. This article offers guidance about how to keep a secret with Terraform and the [Terraform Azure Provider](https://www.terraform.io/docs/providers/azurerm/).

To devise a method to protect our secrets, we first need to know where secrets are used, and how they can be exposed. The following sections describe the three main areas that cover virtually all operational cases for Terraform on Azure:

* [Authentication to Azure](#authentication-to-azure) 
* [Terraform State](#terraform-state)
* [Host environment](#host-environment)

A sample [Terraform configuration](#sample-configuration) accompanies this article. The configuration shows how to implement many of the concepts described below.

## Authentication to Azure

Terraform needs to authenticate to Azure Resource Manager(ARM) and to Azure services. To authenticate, it needs a credential. Once Terraform has authenticated to Azure Storage or Azure Key Vault, it can retrieve all of the other secrets needed by the configuration through interpolation. The initial secret to unlock the other secrets is often referred to as the *bootstrap* secret. The bootstrap secret is typically a *client secret*, a certificate, or user credentials (not recommended). The problem is how best to give Terraform the bootstrap secret without including it in code. Common solutions include  exporting secrets to environment variables, dynamically generated *.tfvars files, and using **-vars** on the command line. All of these share a drawback: credentials are exposed to developers, the host environment, system logs, and malicious actors.

The long wished-for solution is a way to eliminate the requirement for a bootstrap secret. Good news; this particular wish has been granted: [Managed identities for Azure resources](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/) is a feature of Azure Active Directory, specifically designed to solve the bootstrap problem. Terraform can use a managed identity to authenticate to any Azure resource that supports Azure Active Directory (Azure AD) authentication.

<!-- 
* Important takeaway: AAD creates an account and service principal, but does not assign roles to the sp. The new vm/container can't do anything until RBAC is configured. Quickstart overview: https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/tutorial-linux-vm-access-arm

* Initially, if you try to login with the managed identity before configuring RBAC and policies, you'll get a message like this:

    ```azurecli-interactive
    Gamera@terrapin:~$ az login --identity
    No access was configured for the VM, hence no subscriptions were found
    ```

* You have to configure a role, and usually an access policy, on every Azure service the TF scripts need to access. At minimum, the tf identity needs Contributor on ARM, and an access policy configured on one or more storage accounts or blob containers. !Provide an overview of how to do this.

* Don't assign the managed identity security principal more permission than it needs. It's tempting to assign the Owner role, because Owner can do nearly anything in the subscription -- and that's the problem. A subscription Owner can elevate other accounts to Owner, and owners can modify and destroy infrastructure they didn't create. Follow the principal of least privilege when assigning roles. In most cases, it is enough to assign the *Contributor* and *User Access Administrator* roles to the service principal.

* With the managed identity configured, tf needs two additional IDs before it can work with Azure infrastructure: subscriptionID and tenantID. [Need to check, don't think they are needed just to set up remote state, only for infrastructure plan or change]
-->

## Terraform State

Terraform State includes the settings for all of the resources maintained in the configuration, along with all of the credentials needed to manage those resources. As of this writing, passwords, connection strings, details about network security groups, rules, and so on are stored in plain text in the state files. Terraform state has to be protected just like a principal security credential, because in most cases it contains security credentials. 

Terraform state presents a special challenge because DevOps workflows often require access to state at more than one stage, and by more than one entity. A long-running CD pipeline may persist for weeks and involve multiple automation hosts and/or human collaborators. Users and automation hosts with access to Terraform state also have access to all of the secrets contained in the state files. 

The sections below related to state focus on two areas: remote state, and keeping secrets out of state so far as practicable. 

<!--
* Terraform saves most secrets in plain text, readable by anyone with access to the state folder and files. State also contains sensitive configuration details, such as open ports, network rules, etc.
* It is common to access a given configuration state from more than one location. For example, a long-running pipeline may execute on more than one VM or container over a period of weeks. Each time Terraform is run it is configured to use state from the last iteration, if it exists.
* You have to enable remote state on every tf project. There is no global setting, per se, to enable remote state. [reference **TF_CLI_ARGS_name** here]
* When tf init is run, the backend is initialized. 
* You can override the default environment setting and control backend initialization as described in [terraform init](https://www.terraform.io/docs/commands/init.html#backend-initialization). 
* Show examples of backend configurations
-->

## Host environments

Through shell commands(**local_host[]**, for example) and via automation hosts such as Jenkins. Most shells and orchestration hosts have extensive logging facilities. When sensitive info is passed via command line or environment variable, it is often logged by the host environment. 




## Sample configuration
This article includes a companion Terraform script. The script demonstrates how to: 

* Configure Terraform and Providers to use managed identity for Azure resources
* Use Azure Key Vault to manage ssh keys
* Save remote backend state on Azure Storage
* Find the virtual machine service principal *objectID*, also known as the *principal_id* in Terraform.
* Create RBAC role assignments
* Use the *Random*, *Null*, and *Local* providers 
* Use *Local_file* and *local_exec* provisioners to interact with the host environment
* Use *null_resource* to wrap a provisioner so that you can run the provisioner without creating or destroying infrastructure.
* Enforce resource dependencies with *depends_on=[]*.

1. Download the configuration from **! link to repo**
2. Change the values in `variables.tf` as needed 
3. Apply the configuration, fix issues, reapply, fix, repeat until it works. Don't forget that when a terraform configuration is aborted due to errors, Azure infrastructure that was created before the errors is left in an unknown state. Because TF is not idempotent, you need to run `terraform destroy` after every failed sortie so that you have a clean start on the next iteration. 

**Challenge exercise**: If you are experimentally minded, troubleshooting the sample configuration is a good opportunity to try out the [terraform taint](https://www.terraform.io/docs/commands/taint.html) command in a situation where you can do no harm. Using `terraform taint`, you can selectively taint resources to roll the configuration back to a known good point, which will depend on how far the configuration got before terminating. 

## Next steps

Advance to the next article to learn how to create...
> [!div class="nextstepaction"]
> [Next steps button](contribute-get-started-mvc.md)

