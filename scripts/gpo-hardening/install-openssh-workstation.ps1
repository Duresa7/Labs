<#
.SYNOPSIS
  Installs and hardens the OpenSSH Server on a managed workstation.
.DESCRIPTION
  Ensures the OpenSSH Server Windows capability is installed, writes an
  administrators_authorized_keys file with approved admin public keys, locks down
  sshd_config (pubkey-only, no passwords, admin/Domain Admins only), starts the
  sshd service, and opens a dedicated inbound TCP 22 firewall rule on all profiles.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Credentials are prompted at runtime, never hardcoded. Replace the authorized
  keys below with your own.
#>
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
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7mP3xQv2sR8tWqL5nYbZcD9eFhG1jK4uM6oP0aS2dV admin-ws'
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM4kV7nP2qR9sT5wX8yB1cD6fG3hJ0lK4mN7oP9aQ2e ansible-control'
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9rT2wX5yU8bN3mQ7vK1pL4sR6dF0gJ2hC5nA8eZ3x admin-mac'
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

$ruleName = 'Corp-Managed-Workstation-OpenSSH-In-TCP'
if (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue) {
    Set-NetFirewallRule -Name $ruleName -Enabled True -Profile Any -Direction Inbound -Action Allow
} else {
    New-NetFirewallRule -Name $ruleName `
        -DisplayName 'Corp Managed Workstation OpenSSH (TCP 22)' `
        -Enabled True `
        -Profile Any `
        -Direction Inbound `
        -Protocol TCP `
        -Action Allow `
        -LocalPort 22 | Out-Null
}
Write-Log 'Ensured dedicated inbound firewall rule for TCP 22 on all profiles.'

Restart-Service -Name sshd -Force
$service = Get-CimInstance Win32_Service -Filter "Name='sshd'"
Write-Log ('Completed OpenSSH workstation bootstrap. State={0}; StartMode={1}' -f $service.State, $service.StartMode)
