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

<!-- items in bold text marked with ! are notes to self, comments that will be removed but I want them visible in the text for now. I used to use a hash mark as a todo tag, but that tends to confuse the markdown linter even when embedded in a comment block -->

# How to manage secrets in Terraform on Azure

**! intro is far from complete, might save until last**

- What are secrets in Terraform? Any information you don't want to be compromised. A few examples:
    - Terraform state
    - Storage access keys
    - SSH private key and password
    - Configuration details for network rules and endpoints

- Three main topics:
    - managed identity, rbac, access policies
    - remote backend state
    - exposing secrets to the environment (how not to)
        - environment variables -- for example, something like this is commonly used: 
            ```bash
            $ export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
            $ export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
            $ export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
            $ export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
            ```
            ARM_SUBSCRIPTION_ID and ARM_TENANT_ID are not sensitive, but ARM_CLIENT_ID and ARM_CLIENT_SECRET are the equivalent of username and password for the Azure account.

            **! look at the .sh scripts for docker tf test for an example, then rewrite to avoid use of env vars**

        - shell commands that might be logged e.g., `terraform apply -var *double-secret-storage-access-key*`
        - terraform.tfvars, *.auto.tfvars

## Managed identity, RBAC, and access policies

* Managed identity is supported for Azure VM, AKS, and Azure Cloud Shell. Etc. **!Link to msi docs here**

* Important takeaway: AAD creates an account and service principal, but does not assign roles to the sp. The new vm/container can't do anything until RBAC is configured.

* Initially, if you try to login with the managed identity before configuring RBAC and policies, you'll get a message like this:

    ```azurecli-interactive
    Gamera@terrapin:~$ az login --identity
    No access was configured for the VM, hence no subscriptions were found
    ```

* You have to configure a role, and usually an access policy, on every Azure service the TF scripts need to access. At minimum, the tf identity needs Contributor on ARM, and an access policy configured on one or more storage accounts or blob containers.

* Don't assign the managed identity security principal more permission than it needs. It's tempting to assign the Owner role, because Owner can do nearly anything in the subscription -- and that's the problem. A subscription Owner can elevate other accounts to Owner, and owners can modify and destroy infrastructure they didn't create. Follow the principal of least privilege when assigning roles. In most cases, it is enough to assign the *Contributor* and *User Access Administrator* roles to the service principal.

[side note, how does Jenkins handle managed identity?]
* With the managed identity configured, tf needs two additional IDs before it can work with Azure infrastructure: subscriptionID and tenantID. [Need to check, don't think they are needed just to set up remote state, only for infrastructure plan or change]

## Remote backend state

* Terraform saves most secrets in plain text, readable by anyone with access to the state folder and files. State also contains sensitive configuration details, such as open ports, network rules, etc.
* It is common to access a given configuration state from more than one location. For example, a long-running pipeline may execute on more than one VM or container over a period of weeks. Each time Terraform is run it is configured to use state from the last iteration, if it exists.
* You have to enable remote state on every tf project. There is no global setting, per se, to enable remote state. [reference **TF_CLI_ARGS_name** here]
* When tf init is run, the backend is initialized. 
* You can override the default environment setting and control backend initialization as described in [terraform init](https://www.terraform.io/docs/commands/init.html#backend-initialization). 

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

