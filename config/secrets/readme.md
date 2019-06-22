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

This configuration demonstrates:

* How to use a managed identity to access Azure resources without storing secrets locally
* Finding the virtual machine's service principal objectID, called the principal_id in Terraform.
* Using RBAC role assignments
* The Random, Null, and Local providers
* Using a module to package ssh key generation
* Using null_resource to wrap a provisioner
* Local_file and local_exec provisioners
* Creating explicit resource dependencies with depends_on=[]

