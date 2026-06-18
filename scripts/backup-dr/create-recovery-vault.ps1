<#
.SYNOPSIS
  Create the Azure Recovery Services vault used for backup and DR.
.DESCRIPTION
  One vault holds both the DC system-state backups (MARS) and the Site Recovery
  replication config. Sets geo-redundant storage for the backup data.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Requires the Az module: Install-Module Az -Scope CurrentUser
#>

$rg       = "rg-corplab-dr"
$location = "eastus"
$vaultName = "rsv-corplab"

Connect-AzAccount

if (-not (Get-AzResourceGroup -Name $rg -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $rg -Location $location
}

$vault = New-AzRecoveryServicesVault -ResourceGroupName $rg -Name $vaultName -Location $location
Set-AzRecoveryServicesVaultContext -Vault $vault

# Geo-redundant storage for backup data
Set-AzRecoveryServicesBackupProperty -Vault $vault -BackupStorageRedundancy GeoRedundant

Get-AzRecoveryServicesVault -ResourceGroupName $rg -Name $vaultName |
    Select-Object Name, Location, ID
