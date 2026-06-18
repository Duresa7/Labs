# Chapter 04 - Backup and disaster recovery

An untested backup is a rumor. This chapter protects the part of the lab that hurts most to lose, the domain itself, and then actually restores it to prove the backup is real.

## Objective

Two questions to answer with evidence:

1. If the AD database on `CORP-DC01` is corrupted or a DC is lost, can I get the directory back?
2. If a whole server is gone, can I bring the workload up somewhere else?

Backup answers the first. Disaster recovery answers the second. They are different problems, so they get different tools.

## Architecture

| Layer | Tool | Protects | Recovers |
|---|---|---|---|
| Backup | Azure Backup (MARS agent) into a Recovery Services vault | DC **system state**: the AD database (`NTDS.dit`), SYSVOL, registry, boot files | The directory, via non-authoritative or authoritative restore |
| Disaster recovery | Azure Site Recovery, Mobility agent on the guest | The whole Windows server | A bootable copy of the machine in Azure |

One note on the DR layer: the lab runs on Proxmox (KVM), which Azure Site Recovery does not enumerate as a hypervisor the way it does Hyper-V or VMware. So the Windows guest is protected through ASR's agent path, where the Mobility service is installed inside the guest OS and replication is driven from there. From ASR's point of view it is a physical Windows server. That works regardless of what is underneath it.

## Implementation

**Create the vault.** One Recovery Services vault holds both the backups and the replication configuration.

```powershell
Connect-AzAccount
New-AzResourceGroup -Name "rg-corplab-dr" -Location "eastus"
$vault = New-AzRecoveryServicesVault `
    -ResourceGroupName "rg-corplab-dr" `
    -Name "rsv-corplab" `
    -Location "eastus"
Set-AzRecoveryServicesVaultContext -Vault $vault
```

Script: [scripts/backup-dr/create-recovery-vault.ps1](../scripts/backup-dr/create-recovery-vault.ps1).

**Back up the DC system state.** The MARS agent is installed on `CORP-DC01` and registered to the vault with a passphrase that is generated and stored offline, never in the repo. The backup item is **System State**, scheduled daily, with retention set so there is more than one recovery point to choose from. System state is the supported way to protect a domain controller; it captures `NTDS.dit` and SYSVOL together, consistently.

Script: [scripts/backup-dr/register-mars-and-backup.ps1](../scripts/backup-dr/register-mars-and-backup.ps1).

**Replicate for failover.** The Mobility service is installed on the Windows guest, and ASR replicates it into the vault with a target resource group and virtual network in Azure. Replication runs continuously; the recovery points are crash-consistent on a short interval and app-consistent less often.

Script: [scripts/backup-dr/configure-asr-replication.ps1](../scripts/backup-dr/configure-asr-replication.ps1).

## Verification & evidence

The backup side is verified by checking that jobs complete and recovery points exist.

```powershell
# Recent backup jobs and their status
Get-AzRecoveryServicesBackupJob -Status Completed -Operation Backup |
    Select-Object WorkloadName, Operation, Status, StartTime, EndTime

# Recovery points available to restore from
$item = Get-AzRecoveryServicesBackupItem -BackupManagementType MARS -WorkloadType ...
Get-AzRecoveryServicesBackupRecoveryPoint -Item $item
```

**The restore test (the part that matters).** A recovery point is restored as a non-authoritative system-state restore to an isolated recovery DC, the machine is booted into Directory Services Restore Mode, the restore is applied, and then the DC is checked for a healthy directory.

```powershell
# After the system-state restore completes and the DC reboots:
Get-ADUser -Filter * | Measure-Object        # the accounts are back
dcdiag /v                                     # directory health
repadmin /showrepl                            # replication state
```

For the DR layer, ASR runs a **test failover** into an isolated Azure network. A test failover spins up the replicated machine in Azure without touching the running production server and without breaking ongoing replication, so it is safe to run on a schedule.

> **Screenshot slot:** Recovery Services vault, Backup jobs blade showing completed system-state backups. Save to `evidence/screenshots/04-backup-jobs.png`.

> **Screenshot slot:** ASR test failover completed, the recovery VM running in Azure. Save to `evidence/screenshots/04-asr-testfailover.png`.

> **Screenshot slot:** `dcdiag /v` on the restored DC showing passing tests. Save to `evidence/screenshots/04-dcdiag.png`.

## What this proves

A backup strategy that protects a domain controller the supported way (system state, not a file copy of `NTDS.dit`), a separate DR path that can stand the workload up in Azure even though it runs on an unsupported-by-default hypervisor, and a restore that was actually performed and checked with `dcdiag`. Recovery that has been tested, not assumed.
