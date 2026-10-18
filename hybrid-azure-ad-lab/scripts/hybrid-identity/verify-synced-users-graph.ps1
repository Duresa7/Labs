<#
.SYNOPSIS
  Confirm a managed user synced to Entra ID and is mastered on-prem.
.DESCRIPTION
  Uses Microsoft Graph PowerShell to read the synced user. OnPremisesSyncEnabled
  = True confirms the object is sourced from on-prem AD, not created cloud-only.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Requires the Microsoft.Graph module: Install-Module Microsoft.Graph -Scope CurrentUser
#>

Connect-MgGraph -Scopes "User.Read.All"

$upn = "jack-user@corplab.example.com"

Get-MgUser -Filter "userPrincipalName eq '$upn'" `
    -Property DisplayName, UserPrincipalName, OnPremisesSyncEnabled, OnPremisesLastSyncDateTime |
    Select-Object DisplayName, UserPrincipalName, OnPremisesSyncEnabled, OnPremisesLastSyncDateTime |
    Format-List

Disconnect-MgGraph
