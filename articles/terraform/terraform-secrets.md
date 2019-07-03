---
title: Manage secrets in Terraform on Azure
description: 
author: <github account>
ms.author: tarcher
ms.service: terraform
ms.topic: 
ms.custom: mvc
ms.date: 06/20/2019
---

# How to manage secrets in Terraform on Azure

 When you use Terraform to manage [infrastructure as code](https://docs.microsoft.com/azure/devops/learn/what-is-infrastructure-as-code) (IaC), you work with many *secrets*. A secret is any information you don't want to be compromised. A few common examples:

* *Client secret*, the password for a security principal or user account that can create, modify, or delete infrastructure in Azure.
* Terraform [state](https://www.terraform.io/docs/state/), which contains secrets such as client secret, passwords and access keys in plain text.
* SSH private key and password; for more information about the need for robust SSH key management, see this [NIST paper](https://nvlpubs.nist.gov/nistpubs/ir/2015/NIST.IR.7966.pdf).
* Configuration details for network rules and endpoints: open ports, allowable source IP address range, etc.

Some secrets are generated before Terraform runs. Other secrets are created by Terraform, such as Terraform state. If Terraform is configured to use a security principal with the **Owner** role, Terraform can be used to elevate the role of an existing credential. Terraform can create new credentials and assign roles to them. An individual with unfettered access to a Terraform installation, state, and credentials essentially has the keys to your Azure infrastructure kingdom unless you take steps to constrain access in accordance with the principle of least privilege. 

Until the introduction of [managed identities for Azure resources](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/) it was essentially impossible to avoid exposing secrets to developers and operators. Now it is possible to work with managed Azure resources without exposing credentials at all. This article describes methods for protecting secrets in Terraform, with an emphasis on running Terraform in automation.

We will cover three main topics:

* Managed identity for Azure resources, RBAC, and access policies
* Configuring and using [remote state](https://www.terraform.io/docs/state/remote.html) with the [azurerm](https://www.terraform.io/docs/backends/types/azurerm.html) [backend](https://www.terraform.io/docs/backends/index.html) <!-- need to move these links to be inline with the associated text below -->
* Concealing secrets from the execution environment

## Managed identity, RBAC, and access policies

* Managed identity is supported for Azure VM, AKS, and Azure Cloud Shell. Etc.
* feature name: "managed identities for Azure resources," part of Azure Active Directory. "MSI" is no longer used - probably too limiting, the feature has expanded beyond services
* Docs landing page: https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/


* Important takeaway: AAD creates an account and service principal, but does not assign roles to the sp. The new vm/container can't do anything until RBAC is configured. Quickstart overview: https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/tutorial-linux-vm-access-arm

* Initially, if you try to login with the managed identity before configuring RBAC and policies, you'll get a message like this:

    ```azurecli-interactive
    Gamera@terrapin:~$ az login --identity
    No access was configured for the VM, hence no subscriptions were found
    ```

* You have to configure a role, and usually an access policy, on every Azure service the TF scripts need to access. At minimum, the tf identity needs Contributor on ARM, and an access policy configured on one or more storage accounts or blob containers. !Provide an overview of how to do this.

* Don't assign the managed identity security principal more permission than it needs. It's tempting to assign the Owner role, because Owner can do nearly anything in the subscription -- and that's the problem. A subscription Owner can elevate other accounts to Owner, and owners can modify and destroy infrastructure they didn't create. Follow the principal of least privilege when assigning roles. In most cases, it is enough to assign the *Contributor* and *User Access Administrator* roles to the service principal.

* With the managed identity configured, tf needs two additional IDs before it can work with Azure infrastructure: subscriptionID and tenantID. [Need to check, don't think they are needed just to set up remote state, only for infrastructure plan or change]

## Remote backend state

* Terraform saves most secrets in plain text, readable by anyone with access to the state folder and files. State also contains sensitive configuration details, such as open ports, network rules, etc.
* It is common to access a given configuration state from more than one location. For example, a long-running pipeline may execute on more than one VM or container over a period of weeks. Each time Terraform is run it is configured to use state from the last iteration, if it exists.
* You have to enable remote state on every tf project. There is no global setting, per se, to enable remote state. [reference **TF_CLI_ARGS_name** here]
* When tf init is run, the backend is initialized. 
* You can override the default environment setting and control backend initialization as described in [terraform init](https://www.terraform.io/docs/commands/init.html#backend-initialization). 
* Show examples of backend configurations


## Sample Terraform configuration
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

