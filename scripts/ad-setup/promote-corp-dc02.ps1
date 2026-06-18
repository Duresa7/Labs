<#
.SYNOPSIS
  Promotes CORP-DC02 to a replica domain controller in corp.local.
.DESCRIPTION
  Installs Active Directory Domain Services on a second server and promotes it
  to a replica domain controller, replicating from CORP-DC01. Runs DNS on the
  new DC and keeps the Global Catalog. Part of a Windows Server 2025 AD lab.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Identifiers (domain, hosts, users, IPs) are sanitized placeholders.
  Credentials are prompted at runtime, never hardcoded.
#>
$ErrorActionPreference = 'Stop'
$log = 'C:\Windows\Temp\promote-corp-dc02.log'
$done = 'C:\Windows\Temp\promote-corp-dc02.done'
$err = 'C:\Windows\Temp\promote-corp-dc02.err'

Remove-Item $done, $err -Force -ErrorAction SilentlyContinue
Start-Transcript -Path $log -Force

try {
    $Cred = Get-Credential -Message 'Enter domain admin credentials for DC promotion'
    $dsrm = Read-Host -AsSecureString 'DSRM password'

    $result = Install-ADDSDomainController `
        -Credential $Cred `
        -DomainName 'corp.local' `
        -ReplicationSourceDC 'CORP-DC01.corp.local' `
        -InstallDns:$true `
        -NoGlobalCatalog:$false `
        -SiteName 'Default-First-Site-Name' `
        -SafeModeAdministratorPassword $dsrm `
        -Force:$true `
        -Confirm:$false `
        -NoRebootOnCompletion:$true

    $result | Out-String | Add-Content -Path $log
    'SUCCESS' | Set-Content -Path $done
}
catch {
    $_ | Out-String | Set-Content -Path $err
    throw
}
finally {
    Stop-Transcript
}
