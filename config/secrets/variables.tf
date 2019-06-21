# These values are set in terraform.tfvars
variable "az_subscription_id" {}
variable "az_tenant_id" {}


/* You can override the default values below by setting the value in the .tfvars file, e.g.: varName = "newvalue" */

variable "backend_storage_account_name" {
    default = "tfstate"
}
variable "state_container_name" {
    default = "tfstate"
}
variable "state_key" {
    default = "prod.terraform.tfstate"
}
variable "key_vault_name" {
    default = "tfvault0b01"
}
variable "az_location" {
    default = "westus2"
}
variable "az_name_prefix" {
    default = "tfst"
}
variable "env_tag" {
    default = "TF secrets tutorial"
}
variable "vm_name" {
    default = "TFVM"
}
variable "HOME" {
    description = "should be set to the value of $HOME env var, e.g., /home/username"
}
variable "ssh-file-path" {
    default = "/tf-ssh-key/"
}

/* Consult the Azure documentation for a list of built-in roles and IDs. You can also get the role id in a Terraform configuration using data.azurerm_builtin_role_definition. */

variable "contributor_role_id" {
    default = "b24988ac-6180-42a0-ab88-20f7382dd24c"
}