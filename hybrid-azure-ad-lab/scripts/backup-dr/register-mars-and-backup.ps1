<#
.SYNOPSIS
  Register the MARS agent on CORP-DC01 and protect the DC system state.
.DESCRIPTION
  Installs and registers the Microsoft Azure Recovery Services (MARS) agent
  against the vault, then schedules a daily System State backup. System State
  is the supported way to protect a domain controller: it captures NTDS.dit,
  SYSVOL, and the registry consistently.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Run on CORP-DC01, elevated. The MARS agent installer and the vault
  credentials file are downloaded from the vault in the Azure portal first.
  The vault passphrase is generated here and MUST be stored offline; without
  it, restores are impossible. It is never committed to this repo.
#>

# --- One-time agent install (downloaded from the vault) ---
# & "$env:USERPROFILE\Downloads\MARSAgentInstaller.exe" /q

Import-Module "C:\Program Files\Microsoft Azure Recovery Services Agent\bin\Modules\MSOnlineBackup"

# Register the agent to the vault using the credentials file from the portal
$vaultCreds = "C:\AzureBackup\rsv-corplab_credentials.VaultCredentials"
Start-OBRegistration -VaultCredentials $vaultCreds -Confirm:$false
# Set the encryption passphrase, then store the value offline (never here):
# Set-OBMachineSetting -EncryptionPassphrase (Read-Host -AsSecureString "Vault passphrase")

# --- System State backup policy ---
# Enable the "System State" component in the MARS console (Backup System State),
# then set the schedule and retention. Daily at 02:00, keep 30 daily points.
$pol      = New-OBPolicy
$sched    = New-OBSchedule -DaysOfWeek Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday -TimesOfDay 02:00
$retention = New-OBRetentionPolicy -RetentionDays 30
Set-OBSchedule        -Policy $pol -Schedule $sched
Set-OBRetentionPolicy -Policy $pol -RetentionPolicy $retention
Set-OBPolicy          -Policy $pol -Confirm:$false

# Trigger an on-demand run now
Get-OBPolicy | Start-OBBackup

# Confirm
Get-OBJob
