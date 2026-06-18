# Chapter 02 - GPO security hardening

This is the chapter the rest of the lab is really about. A domain that just exists is not interesting. A domain where a managed user cannot open Registry Editor, cannot run a game launcher out of their Downloads folder, cannot dump LSASS, and gets logged off at 9 PM on a school night, all enforced by policy that reapplies on every refresh, is interesting. Every control here is live in the `corp.local` GPOs, and the [extracted GPO reports](../evidence/gpo-reports/) are the proof.

## Objective

Lock down two populations through Group Policy: **managed users** (what a signed-in person can do) and **managed workstations** (how the machine itself behaves). Block the obvious credential-theft techniques, take away the tools and paths an attacker or a curious user would reach for, and keep the controls reapplying so a reboot or a `gpupdate` cannot quietly undo them.

## The four GPOs

| GPO | Linked to | Applies to | Job |
|---|---|---|---|
| `GPO-PasswordPolicy` | Domain root | Whole domain | Account lockout and password rules |
| `GPO-ManagedUsers-Restrictions` | `OU=Managed,OU=Users-Accounts` | `GRP-ManagedUsers` (security-filtered) | Shell, tool, Settings, and browser restrictions per user |
| `GPO-ManagedWorkstations-Security` | `OU=Managed,OU=Workstations` | Managed computers | Credential hardening, device control, AppLocker, Wi-Fi |
| `Managed Workstations - OpenSSH Server` | `OU=Managed,OU=Workstations` | Managed computers | Deploys key-based OpenSSH for headless admin |

Security filtering matters on the user GPO: only `GRP-ManagedUsers` gets Apply permission, and `Authenticated Users` is read-only. An admin signing in to the same machine is not hit by the restrictions.

## Implementation

### Credential-theft hardening

The workstation GPO closes the doors that tools like mimikatz walk through. All of it is in [implement-gpo-hardening.ps1](../scripts/gpo-hardening/implement-gpo-hardening.ps1).

| Control | Setting | Effect |
|---|---|---|
| LSA protection | `HKLM\...\Control\Lsa\RunAsPPL = 1` and `RunAsPPLBoot = 1` | LSASS runs as a protected process. A normal admin token cannot read its memory |
| WDigest | `...\SecurityProviders\WDigest\UseLogonCredential = 0` | Stops cleartext passwords from sitting in memory |
| Cached logons | `...\Winlogon\CachedLogonsCount = 0` | No offline credential cache to steal or replay |
| Always-install-elevated | `...\Installer\AlwaysInstallElevated = 0` (user and machine) | Removes a classic privilege-escalation path through MSI |

### Local account and device control

```text
Local Administrators  -> restricted to CORP\Domain Admins
Built-in Administrator -> disabled
USB mass storage      -> USBSTOR Start = 4 (disabled)
AutoRun / AutoPlay    -> off on all drive types
```

A managed machine has no local admin except Domain Admins, no usable built-in Administrator, and no removable-storage execution path.

### AppLocker, enforced

AppLocker started in audit mode, then moved to enforced deny once the rules were proven. The model is allow-by-default for Windows and Program Files, deny for the places users actually drop things.

- Allow: everything under `%WINDIR%` and `%PROGRAMFILES%`. Administrators get an allow-all rule.
- Deny: executables, scripts, MSIs, and DLLs launched from Downloads, Desktop, `%TEMP%`, `AppData\Local\Programs`, and the OneDrive and game-launcher paths.
- Named blocks for the launchers people sideload: Roblox, Steam, Epic, Fortnite, Minecraft, Riot, Battle.net, Xbox.

Script: [apply-targeted-applocker-blocks.ps1](../scripts/gpo-hardening/apply-targeted-applocker-blocks.ps1). Documents (Office, PDF, code, images) are untouched unless they try to launch an executable.

### Browser lockdown: default-deny with an allowlist

Both Chrome and Edge run a default-deny URL policy. `URLBlocklist` is set to `*`, and an allowlist names what is permitted: Google account and productivity, coding education and practice sites, developer and framework docs, code sandboxes, research and AI tools, and the CDNs those pages need. Extensions follow the same shape: `ExtensionInstallBlocklist = *`, with two IDs allowed.

| Extension | ID |
|---|---|
| uBlock Origin Lite | `ddkjiahejlhfcafbddmgiahcphecmpfh` |
| Google Docs Offline | `ghbmnnjooekpmoecnnnilnnbdlolhkhi` |

Incognito, Guest, and Add-Profile are off, SafeSearch is forced, and browser history deletion is disabled so the controls cannot be cleared away. Edge launch is blocked for managed users so there is one browser to police, not two. The build did this in layers, which is why there are several scripts:

- [apply-chrome-managed-user-policies.ps1](../scripts/gpo-hardening/apply-chrome-managed-user-policies.ps1) - user-scope Chrome
- [apply-chrome-machine-policies.ps1](../scripts/gpo-hardening/apply-chrome-machine-policies.ps1) - machine-scope Chrome
- [apply-chrome-default-deny-allowlist.ps1](../scripts/gpo-hardening/apply-chrome-default-deny-allowlist.ps1) - the block-`*` plus allowlist model
- [apply-browser-allowlist-edge-chrome-default.ps1](../scripts/gpo-hardening/apply-browser-allowlist-edge-chrome-default.ps1) - mirror to Edge, set Chrome as default handler

### Wi-Fi allowlist

A machine startup script deploys a single WPA2/WPA3 profile for `CorpLab-WiFi` and denies other infrastructure and ad-hoc networks, so a managed laptop cannot be walked onto an open network to escape the policy path. The PSK is a runtime parameter, not a stored value. Script: [deploy-wlan-policy.ps1](../scripts/gpo-hardening/deploy-wlan-policy.ps1).

### Remote administration over SSH

Managed workstations get OpenSSH Server deployed by GPO, configured for key-based auth only (`PasswordAuthentication no`), with a scoped firewall rule. The install script is delivered as a machine startup script through a dedicated GPO. Scripts: [install-openssh-workstation.ps1](../scripts/gpo-hardening/install-openssh-workstation.ps1) and [deploy-managed-workstation-ssh-gpo.ps1](../scripts/gpo-hardening/deploy-managed-workstation-ssh-gpo.ps1).

### Logon-hours enforcement that survives going offline

One managed user (`jack-user`) has time-based access. AD logon hours handle the authentication side, but a cached session can keep running, so there is a machine-side enforcer too: a SYSTEM-context scheduled task that checks every five minutes and logs the session off by ID if it is outside the allowed window. Warnings fire at 30, 10, and 5 minutes. The action script is copied locally so it still works if the domain is unreachable.

```text
Sunday        06:00 - 22:00
Monday-Thu    15:00 - 21:00
Friday        15:00 - 22:00
Saturday      06:00 - 22:00
```

Scripts: [logon-hours-machine-action.ps1](../scripts/gpo-hardening/logon-hours-machine-action.ps1) and [logon-hours-machine-register.ps1](../scripts/gpo-hardening/logon-hours-machine-register.ps1).

### Account lockout

`GPO-PasswordPolicy` at the domain root: lockout threshold 5, lockout duration 30 minutes, reset counter after 30 minutes, administrator lockout enabled. This is also the control that turns a password spray into a wall in [chapter 05](05-attack-and-defend.md).

## Verification & evidence

Policy that is set is not the same as policy that applies. Each control was checked on a managed endpoint, not just on the DC.

```powershell
# What actually landed on the machine
gpresult /h C:\Temp\gpresult.html

# Credential-theft controls, read from the live registry
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name RunAsPPL
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name CachedLogonsCount

# AppLocker is enforced, not auditing
Get-AppLockerPolicy -Effective -Xml

# Browser policy is live (read on the endpoint)
Get-ItemProperty "HKLM:\Software\Policies\Google\Chrome\URLAllowlist"
```

On a managed laptop, `chrome://policy` shows the allowlist and the two permitted extensions, the registry confirms `RunAsPPL = 1` and `CachedLogonsCount = 0`, and `Get-AppLockerPolicy -Effective` shows enforce mode rather than audit.

The full per-GPO settings, extracted and sanitized from the live domain's GPO backups, are in [evidence/gpo-reports/](../evidence/gpo-reports/).

> **Screenshot slot:** `chrome://policy` on a managed endpoint showing the allowlist and the two extensions. Save to `evidence/screenshots/02-chrome-policy.png`.

> **Screenshot slot:** Group Policy Management Console showing `GPO-ManagedWorkstations-Security` settings. Save to `evidence/screenshots/02-gpmc-workstation.png`.

## What this proves

Group Policy authored as a security tool, not a settings menu: credential-theft mitigations (LSA protection, no cached creds, WDigest off), application control with AppLocker in enforce mode, a default-deny browser model, device and network restrictions, and time-based access that holds even offline. Each control was verified on the endpoint and is backed by an exported report. This is the surface [chapter 05](05-attack-and-defend.md) attacks.
