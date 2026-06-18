# Chapter 01 - On-prem Active Directory build

## Objective

Stand up a Windows Server 2025 Active Directory forest that behaves like a small production domain, not a single-DC toy. That means two domain controllers with replication, a Global Catalog and DNS on both, a deliberate OU layout that policy can target by location, and one tightly held admin account instead of everyone running as Domain Admin.

The domain is `corp.local`. Everything later in this repo (the hardening, the cloud sync, the backups, the attack pass) sits on top of what gets built here.

## Architecture

| Decision | Choice | Reason |
|---|---|---|
| Forest / domain | Single domain `corp.local`, 2025 functional level | One domain is enough for this scope; 2025 level unlocks the current schema and Kerberos features |
| Domain controllers | `CORP-DC01` and `CORP-DC02` | A second DC means logons survive one box going down, and it gives replication to actually observe |
| FSMO roles | All five on `CORP-DC01` | Simple to reason about at this size; documented so I know where they live if I need to seize them |
| Global Catalog | Both DCs | GC on both keeps logon and lookups fast if one is offline |
| DNS | AD-integrated zone on both DCs | DNS replicates with AD, no separate zone transfer to babysit |
| Admin model | One Domain Admin (`acarter`), in its own OU | Smallest possible privileged footprint. Daily work does not use this account |

The OU tree is built so that *where* an object lives decides *what* applies to it. Managed users and managed workstations each get their own OU, and the restriction GPOs link to those OUs. Full layout is in [diagrams/ou-structure.md](../diagrams/ou-structure.md).

```
corp.local
├── OU=Admin-Accounts        (Domain-Admins, Service-Accounts)
├── OU=Users-Accounts        └── OU=Managed   (jack-user, test-user-1)
├── OU=Workstations          ├── OU=Managed   (WS-01, LAPTOP-01, WS-02)
│                            └── OU=Staging   (LAPTOP-STG-01)
└── OU=Security-Groups       (GRP-ManagedUsers, GRP-ManagedWorkstations)
```

## Implementation

**First DC and the forest.** `CORP-DC01` gets the AD DS role, then becomes the forest root. The DSRM password and the domain admin credential are entered at runtime, never stored in the script.

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Install-ADDSForest `
    -DomainName "corp.local" `
    -DomainNetbiosName "CORP" `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns `
    -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM password")
```

Full script: [scripts/ad-setup/install-forest-dc01.ps1](../scripts/ad-setup/install-forest-dc01.ps1).

**Second DC.** `CORP-DC02` joins the existing domain as a replica DC and Global Catalog, replicating from `CORP-DC01`. This is the real promotion script from the build, with the hardcoded credential pulled out and replaced by a prompt.

```powershell
$cred = Get-Credential -Message "Domain admin for DC promotion"
Install-ADDSDomainController `
    -DomainName "corp.local" `
    -Credential $cred `
    -ReplicationSourceDC "CORP-DC01.corp.local" `
    -InstallDns -NoGlobalCatalog:$false `
    -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM password")
```

Full script: [scripts/ad-setup/promote-corp-dc02.ps1](../scripts/ad-setup/promote-corp-dc02.ps1).

**OUs, users, and groups.** The OU tree is created first, then accounts drop into the right OU so policy lands on them by location. Accidental-deletion protection is set on every custom OU.

```powershell
New-ADOrganizationalUnit -Name "Users-Accounts" -Path "DC=corp,DC=local" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Managed" -Path "OU=Users-Accounts,DC=corp,DC=local" -ProtectedFromAccidentalDeletion $true

New-ADUser -Name "Jack User" -SamAccountName "jack-user" `
    -UserPrincipalName "jack-user@corp.local" `
    -Path "OU=Managed,OU=Users-Accounts,DC=corp,DC=local" `
    -AccountPassword (Read-Host -AsSecureString "Initial password") -Enabled $true

New-ADGroup -Name "GRP-ManagedUsers" -GroupScope Global -Path "OU=Security-Groups,DC=corp,DC=local"
Add-ADGroupMember -Identity "GRP-ManagedUsers" -Members "jack-user","test-user-1"
```

Full scripts: [create-ou-structure.ps1](../scripts/ad-setup/create-ou-structure.ps1) and [create-users-and-groups.ps1](../scripts/ad-setup/create-users-and-groups.ps1).

## Verification & evidence

Replication and role placement are the two things worth checking before trusting the domain.

```powershell
# Forest and domain are at the 2025 level
Get-ADForest  | Select-Object Name, ForestMode, GlobalCatalogs
Get-ADDomain  | Select-Object Name, DomainMode, PDCEmulator, RIDMaster, InfrastructureMaster

# All five FSMO roles, in one view
netdom query fsmo

# Both DCs are up, and replication has no failures
Get-ADDomainController -Filter * | Select-Object Name, IPv4Address, IsGlobalCatalog, OperatingSystem
repadmin /replsummary
```

Expected result: `Get-ADForest` reports `ForestMode = Windows2025Forest` with both DCs listed as Global Catalogs, `netdom query fsmo` shows all five roles on `CORP-DC01.corp.local`, and `repadmin /replsummary` shows zero failures across the `CORP-DC01` to `CORP-DC02` pair.

> **Screenshot slot:** `repadmin /replsummary` with a clean (zero-failure) result. Save to `evidence/screenshots/01-replsummary.png`.

> **Screenshot slot:** Active Directory Users and Computers showing the OU tree. Save to `evidence/screenshots/01-ou-tree.png`.

## What this proves

A working multi-DC forest with replication, Global Catalog and DNS on both controllers, FSMO roles placed and documented, and an OU model designed so that Group Policy applies by object placement. The privileged footprint is one account in its own OU. That is the base the next four chapters build on.
