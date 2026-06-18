<#
.SYNOPSIS
  Replicate the Windows guest to Azure with Azure Site Recovery (agent path).
.DESCRIPTION
  The lab runs on Proxmox (KVM), which ASR does not enumerate as a hypervisor.
  The guest is protected through ASR's agent path: the Mobility service is
  installed inside the Windows guest and the machine replicates as a physical
  server. This script is a runbook skeleton; most of the wiring (appliance
  registration, account discovery) is done once in the Azure portal, and the
  replication health is then driven and checked from PowerShell.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Requires Az.RecoveryServices. Run after the ASR replication appliance is
  registered to the vault and the Mobility service is installed on the guest.
#>

$rg        = "rg-corplab-dr"
$vaultName = "rsv-corplab"

$vault = Get-AzRecoveryServicesVault -ResourceGroupName $rg -Name $vaultName
Set-AzRecoveryServicesAsrVaultContext -Vault $vault

# 1. Portal / one-time: register the ASR replication appliance to the vault and
#    install the Mobility service on the Windows guest (treated as physical).
# 2. Portal: enable replication, choosing the target resource group, target
#    virtual network, and a replication policy (crash-consistent every 5 min,
#    app-consistent every 60 min).

# Check replication health for the protected item
$fabric    = Get-AzRecoveryServicesAsrFabric
$container  = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabric
Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $container |
    Select-Object FriendlyName, ProtectionState, ReplicationHealth, LastSuccessfulTestFailoverTime

# A test failover (safe: does not touch production, does not stop replication)
# is started from the portal or with Start-AzRecoveryServicesAsrTestFailoverJob,
# bringing the recovery VM up in an isolated Azure network for validation.
