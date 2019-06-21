/*
    outputs:
        state storage account name
        state container name 
        vm name 
        vm ID
        vm principal_id
        vault name
        vault_id

        ...probably others

*/

output "State storage account name" {
    value = "${azurerm_storage_account.storage.name}"
}

output "State container name" {
    value = "${azurerm_storage_container.tfcontainer.name}"
}

output "Key vault name" {
    value = "${azurerm_key_vault.kvault.name}"
}

output "Key vault id" {
    value = "${azurerm_key_vault.kvault.id}"
}

output "Virtual machine name" {
    value = "${azurerm_virtual_machine.name}"
}

output "Virtual machine ID" {
    value = "${azurerm_virtual_machine.id}"
}

output "Virtual machine security principal id" {
    value = "${lookup(azurerm_virtual_machine.vm.identity[0], "principal_id")}"
}

output "Virtual machine administrator username" {
    value = "${random_string.adminuser.result}"
}

output "Virtual machine ssh public key" {
    value = "${module.get_new_sshkeys.ssh-public-key}"
}