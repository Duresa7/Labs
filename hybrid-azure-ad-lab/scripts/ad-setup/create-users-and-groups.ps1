<#
.SYNOPSIS
  Create the lab accounts and security groups, and place them in the right OUs.
.DESCRIPTION
  One privileged admin (acarter) in its own OU, two managed users in the managed
  users OU, and the two security groups. Passwords are prompted, not stored.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Run on a DC as a Domain Admin.
#>

$root      = "DC=corp,DC=local"
$adminOU   = "OU=Domain-Admins,OU=Admin-Accounts,$root"
$managedOU = "OU=Managed,OU=Users-Accounts,$root"
$groupOU   = "OU=Security-Groups,$root"

# Privileged admin account (kept out of daily use)
New-ADUser -Name "Alex Carter" -SamAccountName "acarter" `
    -UserPrincipalName "acarter.adm@corp.local" `
    -Path $adminOU `
    -AccountPassword (Read-Host -AsSecureString "Password for acarter") `
    -Enabled $true -PasswordNeverExpires $false
Add-ADGroupMember -Identity "Domain Admins" -Members "acarter"

# Managed users
foreach ($u in @(
    @{ Name = "Jack User";   Sam = "jack-user" },
    @{ Name = "Test User One"; Sam = "test-user-1" }
)) {
    New-ADUser -Name $u.Name -SamAccountName $u.Sam `
        -UserPrincipalName ("{0}@corp.local" -f $u.Sam) `
        -Path $managedOU `
        -AccountPassword (Read-Host -AsSecureString ("Password for " + $u.Sam)) `
        -Enabled $true -ChangePasswordAtLogon $true
}

# Security groups used for GPO filtering and tracking
New-ADGroup -Name "GRP-ManagedUsers"        -GroupScope Global -GroupCategory Security -Path $groupOU
New-ADGroup -Name "GRP-ManagedWorkstations" -GroupScope Global -GroupCategory Security -Path $groupOU
Add-ADGroupMember -Identity "GRP-ManagedUsers" -Members "jack-user","test-user-1"

Get-ADGroupMember "GRP-ManagedUsers" | Select-Object Name, SamAccountName
