/*********************************************************************
    Secrets tutorial setup configuration

    Version 0.10.2, 04/12/19, v-glmin

    This configuration creates the prerequisite infrastructure needed for the   Terraform secrets tutorial. It will create the following Azure resources:

    * Resource group
    * Key vault
    * Storage accounts for Terraform state and for boot diagnostics
    * A blob container for state
    * Vnet, subnet, nic, nsg, public IP
    * Linux virtual machine with managed identity
    * RBAC role assignments for the key vault and backend storage to enable the virtual machine identity to access those resources
    * An ssh key pair
    * Several new secrets stored in the vault: admin username, ssh key passphrase, and ssh private key

    Among other things, this configuration demonstrates:

    * How to use a managed identity to access Azure resources without storing secrets locally
    * Finding the virtual machine's service principal objectID, called the principal_id in Terraform.
    * Using RBAC role assignments
    * The Random, Null, and Local providers
    * Using a module to package ssh key generation
    * Using null_resource to wrap a provisioner
    * Local_file and local_exec provisioners
    * Creating explicit resource dependencies with depends_on=[]

    This configuration assumes that Terraform is running in Azure Cloud Shell [recommended], or on a VM that has a managed identity configured, using BASH or similar shell on Linux. If neither case applies, you will need to modify this configuration to authenticate using a service principal or through the AZ CLI. For more information, see https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_secret.html. 

    IMPORTANT: The secrets created in this configuration will be saved to Terraform state in plain text. You can view the state using 'terraform show' to see what secrets were saved, and how they appear in the state.

***********************************************************************/
 

terraform {
    version = "~> 0.11.13"

    /* If you want to configure a remote backend and you have a storage account and blob container available, replace xxxxxxxxxxxx below with the correct values, and then uncomment the backend block */
    
    /*  
    use_msi = "true"
    backend "azurerm" {
        storage_account_name = "xxxxxxxxxxxx"
        container_name      = "xxxxxxxxxxxxx"
        key                 = "xxxxxxxxxxxx"  
        subscription_id     = "${var.az_subscription_id}"
        tenant_id           = "${var.az_tenant_id}"
    } 
    */
}

provider "azurerm" {
    version         = "~> 1.2"
    use_msi         = "true"
    subscription_id = "${var.az_subscription_id}"
    tenant_id       = "${var.az_tenant_id}"
}

provider "random" {
    version = "~> 2.1"
}

# Create a new resource group
resource "azurerm_resource_group" "rg" {
    name     = "${var.az_name_prefix}ResourceGroup"
    location = "${var.az_location}"

    tags { environment = "${var.env_tag}" }
}

/*  Normally, the key vault and backend storage account will already exist before you create a new virtual machine. Because this is a tutorial, the configuration creates this infrastructure for you. */

# Create a key vault, and add secrets for use later in the configuration
resource "azurerm_key_vault" "kvault" {
    name                = "${var.key_vault_name}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${azurerm_resource_group.rg.location}"
    tenant_id           = "${var.az_tenant_id}"
    sku { name = "standard"}

    tags { environment = "${var.env_tag}" }
}

/* Generate a random number to append to the storage names to ensure that they are unique. */
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.rg.name}"
    }

    byte_length = 6
}

# Create backend storage account and blob container for terraform state
resource "azurerm_storage_account" "tfstorage" {
    name                        = "${var.az_name_prefix}${var.backend_storage_account_name}${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.rg.name}"
    location                    = "${var.az_location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags { environment = "${var.env_tag}" }
}
resource "azurerm_storage_container" "tfcontainer" {
  name                  = "${var.state_container_name}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  storage_account_name  = "${azurerm_storage_account.tfstorage.name}"
  container_access_type = "private"
}


# Create virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "${var.az_name_prefix}vnet"
    address_space       = ["10.0.0.0/24"]
    location            = "${var.az_location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"

    tags { environment = "${var.env_tag}" }
}

# Create subnet
resource "azurerm_subnet" "subnet" {
    name                 = "${var.az_name_prefix}subnet"
    resource_group_name  = "${azurerm_resource_group.rg.name}"
    virtual_network_name = "${azurerm_virtual_network.vnet.name}"
    address_prefix       = "10.0.1.0/26"
}

# Create public IPs
resource "azurerm_public_ip" "publicip" {
    name                         = "${var.az_name_prefix}-PublicIP"
    location                     = "${var.az_location}"
    resource_group_name          = "${azurerm_resource_group.rg.name}"
    public_ip_address_allocation = "dynamic"

    tags { environment = "${var.env_tag}" }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
    name                = "${var.az_name_prefix}-NSG"
    location            = "${var.az_location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags { environment = "${var.env_tag}" }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
    name                      = "${var.az_name_prefix}-NIC"
    location                  = "${var.az_location}"
    resource_group_name       = "${azurerm_resource_group.rg.name}"
    network_security_group_id = "${azurerm_network_security_group.nsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
    }

    tags { environment = "${var.env_tag}" }
}


# Create storage account for boot diagnostics
resource "azurerm_storage_account" "diagstorage" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.rg.name}"
    location                    = "${var.az_location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags { environment = "${var.env_tag}" }
}


# create a random administrator user name - alpha and numbers only
resource "random_string" "adminuser" {
    length = 8
    special = false
    number = true  
}

# save the username to the key vault
resource "azurerm_key_vault_secret" "adminuser" {
    name = "${var.az_name_prefix}-${var.vm_name}-adminuser"
    value = "${random_string.adminuser.result}" 
    key_vault_id = "${azurerm_key_vault.kvault.id}"

    tags { environment = "${var.env_tag}" }
}

/* This creates a new ssh key pair, and saves the passphrase and private key in the vault. The output is the public key, used in the virtual machine. */
module "get_new_sshkeys" "sshkey" {
    source = "./getnewsshkeys"
    vm-name = "${var.az_name_prefix}-${var.vm_name}"
    key-vault-id = "${azurerm_key_vault.kvault.id}"
    file-path = "${var.HOME}${var.ssh-file-path}"
    tag = "${var.env_tag}"
}


# Create virtual machine
resource "azurerm_virtual_machine" "vm" {
    name                  = "${var.az_name_prefix}-${var.vm_name}"
    location              = "${var.az_location}"
    resource_group_name   = "${azurerm_resource_group.rg.name}"
    network_interface_ids = ["${azurerm_network_interface.nic.id}"]
    vm_size               = "Standard_DS1_v2"

    # This tells azurerm to create a virtual machine with a managed identity
    identity {
        type = "SystemAssigned"
    }

    storage_os_disk {
        name              = "${var.az_name_prefix}OsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS" #change to latest version
        version   = "latest"
    }

      os_profile {
        computer_name  = "${var.az_name_prefix}-${var.vm_name}"
        admin_username = "${random_string.adminuser.result}"
       } 
    
    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            key_data = "${module.get_new_sshkeys.ssh-public-key}"
            path =  "/home/${random_string.adminuser.result}/.ssh/authorized_keys"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.diagstorage.primary_blob_endpoint}"
    }

    tags { environment = "${var.env_tag}" }
}

/*
*   Configure RBAC roles for the virtual machine service principal
*/

# Key vault role and access policy
resource "azurerm_role_assignment" "kvrole" {
    scope = "todo"
    role_definition_id = "${var.contributor_role_id}"
    principal_id = "${lookup(azurerm_virtual_machine.vm.identity[0], "principal_id")}"
}

resource "azurerm_key_vault_access_policy" "kvap" {
    key_vault_id = "${azurerm_key_vault.kvault.id}"
    # resource_group_name = "${azurerm_resource_group.rg.name}"
    tenant_id = "${var.az_tenant_id}"
    object_id =  "${lookup(azurerm_virtual_machine.vm.identity[0], "principal_id")}"       
    
    secret_permissions = ["create","get","set",]
}

# Blob container role
resource "azurerm_role_assignment" "bcrole" {
    scope = "TODO"
    role_definition_id = "${var.contributor_role_id}"
    principal_id = "${lookup(azurerm_virtual_machine.vm.identity[0], "principal_id")}"
}


