<#
.SYNOPSIS
  Add a routable UPN suffix to the forest and stamp it on managed users.
.DESCRIPTION
  On-prem accounts were created under corp.local, which cannot be verified in
  Entra ID. This adds an alternative UPN suffix matching the verified cloud
  domain and rewrites managed users' UPNs to use it, so the same name works
  on-prem and in the cloud.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Run on a domain controller as a Domain Admin.
#>

$CloudDomain = "corplab.example.com"
$ManagedOU   = "OU=Managed,OU=Users-Accounts,DC=corp,DC=local"

# Register the alternative UPN suffix on the forest
Set-ADForest -Identity corp.local -UPNSuffixes @{add = $CloudDomain}

# Stamp every managed user with a UPN under the verified cloud domain
Get-ADUser -SearchBase $ManagedOU -Filter * | ForEach-Object {
    $newUpn = "{0}@{1}" -f $_.SamAccountName, $CloudDomain
    Set-ADUser $_ -UserPrincipalName $newUpn
    Write-Host ("Set UPN for {0} -> {1}" -f $_.SamAccountName, $newUpn)
}

# Confirm
Get-ADUser -SearchBase $ManagedOU -Filter * -Properties UserPrincipalName |
    Select-Object SamAccountName, UserPrincipalName
