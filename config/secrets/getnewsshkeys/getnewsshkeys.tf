/*
    get_new_sshkeys module
        version 0.10, 04/12/19 - v-glmin

    Creates a new ssh key pair. Generates a random passphrase and applies it to the private key file. Stores the passphrase and the private key in the vault. Output value is the public key.

        IMPORTANT: the passphrase and private key will be written to Terraform state in clear text.
     
    Inputs:
    
    vm-name  -- usually the value of azurerm_virtual_machine.name, but can be any text.

    key-vault-id  -- the full id of the key vault in which to save the passphrase and private key as secrets. Must have IAM contributor role on Secrets in the vault. 

    file-path -- the full file path to the directory where you want the ssh key files to go. This has to be in the form of /x/.../z/ with the trailing slash. Paths in the form ~/z/ won't work because local_file doesn't understand that format.

    tag -- environment tag, default is empty string

    Output:

    ssh-public-key  -- just what it sounds like.
*/

# Input variables
variable "vm-name" {}
variable "key-vault-id" {}
variable "file-path" {}
variable "tag" {
    default = ""
}

# provider configurations   
provider "azurerm" {
    version = "~> 1.2"
}

provider "local" {
    version = "~> 1.2"
}

provider "null" {
    version = "~> 2.1"
}

provider "random" {
    version = "~> 2.1"
}

# get a passphrase that contains alpha, numeric, and some special characters, but no spaces
resource "random_string" "passphrase" {
    length = 12
    special = true
    override_special = "!@#$%&*-_=?"
    number = true  
}

# create a new ssh key pair, with a password on the private key
resource "null_resource" "sshkg" {
    # generate the key pair
    provisioner "local-exec" {
        command = "ssh-keygen -f ${var.file-path}${var.vm-name} -t rsa -b 4096 -N ${random_string.passphrase.result}"
    }
}

# save the passphrase to the vault
resource "azurerm_key_vault_secret" "kvpp" {
    name = "${var.vm-name}-ssh-passphrase"
    value = "${random_string.passphrase.result}" 
    key_vault_id = "${var.key-vault-id}"  
    tags { environment = "${var.tag}" }
}

# get the ssh keys
data "local_file" "sshpk" {
    # private key, soooper secret!
    depends_on = ["null_resource.sshkg"]  
    filename = "${var.file-path}${var.vm-name}"
}
data "local_file" "sshpub" {
    # public key
    depends_on = ["null_resource.sshkg"]
    filename = "${var.file-path}${var.vm-name}.pub"
}

# save the soooper-secret private key to the vault
resource "azurerm_key_vault_secret" "kvpk" {
    name = "${var.vm-name}-ssh-pk"
    value = "${data.local_file.sshpk.content}"
    key_vault_id = "${var.key-vault-id}"
    tags { environment = "${var.tag}" }
}

output "ssh-public-key" {
    value = "${data.local_file.sshpub.content}"
}

resource "null_resource" "cleanup" {
    # delete the key files
    depends_on =["azurerm_key_vault_secret.kvpk"]
    provisioner "local-exec" {
        command = "rm ${var.file-path}*"
    }
}

