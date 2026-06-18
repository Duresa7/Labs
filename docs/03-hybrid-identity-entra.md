# Chapter 03 - Hybrid identity with Microsoft Entra ID

## Objective

Take the on-prem `corp.local` accounts and make them work in the cloud too: one identity a person can use to sign in to both a domain-joined laptop and a Microsoft cloud app, with the same password and without a second prompt. Do it without paying for premium licensing, because the point is to prove the pattern, not to run a tenant with a budget.

The sign-in and sync flow is drawn out in [diagrams/hybrid-identity-flow.md](../diagrams/hybrid-identity-flow.md).

## Approach

There are three ways to handle cloud authentication for synced users. The choice drives everything else.

| Method | What runs | Cost | Chosen? |
|---|---|---|---|
| Password Hash Sync (PHS) | A re-hash of the on-prem hash is synced to Entra | Free tier | **Yes** |
| Pass-through Authentication | An on-prem agent validates each sign-in live | Free tier, more moving parts | No |
| Federation (AD FS) | A federation farm you build and keep online | Servers and certificates to maintain | No |

PHS wins for a lab: no extra servers, sign-in keeps working even if the on-prem side is down, and it is the option Microsoft recommends for most cases. Seamless SSO rides alongside it so domain-joined machines get a silent token. The tenant itself is a free Microsoft Entra / Microsoft 365 developer tenant, and the verified domain is `corplab.example.com`.

## Implementation

**Plan the UPN suffix.** On-prem accounts were created under `corp.local`, which is not internet-routable and cannot be verified in Entra. So the forest gets an alternative UPN suffix that matches the verified cloud domain, and the synced users are stamped with it.

```powershell
Set-ADForest -Identity corp.local -UPNSuffixes @{add="corplab.example.com"}

Get-ADUser -SearchBase "OU=Managed,OU=Users-Accounts,DC=corp,DC=local" -Filter * |
    ForEach-Object {
        Set-ADUser $_ -UserPrincipalName ("{0}@corplab.example.com" -f $_.SamAccountName)
    }
```

Script: [scripts/hybrid-identity/add-upn-suffix.ps1](../scripts/hybrid-identity/add-upn-suffix.ps1). Matching the UPN to the verified domain is what lets a user sign in to the cloud with the same name they use on-prem.

**Install Entra Connect.** Entra Connect goes on a domain-joined sync server. The configuration:

- Sign-in method: **Password Hash Synchronization**
- Enable **Seamless single sign-on** (this creates the `AZUREADSSOACC` computer account in AD)
- OU filtering: sync only `OU=Users-Accounts` and the groups, not the whole directory
- Device options: enable **hybrid Azure AD join**, which publishes the Service Connection Point into the on-prem configuration partition

**Trigger and confirm the first sync.** After setup, force an initial cycle rather than waiting for the 30-minute timer.

```powershell
Import-Module ADSync
Get-ADSyncScheduler                       # confirm SyncCycleEnabled and the interval
Start-ADSyncSyncCycle -PolicyType Initial # full sync on first run; Delta after
```

Script: [scripts/hybrid-identity/sync-and-verify.ps1](../scripts/hybrid-identity/sync-and-verify.ps1).

## Verification & evidence

Three checks confirm the three things that had to work: objects arrived in the cloud, the password works there, and a device is hybrid-joined.

```powershell
# 1. Objects synced, and Entra knows they came from on-prem
Connect-MgGraph -Scopes "User.Read.All"
Get-MgUser -Filter "userPrincipalName eq 'jack-user@corplab.example.com'" `
    -Property DisplayName,UserPrincipalName,OnPremisesSyncEnabled |
    Select-Object DisplayName, UserPrincipalName, OnPremisesSyncEnabled
```

```text
# 2. On LAPTOP-01, the device shows joined both ways
dsregcmd /status

    AzureAdJoined : YES
    DomainJoined  : YES
```

`OnPremisesSyncEnabled = True` on the Graph result confirms the user is mastered on-prem, not cloud-only. `dsregcmd /status` showing both `AzureAdJoined` and `DomainJoined` as YES is the definition of a hybrid-joined device. Seamless SSO is confirmed by signing in to a cloud app from `LAPTOP-01` on the corporate network and getting no password prompt.

Script: [scripts/hybrid-identity/verify-synced-users-graph.ps1](../scripts/hybrid-identity/verify-synced-users-graph.ps1).

> **Screenshot slot:** Entra admin center, Entra Connect / sync status showing "Last sync: less than 1 hour ago". Save to `evidence/screenshots/03-sync-status.png`.

> **Screenshot slot:** Entra Users list showing `jack-user` with "Directory synced: Yes". Save to `evidence/screenshots/03-synced-user.png`.

> **Screenshot slot:** `dsregcmd /status` on `LAPTOP-01` showing `AzureAdJoined : YES` and `DomainJoined : YES`. Save to `evidence/screenshots/03-dsregcmd.png`.

## What this proves

Directory synchronization from on-prem AD to Entra ID with Password Hash Sync, Seamless SSO for silent cloud tokens on domain-joined machines, UPN planning to bridge a non-routable internal domain to a verified cloud domain, and hybrid Azure AD join. All of it on free-tier licensing, which is the constraint most home labs actually live under.
