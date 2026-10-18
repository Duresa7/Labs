<#
.SYNOPSIS
  Install the AD DS role and create the corp.local forest on the first DC.
.DESCRIPTION
  Promotes CORP-DC01 to the forest root for corp.local at the Windows Server
  2025 functional level, with AD-integrated DNS. Credentials and the DSRM
  password are entered at runtime.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Run on the server that will become CORP-DC01, elevated.
#>

Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Import-Module ADDSDeployment

Install-ADDSForest `
    -DomainName "corp.local" `
    -DomainNetbiosName "CORP" `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -SysvolPath  "C:\Windows\SYSVOL" `
    -LogPath     "C:\Windows\NTDS" `
    -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM password") `
    -Force

# The server reboots automatically to finish promotion.
