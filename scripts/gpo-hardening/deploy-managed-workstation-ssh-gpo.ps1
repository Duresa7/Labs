<#
.SYNOPSIS
  Deploys an OpenSSH Server bootstrap to managed workstations via GPO startup script.
.DESCRIPTION
  Creates (or reuses) a GPO, links it to the managed-workstations OU, and writes a
  machine startup .cmd/.ps1 pair into SYSVOL that installs and hardens OpenSSH
  Server. Registers the scripts in scripts.ini, stamps a deployment version in the
  registry, and wires the client-side scripts extension GUID onto the GPO object.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Identifiers (domain, hosts, users, IPs) are sanitized placeholders.
  Credentials are prompted at runtime, never hardcoded. SSH public keys shown are
  non-functional placeholders.
#>
$ErrorActionPreference = 'Stop'

$gpoName = 'Managed Workstations - OpenSSH Server'
$targetOU = 'OU=Managed,OU=Workstations,DC=corp,DC=local'
$domainFqdn = 'corp.local'
$scriptsExtension = '[{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B6664F-4972-11D1-A7CA-0000F87571E3}]'
$cmdName = 'install-openssh-workstation.cmd'
$psName = 'install-openssh-workstation.ps1'

$cmdContent = @'
@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-openssh-workstation.ps1"
exit /b %errorlevel%
'@

$psContent = @'
$ErrorActionPreference = 'Stop'

$logDir = 'C:\ProgramData\ssh'
$logPath = Join-Path $logDir 'workstation-ssh-bootstrap.log'
$configPath = 'C:\ProgramData\ssh\sshd_config'
$authorizedKeysPath = 'C:\ProgramData\ssh\administrators_authorized_keys'

function Write-Log {
    param([string]$Message)
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $logPath -Value ('{0} {1}' -f (Get-Date -Format s), $Message)
}

Write-Log 'Starting OpenSSH workstation bootstrap.'

$capability = Get-WindowsCapability -Online |
    Where-Object Name -like 'OpenSSH.Server~~~~*' |
    Select-Object -First 1

if (-not $capability) {
    throw 'OpenSSH Server capability not found.'
}

if ($capability.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name $capability.Name | Out-Null
    Write-Log ('Installed capability {0}.' -f $capability.Name)
} else {
    Write-Log ('Capability {0} already installed.' -f $capability.Name)
}

$authorizedKeys = @(
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAEXAMPLEPLACEHOLDERKEYDONOTUSE admin-ws'
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAEXAMPLEPLACEHOLDERKEYDONOTUSE ansible-control'
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAEXAMPLEPLACEHOLDERKEYDONOTUSE admin-mac'
) -join "`r`n"

Set-Content -Path $authorizedKeysPath -Value $authorizedKeys -Encoding Ascii
icacls $authorizedKeysPath /inheritance:r /grant '*S-1-5-32-544:F' '*S-1-5-18:F' | Out-Null
Write-Log 'Updated administrators_authorized_keys.'

$config = @(
    'PermitRootLogin prohibit-password'
    'PubkeyAuthentication yes'
    'AuthorizedKeysFile	.ssh/authorized_keys'
    'PasswordAuthentication no'
    'Subsystem	sftp	sftp-server.exe'
    'AllowGroups administrators "Domain Admins"'
    ''
    'Match Group administrators'
    '       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys'
) -join "`r`n"

Set-Content -Path $configPath -Value $config -Encoding Ascii
Write-Log 'Updated sshd_config.'

Set-Service -Name sshd -StartupType Automatic

if ((Get-Service -Name sshd).Status -ne 'Running') {
    Start-Service -Name sshd
}

$rule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
if ($rule) {
    Enable-NetFirewallRule -Name 'OpenSSH-Server-In-TCP'
} else {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
        -DisplayName 'OpenSSH Server (sshd)' `
        -Enabled True `
        -Direction Inbound `
        -Protocol TCP `
        -Action Allow `
        -LocalPort 22 | Out-Null
}

Restart-Service -Name sshd -Force
Write-Log 'Completed OpenSSH workstation bootstrap.'
'@

Import-Module GroupPolicy
Import-Module ActiveDirectory

$gpo = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $gpoName -Comment 'Deploys OpenSSH Server to managed workstations and restricts SSH access to approved administrators.'
}

$inheritance = Get-GPInheritance -Target $targetOU
if (-not ($inheritance.GpoLinks | Where-Object { $_.DisplayName -eq $gpoName })) {
    New-GPLink -Name $gpoName -Target $targetOU -LinkEnabled Yes | Out-Null
}

$gpoRoot = Join-Path "C:\Windows\SYSVOL\sysvol\$domainFqdn\Policies" ("{" + $gpo.Id.Guid + "}")
$machineScriptsRoot = Join-Path $gpoRoot 'Machine\Scripts'
$startupScriptsRoot = Join-Path $machineScriptsRoot 'Startup'

New-Item -ItemType Directory -Path $startupScriptsRoot -Force | Out-Null

Set-Content -Path (Join-Path $startupScriptsRoot $cmdName) -Value $cmdContent -Encoding Ascii
Set-Content -Path (Join-Path $startupScriptsRoot $psName) -Value $psContent -Encoding Ascii

$scriptsIni = @"
[Startup]
0CmdLine=$cmdName
0Parameters=
"@

Set-Content -Path (Join-Path $machineScriptsRoot 'scripts.ini') -Value $scriptsIni -Encoding Ascii

Set-GPRegistryValue -Name $gpoName `
    -Key 'HKLM\Software\Policies\CorpLab\OpenSSH' `
    -ValueName 'DeploymentVersion' `
    -Type String `
    -Value (Get-Date -Format s) | Out-Null

$domainDn = (Get-ADDomain).DistinguishedName
$gpoDn = 'CN={' + $gpo.Id.Guid + '},CN=Policies,CN=System,' + $domainDn
$gpoAdObject = Get-ADObject -Identity $gpoDn -Properties gPCMachineExtensionNames
$currentExtensions = [string]$gpoAdObject.gPCMachineExtensionNames

if ($currentExtensions -notmatch [regex]::Escape($scriptsExtension)) {
    Set-ADObject -Identity $gpoDn -Replace @{
        gPCMachineExtensionNames = $currentExtensions + $scriptsExtension
    }
}

[PSCustomObject]@{
    GpoName = $gpo.DisplayName
    GpoId = $gpo.Id.Guid
    LinkedTarget = $targetOU
    StartupScript = (Join-Path $startupScriptsRoot $cmdName)
    PowerShellScript = (Join-Path $startupScriptsRoot $psName)
}
