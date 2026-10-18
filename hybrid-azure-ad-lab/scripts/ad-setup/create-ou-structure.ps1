<#
.SYNOPSIS
  Build the corp.local OU tree with accidental-deletion protection.
.DESCRIPTION
  Creates the Admin-Accounts, Users-Accounts, Workstations, and Security-Groups
  branches so Group Policy can target objects by their location.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Run on a DC as a Domain Admin.
#>

$root = "DC=corp,DC=local"

function New-LabOU {
    param([string]$Name, [string]$Path)
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$Name'" -SearchBase $Path -SearchScope OneLevel -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $true
        Write-Host "Created OU=$Name under $Path"
    }
}

# Top-level branches
New-LabOU "Admin-Accounts"  $root
New-LabOU "Users-Accounts"  $root
New-LabOU "Workstations"    $root
New-LabOU "Security-Groups" $root

# Sub-OUs
New-LabOU "Domain-Admins"   "OU=Admin-Accounts,$root"
New-LabOU "Service-Accounts" "OU=Admin-Accounts,$root"
New-LabOU "Managed"         "OU=Users-Accounts,$root"
New-LabOU "Managed"         "OU=Workstations,$root"
New-LabOU "Staging"         "OU=Workstations,$root"

Get-ADOrganizationalUnit -Filter * -SearchBase $root |
    Select-Object Name, DistinguishedName | Sort-Object DistinguishedName
