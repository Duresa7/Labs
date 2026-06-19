<#
.SYNOPSIS
  Collects the OpenSSH server state on CORP-DC02 for troubleshooting.
.DESCRIPTION
  Dumps the current identity, sshd/ssh-agent service state, sshd_config,
  administrators_authorized_keys metadata and ACLs, the ssh host directory
  ACL, and recent OpenSSH/Operational events to a text file for review.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Credentials are prompted at runtime, never hardcoded.
#>
$ErrorActionPreference = 'Continue'
$out = 'C:\Windows\Temp\dc02-ssh-state.txt'

try {
    "=== whoami ===" | Set-Content -Path $out -Encoding ASCII
    whoami | Add-Content -Path $out

    "`r`n=== ssh services ===" | Add-Content -Path $out
    Get-Service sshd, ssh-agent -ErrorAction SilentlyContinue |
        Select-Object Name, Status, StartType |
        Format-Table -AutoSize | Out-String | Add-Content -Path $out

    "`r`n=== ssh config ===" | Add-Content -Path $out
    if (Test-Path 'C:\ProgramData\ssh\sshd_config') {
        Get-Content 'C:\ProgramData\ssh\sshd_config' | Add-Content -Path $out
    } else {
        'sshd_config not found' | Add-Content -Path $out
    }

    "`r`n=== admin authorized_keys exists ===" | Add-Content -Path $out
    if (Test-Path 'C:\ProgramData\ssh\administrators_authorized_keys') {
        Get-Item 'C:\ProgramData\ssh\administrators_authorized_keys' |
            Select-Object FullName, Length, LastWriteTime |
            Format-List | Out-String | Add-Content -Path $out

        "`r`n=== admin authorized_keys acl ===" | Add-Content -Path $out
        icacls 'C:\ProgramData\ssh\administrators_authorized_keys' | Add-Content -Path $out
    } else {
        'administrators_authorized_keys not found' | Add-Content -Path $out
    }

    "`r`n=== ssh host dir acl ===" | Add-Content -Path $out
    icacls 'C:\ProgramData\ssh' | Add-Content -Path $out

    "`r`n=== recent openssh events ===" | Add-Content -Path $out
    $events = Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 30 -ErrorAction SilentlyContinue |
        Select-Object TimeCreated, Id, LevelDisplayName, Message
    if ($events) {
        $events | Format-List | Out-String | Add-Content -Path $out
    } else {
        'No OpenSSH/Operational events found' | Add-Content -Path $out
    }
}
catch {
    $_ | Out-String | Add-Content -Path $out
}
