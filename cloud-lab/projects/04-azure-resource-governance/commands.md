# Command reference (Azure CLI)

The `az` equivalent of the governance labs.

```bash
# Resource group: the lifecycle container everything else lives in
az group create --name lab-rg --location eastus

# A VM, then open the web port (the lab installed Nginx via a startup script)
az vm create --resource-group lab-rg --name lab-vm --image Ubuntu2204 \
  --admin-username azureuser --generate-ssh-keys
az vm open-port --resource-group lab-rg --name lab-vm --port 80

# Network security group rule (reach the site from my own machine)
az network nsg rule create --resource-group lab-rg --nsg-name lab-vmNSG \
  --name allow-web --priority 1000 --protocol Tcp \
  --destination-port-ranges 80 --access Allow

# RBAC: least-privilege role at the narrowest scope
az role assignment create --assignee <principal> --role Reader \
  --scope /subscriptions/<sub-id>/resourceGroups/lab-rg

# Resource locks: the two types, then removing one to allow a delete
az lock create --name read-only  --lock-type ReadOnly      --resource-group lab-rg
az lock create --name no-delete  --lock-type CanNotDelete  --resource-group lab-rg
az lock delete --name no-delete  --resource-group lab-rg   # required before a delete succeeds
```

The lock commands are the whole lesson: even an Owner cannot delete a locked resource until `az lock delete` removes the lock, which is the deliberate speed bump described in the [walkthrough](README.md).
